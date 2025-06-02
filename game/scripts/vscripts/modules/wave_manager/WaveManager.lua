WaveManager = WaveManager or class({})

local BaseClassAI = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassPlayer = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassPlayerDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

modifier_wave_manager_unit_ai = class(BaseClassAI)
modifier_wave_manager_player = class(BaseClassPlayer)
modifier_wave_manager_player_thinker = class(BaseClassPlayer)
modifier_wave_manager_player_attribute_debuff = class(BaseClassPlayerDebuff)
modifier_wave_manager_fow_revealer = class(BaseClassAI)
--------------------------------------------------
function WaveManager:Init()
    CustomGameEventManager:Send_ServerToAllClients("wave_manager_modifier_unit_count_init", {
        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
    })
    -- Important declarations
    self.spawnPoints = Entities:FindAllByName("wave_manager_spawn_point")
    self.triggerZone = Entities:FindByName(nil, "wave_manager_zone")
    self.primaryZone = Entities:FindByName(nil, "wave_manager_zone")

    self.playerSpawnEntity = Entities:FindByName(nil, "wave_manager_player_spawn")
    self.playerSpawnPoint = self.playerSpawnEntity:GetAbsOrigin()

    self.spawnInterval = 5
    self.minSpawnInterval = 1

    self.unitsSpawned = 0 -- This is increased every time a unit spawns
    self.unitsAlive = 0 -- Amount of units alive currently
    self.unitsSoftLimit = 50 -- Max amount of units allowed alive at the same time. Exceeding this will trigger the warning countdown into loss.
    self.unitsKilled = 0

    self.waveBossFactor = 30 -- Will spawn a boss after this amount of enemies have spawned
    self.waveModifierFactor = 25 -- Every X units spawned will add a random modifier to all X next units
    self.waveModifierFactorEnabled = false
    self.waveModifierFactorRemaining = self.waveModifierFactor
    self.waveModifier = nil
    self.timePassed = 0
    self.playerDeaths = 0

    self.endGameTriggerTimer = nil
    self.endGameTriggerTimerWin = nil

    self.allowedUnits = {
        "npc_dota_creature_wave_enemy",
    }

    self.allowedBosses = {
        "npc_dota_creature_30_boss",
        "npc_dota_creature_40_boss",
        "npc_dota_creature_100_boss",
        "npc_dota_creature_100_boss_2",
        "npc_dota_creature_100_boss_4",
    }


    -- Modifiers (remove current one)
    self.modifierList = {}
    --[[for _,mod in pairs(ENEMY_ALL_BUFFS) do
        if mod ~= _G.DifficultyChatTableEnemies[1] then
            table.insert(self.modifierList, mod)
        end
    end--]]

    -- Create FOW Revealer unit 
    local fowEmitter = CreateUnitByName("outpost_placeholder_unit", self.primaryZone:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS)
    fowEmitter:AddNewModifier(fowEmitter, nil, "modifier_wave_manager_fow_revealer", {})

    local music = {
        "TCOTRPG.Waves.Music.BGM"
    }

    self.selectedMusic = music[RandomInt(1, #music)]

    Timers:CreateTimer(114, function()
        if _G.GameHasEnded then return end 
        
        self.selectedMusic = music[RandomInt(1, #music)]
        EmitGlobalSound(self.selectedMusic)

        return 114
    end)

    EmitGlobalSound(self.selectedMusic)

    local loseTimer = nil

    GameRules:GetGameModeEntity():SetTPScrollSlotItemOverride("item_arena_invuln")

    -- Disable couriers 
    GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(false)

    -- Setup modifiers for players 
    -- This deals with player resurrection etc.
    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and hero:IsRealHero() and not hero:IsIllusion() and not IsSummonTCOTRPG(hero) then
            local connectionState = PlayerResource:GetConnectionState(hero:GetPlayerID())
            if connectionState == DOTA_CONNECTION_STATE_CONNECTED then
                if not hero:IsAlive() and hero:GetTimeUntilRespawn() > 0 then
                    hero:RespawnHero(false, false)
                end

                if hero:HasModifier("modifier_invulnerable") then 
                    hero:RemoveModifierByName("modifier_invulnerable")
                end

                if hero:HasModifier("modifier_stunned") then 
                    hero:RemoveModifierByName("modifier_stunned")
                end

                if hero:HasModifier("modifier_wave_manager_player") then 
                    hero:RemoveModifierByName("modifier_wave_manager_player")
                end

                if hero:HasModifier("modifier_wave_manager_player_thinker") then 
                    hero:RemoveModifierByName("modifier_wave_manager_player_thinker")
                end

                -- We un-chicken the chicken --
                if hero:HasModifier("modifier_chicken_ability_1_self_transmute") then
                    hero:RemoveModifierByName("modifier_chicken_ability_1_self_transmute")
                    hero:SetBaseMoveSpeed(350) -- Chicken is slow again D:
                end

                -- Add player modifier --
                hero:AddNewModifier(hero, nil, "modifier_wave_manager_player", {})
                hero:AddNewModifier(hero, nil, "modifier_wave_manager_player_thinker", {})

                -- Teleport players to the arena
                if hero:IsAlive() then
                    hero:Stop()
                    hero:AddNewModifier(hero, nil, "modifier_silence", { duration = 1.0 })
                    hero:SetAbsOrigin(self.playerSpawnPoint)
                    FindClearSpaceForUnit(hero, self.playerSpawnPoint, false)
                    hero:CenterCameraOnEntity(hero, 3)
                end

                local courier = PlayerResource:GetPreferredCourierForPlayer(hero:GetPlayerID())
                if courier ~= nil then
                    courier:AddNewModifier(courier, nil, "modifier_stunned", {})
                end

                -- Remove warp and replace it 
                local warp = hero:FindItemInInventory("item_base_portal_custom")
                if warp then
                    hero:TakeItem(warp)
                end
                
                hero:AddItemByName("item_arena_invuln")
            else
                hero:RemoveModifierByName("modifier_limited_lives") -- Remove the lives because it can be buggy otherwise
                hero:RespawnHero(false, false) -- Puts them in base again

                -- Add player modifier --
                hero:AddNewModifier(hero, nil, "modifier_wave_manager_player", {})
                hero:SetRespawnsDisabled(true)
                hero:ForceKill(false)
            end
        end
    end

    -- Enable Global Variable 
    -- Shop is disabled in the order filter
    _G.FinalGameWavesEnabled = true

    Timers:CreateTimer(1.0, function()
        if _G.GameHasEnded then return end

        if GetNumAliveHeroesNormal() > 0 then 
            if self.endGameTriggerTimer ~= nil then
                Timers:RemoveTimer(self.endGameTriggerTimer)
                self.endGameTriggerTimer = nil
            end

            if self.endGameTriggerTimerWin ~= nil then
                Timers:RemoveTimer(self.endGameTriggerTimerWin)
                self.endGameTriggerTimerWin = nil
            end
        end

        -- First we check if there are any alive players. If there are none, we end the game. (dead players with lives or aegis are considered live)
        -- After that we check if the amount of players that are dead are more than alive players (regardless of lives or aegis), we end the game
        if GetNumAliveHeroesWithLives() < 1 or (GetDeadOrReincarnatingPlayersWithLives() > 0 and GetNumAliveHeroesNormal() < 1) then
            if self.endGameTriggerTimer == nil then
                self.endGameTriggerTimer = Timers:CreateTimer(7.0, function() 
                    GameRules:SendCustomMessage("<font color='red'>You could not withstand the eternal torment, such a shame!</font>", 0, 0)
                    GameRules:SendCustomMessage("<font color='lightgreen'>GG, WP!</font>", 0, 0)
                    GameRules:SendCustomMessage("<font color='lightblue'>(Preparing player scores...)</font>", 0, 0)

                    if self.endGameTriggerTimerWin == nil then
                        self.endGameTriggerTimerWin = Timers:CreateTimer(5.0, function()
                            self:OnGameHasEnded()
                        end)
                    end

                    return
                end)
            end
        end

        self.timePassed = self.timePassed + 1

        CustomGameEventManager:Send_ServerToAllClients("wave_manager_modifier_unit_count", {
            time = self.timePassed,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })

        if self.unitsAlive >= self.unitsSoftLimit then
            if not loseTimer then
                loseTimer = Timers:CreateTimer(10.0, function()
                    if _G.GameHasEnded then return end 

                    self:OnGameHasEnded()
                end)
            end
        else
            if loseTimer ~= nil then
                Timers:RemoveTimer(loseTimer)
                loseTimer = nil
            end
        end

        CustomGameEventManager:Send_ServerToAllClients("wave_manager_modifier_unit_count", {
            units = self.unitsAlive,
            limit = self.unitsSoftLimit,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })

        return 1.0
    end)

    Timers:CreateTimer(self.spawnInterval, function()
        if _G.GameHasEnded then return end

        self:SpawnWaveUnit()

        self.unitsSpawned = self.unitsSpawned + 1

        if self.spawnInterval > self.minSpawnInterval then
            self.spawnInterval = self.spawnInterval - 0.5
        end

        return self.spawnInterval
    end)

    
    --[[
    local abyssInterval = 10
    Timers:CreateTimer(abyssInterval, function()
        -- Find a random hero
        local abyssRandomEnemies = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, self.primaryZone:GetAbsOrigin(), nil,
            FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        abyssRandomEnemies = shuffleTable(abyssRandomEnemies)
        
        local abyssRandomEnemy = nil 
        for _,selectedRandomEnemy in ipairs(abyssRandomEnemies) do
            if selectedRandomEnemy:IsAlive() then
                abyssRandomEnemy = selectedRandomEnemy
                break
            end
        end

        if abyssRandomEnemy ~= nil then
            -- Season of Abyss --
            local abyssOffsetX = RandomInt(-450, 450)
            local abyssOffsetY = RandomInt(-450, 450)
            local abyssOriginPos = abyssRandomEnemy:GetAbsOrigin()
            local randomAbyssLocation = Vector(abyssOriginPos.x+abyssOffsetX, abyssOriginPos.y+abyssOffsetY, abyssOriginPos.z)
            local abyssEmitter = CreateUnitByName("outpost_placeholder_unit", randomAbyssLocation, false, nil, nil, DOTA_TEAM_NEUTRALS)
            abyssEmitter:AddNewModifier(abyssEmitter, nil, "modifier_season_firestorm", {
                duration = abyssInterval
            })
        end

        return abyssInterval
    end)
    --]]

    -- Lightning Season
    --[[
    local lightningInterval = 10
    local lightningDamageDelay = 5
    Timers:CreateTimer(lightningInterval, function()
        -- Find a random hero
        local lightningRandomEnemies = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, self.primaryZone:GetAbsOrigin(), nil,
            FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

            lightningRandomEnemies = shuffleTable(lightningRandomEnemies)
        
        local lightningRandomEnemy = nil 
        for _,selectedRandomEnemy in ipairs(lightningRandomEnemies) do
            if selectedRandomEnemy:IsAlive() then
                lightningRandomEnemy = selectedRandomEnemy
                break
            end
        end

        if lightningRandomEnemy ~= nil then
            -- Season of lightning --
            local lightningOffsetX = RandomInt(-900, 900)
            local lightningOffsetY = RandomInt(-900, 900)
            local lightningOriginPos = lightningRandomEnemy:GetAbsOrigin()
            local randomlightningLocation = Vector(lightningOriginPos.x+lightningOffsetX, lightningOriginPos.y+lightningOffsetY, lightningOriginPos.z)
            local lightningEmitter = CreateUnitByName("outpost_placeholder_unit", randomlightningLocation, false, nil, nil, DOTA_TEAM_NEUTRALS)
            lightningEmitter:AddNewModifier(lightningEmitter, nil, "modifier_season_lightning", {
                duration = lightningDamageDelay
            })
            AddFOWViewer(DOTA_TEAM_GOODGUYS, randomlightningLocation, 900, lightningDamageDelay, false)
        end

        return lightningInterval
    end)
    --]]
end

function WaveManager:CalculateScore()
    -- Calculate score
    local score = (self.unitsKilled*0.1) + (self.timePassed*0.05)
    
    if self.playerDeaths < 0 then
        self.playerDeaths = 0 -- It should not be 0 or less
    end

    score = math.floor(score) -- Round it again

    return score
end

function WaveManager:OnGameHasEnded()
    local playerScores = {}
    local playerItems = {}
    local playerAbilities = {}

    -- Decrease the player deaths based on dead players
    -- This is done to not cause score loss if you don't have any deaths,
    -- since to lose you have all to die.
    --self.playerDeaths = self.playerDeaths - GetDeadPlayersConnected()

    score = self:CalculateScore()

    -- Sounds
    StopGlobalSound(self.selectedMusic)

    EmitGlobalSound("TCOTRPG.Waves.Music.EndScreen")

    -- Panorama
    CustomGameEventManager:Send_ServerToAllClients("wave_manager_modifier_unit_endscreen_init", {
        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
    })

    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        local connectionState = PlayerResource:GetConnectionState(hero:GetPlayerID())

        if UnitIsNotMonkeyClone(hero) and hero:IsRealHero() and not hero:IsIllusion() and not IsSummonTCOTRPG(hero) and connectionState == DOTA_CONNECTION_STATE_CONNECTED then
            local steamID = PlayerResource:GetSteamID(hero:GetPlayerID())
            if steamID ~= nil then
                steamID = tostring(steamID)
            end

            playerScores[steamID] = playerScores[steamID] or nil
            playerItems[steamID] = playerItems[steamID] or nil
            playerAbilities[steamID] = playerAbilities[steamID] or nil

            playerScores[steamID] = score
            playerItems[steamID] = GetPlayerItems(hero)
            playerAbilities[steamID] = GetPlayerAbilities(hero)

            if hero:IsAlive() then
                hero:AddNewModifier(hero, nil, "modifier_stunned", {})
                hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})
            end

            -- Get items
            local items = {}

            for i = 0, 5, 1 do
            local item = hero:GetItemInSlot(i)
            if item ~= nil then
              table.insert(items, item:GetAbilityName())
            end
            end

            -- Get the neutral slot too
            local neutralItem = hero:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
            if neutralItem ~= nil then
            table.insert(items, neutralItem:GetAbilityName())
            end

            CustomGameEventManager:Send_ServerToAllClients("wave_manager_modifier_unit_count", {
              points = score,
              units = self.unitsAlive,
              time = self.timePassed,
              killed = self.unitsKilled,
              deaths = self.playerDeaths,
              heroes = {
                [hero:GetUnitName()] = {
                      stats = {
                        hero = hero:GetUnitName(),
                        steam = steamID,
                        items = items,
                        attributes = {
                          strength = math.floor(hero:GetStrength()),
                          agility = math.floor(hero:GetAgility()),
                          intellect = math.floor(hero:GetIntellect()),
                        }
                      }
                    }
              },
              a = RandomFloat(1,1000),
              b = RandomFloat(1,1000),
              c = RandomFloat(1,1000),
            })

            -- Bots should be DOTA_CONNECTION_STATE_NOT_YET_CONNECTED
            -- This way they don't get added to the leaderboard
            if IsInToolsMode() or (IsDedicatedServer() and not GameRules:IsCheatMode()) then
                -- Send data to server
                local playerSteamID = tostring(PlayerResource:GetSteamID(hero:GetPlayerID()))
                local serverData = {
                  steamid = playerSteamID,
                  points = playerScores[steamID],
                  difficulty = KILL_VOTE_RESULT,
                  abilities = playerAbilities[steamID],
                  hero = hero:GetUnitName(),
                  items = playerItems[steamID],
                  attributes = {
                      strength = math.floor(hero:GetStrength()),
                      agility = math.floor(hero:GetAgility()),
                      intellect = math.floor(hero:GetIntellect()),
                  },
                  players = _G.PlayerList,
                  server_key = GetDedicatedServerKeyV2(SERVER_KEY),
                  date_key = SERVER_DATE_KEY
                }

                local req = CreateHTTPRequestScriptVM("POST", SERVER_URI.."/skapa")

                req:SetHTTPRequestRawPostBody("application/json", json.encode(serverData))

                req:Send(function(res)
                    if not res.StatusCode == 201 then
                        print("Failed to send data to server for leaderboard, error: " .. res.StatusCode)
                        return
                    end

                    if res.StatusCode == 201 then
                        print("[Leaderboard] Successfully updated "..playerScores[steamID].." points for client ", playerSteamID)

                        -- Give them XP equal to the points earned, seems fair
                        XpManager:AddExperience(hero, tonumber(playerScores[steamID])*2)
                    end
                end)

                -- End the game shortly after --
                Timers:CreateTimer(120.0, function() 
                    GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
                end)
            end
        end
    end

    _G.GameHasEnded = true
end

function WaveManager:UpdateLeaderboardScore(hero)
    if IsInToolsMode() or (IsDedicatedServer() and not GameRules:IsCheatMode()) then
        local steamID = PlayerResource:GetSteamID(hero:GetPlayerID())
        if steamID ~= nil then
            steamID = tostring(steamID)
        end

        playerScores[steamID] = playerScores[steamID] or nil
        playerItems[steamID] = playerItems[steamID] or nil
        playerAbilities[steamID] = playerAbilities[steamID] or nil

        score = self:CalculateScore()

        playerScores[steamID] = score
        playerItems[steamID] = GetPlayerItems(hero)
        playerAbilities[steamID] = GetPlayerAbilities(hero)

        -- Send data to server
        local playerSteamID = tostring(PlayerResource:GetSteamID(hero:GetPlayerID()))
        local serverData = {
          steamid = playerSteamID,
          points = playerScores[steamID],
          difficulty = KILL_VOTE_RESULT,
          abilities = playerAbilities[steamID],
          hero = hero:GetUnitName(),
          items = playerItems[steamID],
          attributes = {
              strength = math.floor(hero:GetStrength()),
              agility = math.floor(hero:GetAgility()),
              intellect = math.floor(hero:GetIntellect()),
          },
          players = _G.PlayerList,
          server_key = GetDedicatedServerKeyV2(SERVER_KEY),
          date_key = SERVER_DATE_KEY
        }

        local req = CreateHTTPRequestScriptVM("POST", SERVER_URI.."/skapa")

        req:SetHTTPRequestRawPostBody("application/json", json.encode(serverData))

        req:Send(function(res)
            if not res.StatusCode == 201 then
                print("Failed to send data to server for leaderboard, error: " .. res.StatusCode)
                return
            end

            if res.StatusCode == 201 then
                print("[Leaderboard] Successfully updated "..playerScores[steamID].." points for client ", playerSteamID)
            end
        end)
    end
end

function WaveManager:SpawnWaveUnit()
    local randomUnit = self.allowedUnits[RandomInt(1, #self.allowedUnits)]
    local randomSpawnPoint = self.spawnPoints[RandomInt(1, #self.spawnPoints)]
    local isBoss = false

    if self.unitsSpawned > 0 and self.unitsSpawned % self.waveBossFactor == 0 then
        randomUnit = self.allowedBosses[RandomInt(1, #self.allowedBosses)]

        local randomBossSounds = {
            "TCOTRPG.Waves.Boss.Appearance",
        }

        EmitGlobalSound(randomBossSounds[RandomInt(1, #randomBossSounds)])

        isBoss = true
    else
        -- Never replace a boss spawn
        --[[
        if RollPercentage(10) and not _G.WavesNecrolyteAlive then
            randomUnit = "npc_dota_creature_wave_enemy_necrolyte"
            _G.WavesNecrolyteAlive = true
            isBoss = true
        end
        --]]
        
        --if RollPercentage(10) then
        --    randomUnit = "npc_dota_creature_wave_enemy_razor"
        --    isBoss = true
        --end

        --if RollPercentage(10) then
            --randomUnit = "npc_dota_creature_wave_enemy_underlord"
            --isBoss = true
        --end
    end

    if self.unitsSpawned > 0 and self.unitsSpawned % self.waveModifierFactor == 0 then
        self.waveModifier = self.modifierList[RandomInt(1, #self.modifierList)]
        local modifierNameIcon = ""

        if self.waveModifier == "modifier_apocalypse_armor" then
            modifierNameIcon = "shield"
        elseif self.waveModifier == "modifier_apocalypse_attack_range" then
            modifierNameIcon = "dragonlance"
        elseif self.waveModifier == "modifier_apocalypse_corpse_explosion" then
            modifierNameIcon = "skull"
        elseif self.waveModifier == "modifier_apocalypse_evasion" then
            modifierNameIcon = "butterfly"
        elseif self.waveModifier == "modifier_apocalypse_increased_speed" then
            modifierNameIcon = "speed"
        elseif self.waveModifier == "modifier_apocalypse_life_blood" then
            modifierNameIcon = "kadash_survival_skills"
        elseif self.waveModifier == "modifier_apocalypse_magic_attacks" then
            modifierNameIcon = "magicdmg"
        elseif self.waveModifier == "modifier_apocalypse_magic_resistance" then
            modifierNameIcon = "magicres"
        elseif self.waveModifier == "modifier_apocalypse_mana_burn" then
            modifierNameIcon = "manaburn"
        elseif self.waveModifier == "modifier_apocalypse_rushing" then
            modifierNameIcon = "rushing"
        elseif self.waveModifier == "modifier_apocalypse_health_deny" then
            modifierNameIcon = "healthdeny"
        elseif self.waveModifier == "modifier_apocalypse_magic_shield" then
            modifierNameIcon = "magicshield"
        elseif self.waveModifier == "modifier_apocalypse_mana_void" then
            modifierNameIcon = "manavoid"
        elseif self.waveModifier == "modifier_apocalypse_reanimation" then
            modifierNameIcon = "skeleton_king_reincarnation"
        end

        --[[EmitGlobalSound("TCOTRPG.Waves.Modifier.New")

        CustomGameEventManager:Send_ServerToAllClients("wave_manager_modifier_notification", {
            modifier = self.waveModifier,
            modifierImage = modifierNameIcon,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })--]]

        self.waveModifierFactorRemaining = self.waveModifierFactor
        self.waveModifierFactorEnabled = true
    end

    local unit = CreateUnitByName(randomUnit, randomSpawnPoint:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)

    -- Remove respawn abilities
    if unit:FindAbilityByName("Respawn") then
        unit:RemoveAbility("Respawn")
    end

    if unit:FindAbilityByName("Respawn_Forever") then
        unit:RemoveAbility("Respawn_Forever")
    end

    if unit:FindAbilityByName("Respawn_boss_SF2") then
        unit:RemoveAbility("Respawn_boss_SF2")
    end

    if unit:FindAbilityByName("Respawn_boss_SF4") then
        unit:RemoveAbility("Respawn_boss_SF4")
    end

    -- Add AI
    unit:AddNewModifier(unit, nil, "modifier_wave_manager_unit_ai", {
        unitCount = self.unitsSpawned,
        timePassed = self.timePassed
    })

    if self.waveModifierFactorEnabled == true then
        if self.waveModifierFactorRemaining > 0 and self.waveModifier then
            unit:AddNewModifier(unit, nil, self.waveModifier, {})
            self.waveModifierFactorRemaining = self.waveModifierFactorRemaining - 1
        end

        if self.waveModifierFactorRemaining < 1 then
            self.waveModifierFactorEnabled = false
        end
    end

    -- Add true sight passive 
    if not unit:FindAbilityByName("necronomicon_warrior_sight") then
        unit:AddAbility("necronomicon_warrior_sight")
    end

    -- If it's a boss, add the boss passives 
    if isBoss then
        if unit:FindAbilityByName("boss_shell_custom") then
            unit:RemoveAbility("boss_shell_custom")
        end
    end
end
---------------------------
function modifier_wave_manager_unit_ai:DeclareFunctions()
    return {
        --MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        --MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        --MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT,
        --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_wave_manager_unit_ai:OnDeath(event)
    if not IsServer() then return end

    if _G.GameHasEnded then return end

    if event.unit == self:GetParent() then
        if self:GetParent():GetUnitName() == "npc_dota_creature_wave_enemy_necrolyte" then
            _G.WavesNecrolyteAlive = false
        end

        local toRemove = WaveManager.unitsAlive - 1
        
        if toRemove < 0 then
            toRemove = 0
        end

        WaveManager.unitsAlive = toRemove

        WaveManager.unitsKilled = WaveManager.unitsKilled + 1

        CustomGameEventManager:Send_ServerToAllClients("wave_manager_modifier_unit_count", {
            killed = WaveManager.unitsKilled,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end

    if event.attacker == self:GetParent() and event.unit:IsRealHero() and not event.unit:IsIllusion() then
        local connectionState = PlayerResource:GetConnectionState(event.unit:GetPlayerID())
        if connectionState == DOTA_CONNECTION_STATE_CONNECTED then
            WaveManager.playerDeaths = WaveManager.playerDeaths + 1

            CustomGameEventManager:Send_ServerToAllClients("wave_manager_modifier_unit_count", {
                deaths = WaveManager.playerDeaths,
                a = RandomFloat(1,1000),
                b = RandomFloat(1,1000),
                c = RandomFloat(1,1000),
            })
        end
    end

    if event.attacker ~= self:GetParent() or event.unit == self:GetParent() then return end
    if event.unit:GetTeam() == event.attacker:GetTeam() then return end
    if not event.unit:IsRealHero() or event.unit:IsIllusion() then return end

    local sounds = {
        "TCOTRPG.Waves.Aghanim.CheckOutThisGuy",
        "TCOTRPG.Waves.Aghanim.CheckOutTheHustle",
        "TCOTRPG.Waves.Aghanim.SmallBusinessOwner",
        "TCOTRPG.Waves.Aghanim.BroEntrance",
        "TCOTRPG.Waves.Aghanim.GoatEntrance",
        "TCOTRPG.Waves.Aghanim.BucketEntrance",
        "TCOTRPG.Waves.Aghanim.MechEntrance",
        "TCOTRPG.Waves.Aghanim.LookWhoItIs",
        "TCOTRPG.Waves.Aghanim.LotsOfHobbies",
        "TCOTRPG.Waves.Aghanim.Shazaam",
        "TCOTRPG.Waves.Aghanim.FlickOfTheWrist",
        "TCOTRPG.Waves.Aghanim.Booyah",
        "TCOTRPG.Waves.Aghanim.Hiyahh_01",
        "TCOTRPG.Waves.Aghanim.Hiyahh_02",
        "TCOTRPG.Waves.Aghanim.Hiyahh_03",
        "TCOTRPG.Waves.Aghanim.Hiyahh_04",
        "TCOTRPG.Waves.Aghanim.BingBong_01",
        "TCOTRPG.Waves.Aghanim.BingBong_02",
        "TCOTRPG.Waves.Aghanim.BingBong_03",
        "TCOTRPG.Waves.Aghanim.BoopityBop_01",
        "TCOTRPG.Waves.Aghanim.BoopityBop_02",
        "TCOTRPG.Waves.Aghanim.BoopityBop_03",
    }

    EmitGlobalSound(sounds[RandomInt(1, #sounds)])
end

--[[
function modifier_wave_manager_unit_ai:GetModifierIncomingSpellDamageConstant(event)
    local armor = self.fArmor -- calculate the current armor value
    local damageReduction = armor / (armor + 120) -- calculate the damage reduction based on armor using a logarithmic function
    local total = -(event.damage-(event.damage * (1 - damageReduction))) -- apply the damage reduction to the incoming spell damage

    return total
end
--]]

function modifier_wave_manager_unit_ai:GetModifierMagicalResistanceBonus()
    return self.fMagicResistance
end

function modifier_wave_manager_unit_ai:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_wave_manager_unit_ai:GetModifierTotalDamageOutgoing_Percentage()
    return self.fDamage
end

function modifier_wave_manager_unit_ai:GetModifierIncomingDamage_Percentage()
    return self.fDr
end

function modifier_wave_manager_unit_ai:GetModifierAttackSpeedBonus_Constant()
    return self.fAttackSpeed
end

function modifier_wave_manager_unit_ai:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    WaveManager.unitsAlive = WaveManager.unitsAlive + 1

    local parent = self:GetParent()

    -- Give them the max movement capability
    parent:AddNewModifier(parent, nil, "modifier_max_movement_speed", {})

    self.target = nil

    self.abilities = {}
    self.maxAbilities = 1
    self.numAbilities = RandomInt(1, self.maxAbilities)

    self.unitCount = params.unitCount
    self.timePassed = params.timePassed

    self.scalingMultiplier = 2.472
    
    if IsBossTCOTRPG(parent) then
        self.scalingMultiplier = self.scalingMultiplier * 2
    end

    self.armor = self.unitCount * self.scalingMultiplier -- +1 armor per unit spawned 
    self.damage = self.unitCount * self.scalingMultiplier -- +1% outgoing damage per unit spawned
    self.health = self.unitCount * self.scalingMultiplier * self.timePassed -- 1 hour would be +18m HP roughly?
    self.attackSpeed = self.unitCount * self.scalingMultiplier

    -- Health has to be added this way
    -- You can't add health with a property apparently...
    local maxHealth = parent:GetMaxHealth()
    maxHealth = maxHealth + self.health

    if maxHealth > INT_MAX_LIMIT then
        maxHealth = INT_MAX_LIMIT
    end

    parent:SetBaseMaxHealth(maxHealth)
    parent:SetMaxHealth(maxHealth)
    parent:SetHealth(maxHealth)

    parent:SetBaseMagicalResistanceValue(98) -- We override this since enemies/bosses have different values in the KV

    -- Calculate our magic resistance 
    -- Enemies need to have 0% magic resistance in the unit KV because 50% is the base here (0.5)
    self.magicResistance = 1 - ((1 - 0.7) * math.pow(1 - (self.scalingMultiplier/100), self.unitCount))
    self.magicResistance = math.max(self.magicResistance, (self.scalingMultiplier/100)) * 100

    -- I don't trust it to not get to 100% tbh
    if self.magicResistance >= 90 then
        self.magicResistance = 90
    end

    self.dr = -math.abs(self.magicResistance)

    self.resurrectTimer = nil

    self.primaryZone = Entities:FindByName(nil, "wave_manager_zone")

    self:InvokeBonus()

    -- True sight 
    if not parent:FindAbilityByName("necronomicon_warrior_sight") then
        parent:AddAbility("necronomicon_warrior_sight")
    end

    -- Add a random ability 
    local abilityPool = {
        "invoker_chaos_meteor_lua",
        "follower_skafian_leech_seed",
        "follower_skafian_healing",
        "follower_spider_earthquake",
        "follower_spider_burrow",
        "follower_spider_sandstorm",
        "creature_wave_silence",
        "creature_wave_taunt",
        "creep_wave_ministun",
        "creature_wave_solar_bind"
    }

    abilityPool = shuffleTable(abilityPool)
    local i = 0
    for _,shuffle in ipairs(abilityPool) do
        if i < self.numAbilities then
            local randomAbility = abilityPool[RandomInt(1, #abilityPool)]
            if not parent:FindAbilityByName(randomAbility) then
                local newAbility = parent:AddAbility(randomAbility)
                newAbility:SetLevel(GetLevelFromDifficulty())
                newAbility:SetActivated(true)
                newAbility:SetHidden(false)

                if bit.band(newAbility:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_AUTOCAST) ~= 0 and not newAbility:GetAutoCastState() then
                    newAbility:ToggleAutoCast()
                end
            end
        else
            break
        end

        i = i + 1
    end

    for i=0, parent:GetAbilityCount()-1 do
        local abil = parent:GetAbilityByIndex(i)
        if abil ~= nil then
            table.insert(self.abilities, abil:GetAbilityName())
        end
    end

    -- 0.1 might be better than FrameTime() to reduce lag
    self:OnIntervalThink()
    self:StartIntervalThink(0.3)
end

function modifier_wave_manager_unit_ai:OnIntervalThink()
    if _G.GameHasEnded then return end

    local parent = self:GetParent()

    -- Disable the AI entirely if the unit is channeling an ability
    if parent:IsChanneling() then return end

    -- Make sure the player stays inside the zone --
    if parent:IsAlive() and not IsInTrigger(parent, self.primaryZone) then
        parent:SetAbsOrigin(self.primaryZone:GetAbsOrigin())
        FindClearSpaceForUnit(parent, self.primaryZone:GetAbsOrigin(), false)
    end
 
    -- Ability casting logic --
    if self.target ~= nil and not self.target:IsNull() and #self.abilities > 0 then
        -- The unit will attempt to cast an ability on the target if the target is within 850 units
        if ((parent:GetAbsOrigin() - self.target:GetAbsOrigin()):Length2D() <= 850) then
            for _,name in ipairs(self.abilities) do
                local ability = parent:FindAbilityByName(name)
                if ability ~= nil and ability:IsCooldownReady() and not parent:IsSilenced() and not parent:IsStunned() and not parent:IsHexed()  then
                    local castTarget = nil

                    if bit.band(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) ~= 0 or bit.band(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_POINT) ~= 0 then
                        castTarget = self.target
                    end

                    if bit.band(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_NO_TARGET) ~= 0 then
                        castTarget = parent
                    end

                    -- Prevent friendly abilities from being cast on enemy heroes
                    -- Cast it on allies instead
                    if bit.band(ability:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_FRIENDLY) ~= 0 then
                        local allies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
                            900, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                            FIND_CLOSEST, false)

                        for _,ally in ipairs(allies) do
                            if ally:IsAlive() then
                                castTarget = selectedAlly
                                break
                            end
                        end
                    end 

                    -- Don't cast it if it's autocast
                    if bit.band(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_AUTOCAST) ~= 0 then
                        castTarget = nil
                    end

                    if castTarget then
                        if string.match(ability:GetAbilityName(), "ice_blast_release") then
                            Timers:CreateTimer(1, function()
                                SpellCaster:Cast(ability, castTarget, true)
                            end)
                        else
                            SpellCaster:Cast(ability, castTarget, true)
                        end
                    end
                end
            end
        end
    end

    -- Targeting logic --
    if self.target ~= nil and not self.target:IsNull() then
        if not parent:IsTaunted() then
            -- The target must be alive, not be attack immune
            if self.target:IsAlive() and not self.target:IsInvulnerable() and not self.target:IsUntargetableFrom(parent) and IsInTrigger(self.target, self.primaryZone) then
                parent:SetForceAttackTarget(self.target)
            else
                parent:SetForceAttackTarget(nil)
                self.target = nil
            end
        end
    end

    -- We will continue to search for units even if there is a target already 
    -- to see if there's another target that is closer
    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and victim ~= self.target and not victim:HasModifier("modifier_wave_manager_fow_revealer") and not victim:HasModifier("modifier_chicken_ability_1_self_transmute") then
            if self.target ~= nil then
                local victimDistance = parent:GetRangeToUnit(victim)
                local currentTargetDistance = parent:GetRangeToUnit(self.target)

                -- If there is a unit that is closer to the unit than the current target,
                -- we change the target to be that unit instead
                if victimDistance < currentTargetDistance then
                    self.target = victim 
                    break
                end
            else
                self.target = victim 
                break
            end
        end
    end
end

function modifier_wave_manager_unit_ai:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    --if parent:IsAlive() then
        --parent:ForceKill(false)
    --end
end

function modifier_wave_manager_unit_ai:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
        armor = self.fArmor,
        magicResistance = self.fMagicResistance,
        health = self.fHealth,
        dr = self.fDr,
        attackSpeed = self.fAttackSpeed
    }
end

function modifier_wave_manager_unit_ai:HandleCustomTransmitterData(data)
    if data.damage ~= nil and data.armor ~= nil and data.magicResistance ~= nil and data.health ~= nil and data.dr ~= nil and data.attackSpeed ~= nil then
        self.fDamage = tonumber(data.damage)
        self.fArmor = tonumber(data.armor)
        self.fMagicResistance = tonumber(data.magicResistance)
        self.fHealth = tonumber(data.health)
        self.fDr = tonumber(data.dr)
        self.fAttackSpeed = tonumber(data.attackSpeed)
    end
end

function modifier_wave_manager_unit_ai:InvokeBonus()
    if IsServer() == true then
        self.fDamage = self.damage
        self.fArmor = self.armor
        self.fMagicResistance = self.magicResistance
        self.fHealth = self.health
        self.fDr = self.dr
        self.fAttackSpeed = self.attackSpeed

        self:SendBuffRefreshToClients()
    end
end

function modifier_wave_manager_unit_ai:GetEffectName()
    return "particles/models/items/warlock/ti10_puppet_summoner_golem/ti10_puppet_summoner_golem.vpcf"
end

function modifier_wave_manager_unit_ai:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_wave_manager_unit_ai:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_wave_manager_unit_ai:StatusEffectPriority()
    return 10001
end

function modifier_wave_manager_unit_ai:CheckState()
    return {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
end
-----------------------------------------------------
function modifier_wave_manager_player:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_START,
        MODIFIER_EVENT_ON_ABILITY_END_CHANNEL 
    }
end

function modifier_wave_manager_player:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local connectionState = PlayerResource:GetConnectionState(parent:GetPlayerID())

    -- Do not add this for abyssal season
    --parent:AddNewModifier(parent, nil, "modifier_season_death", {})
    
    parent:AddNewModifier(parent, nil, "modifier_season_frenzy", {})

    self.primaryZone = Entities:FindByName(nil, "wave_manager_zone")

    parent:SetTimeUntilRespawn(99999)
    parent:SetRespawnsDisabled(true)

    if connectionState == DOTA_CONNECTION_STATE_CONNECTED then
        self:StartIntervalThink(0.1)
    end
end

function modifier_wave_manager_player:OnIntervalThink()
    if _G.GameHasEnded then return end

    local parent = self:GetParent()

    -- Make sure the player stays inside the zone --
    if parent:IsAlive() and not IsInTrigger(parent, self.primaryZone) then
        parent:SetAbsOrigin(self.primaryZone:GetAbsOrigin())
        FindClearSpaceForUnit(parent, self.primaryZone:GetAbsOrigin(), false)
        parent:CenterCameraOnEntity(parent, 3)
    end
end

function modifier_wave_manager_player:OnAbilityEndChannel(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end
    if event.ability:GetAbilityName() ~= "item_tombstone" then return end

    if self.resurrectTimer ~= nil then
        Timers:RemoveTimer(self.resurrectTimer)
        self.resurrectTimer = nil
    end
end

function modifier_wave_manager_player:OnAbilityStart(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end
    if event.ability:GetAbilityName() ~= "item_tombstone" then return end

    if self.resurrectTimer ~= nil then
        Timers:RemoveTimer(self.resurrectTimer)
        self.resurrectTimer = nil
    end

    self.resurrectTimer = Timers:CreateTimer(event.ability:GetChannelTime(), function()
        --local debuff = parent:FindModifierByName("modifier_wave_manager_player_attribute_debuff")
        --if not debuff then
        --    debuff = parent:AddNewModifier(parent, nil, "modifier_wave_manager_player_attribute_debuff", {})
        --end

        --if debuff then
        --    debuff:IncrementStackCount()
        --end

        self.resurrectTimer = nil
    end)
end

function modifier_wave_manager_player:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
end
------------------
function modifier_wave_manager_player_attribute_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, 
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS 
    }
end

function modifier_wave_manager_player_attribute_debuff:GetModifierBonusStats_Agility()
    return self.fAgi
end

function modifier_wave_manager_player_attribute_debuff:GetModifierBonusStats_Intellect()
    return self.fInt
end

function modifier_wave_manager_player_attribute_debuff:GetModifierBonusStats_Strength()
    return self.fStr
end

function modifier_wave_manager_player_attribute_debuff:GetPriority()
    return 999998
end

function modifier_wave_manager_player_attribute_debuff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end
end

function modifier_wave_manager_player_attribute_debuff:OnStackCountChanged()
    if not IsServer() then return end

    self.agi = self:GetParent():GetBaseAgility() * -0.1 * self:GetStackCount()
    self.str = self:GetParent():GetBaseStrength() * -0.1 * self:GetStackCount()
    self.int = self:GetParent():GetBaseIntellect() * -0.1 * self:GetStackCount()

    self:InvokeAttributes()
end

function modifier_wave_manager_player_attribute_debuff:GetTexture() return "item_tombstone" end

function modifier_wave_manager_player_attribute_debuff:AddCustomTransmitterData()
    return
    {
        agi = self.fAgi,
        str = self.fStr,
        int = self.fInt
    }
end

function modifier_wave_manager_player_attribute_debuff:HandleCustomTransmitterData(data)
    if data.agi ~= nil and data.str ~= nil and data.int ~= nil then
        self.fAgi = tonumber(data.agi)
        self.fStr = tonumber(data.str)
        self.fInt = tonumber(data.int)
    end
end

function modifier_wave_manager_player_attribute_debuff:InvokeAttributes()
    if IsServer() == true then
        self.fAgi = self.agi
        self.fStr = self.str
        self.fInt = self.int

        self:SendBuffRefreshToClients()
    end
end
-------------------------------------------------
function modifier_wave_manager_fow_revealer:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    AddFOWViewer(parent:GetTeam(), parent:GetAbsOrigin(), 4000, 9999999, true)
end

function modifier_wave_manager_fow_revealer:CheckState()
    local state = { 
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end
---------------
function modifier_wave_manager_player_thinker:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(60)
end

function modifier_wave_manager_player_thinker:OnIntervalThink()
    local parent = self:GetParent()

    local connectionState = PlayerResource:GetConnectionState(parent:GetPlayerID())

    if UnitIsNotMonkeyClone(parent) and parent:IsRealHero() and not parent:IsIllusion() and not IsSummonTCOTRPG(parent) and connectionState == DOTA_CONNECTION_STATE_CONNECTED then
        self:UpdateLeaderboardScore(parent)
    end
end