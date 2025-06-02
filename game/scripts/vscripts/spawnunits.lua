if modifier_unit_on_death == nil then modifier_unit_on_death = class({}) end
if modifier_unit_out_of_game == nil then modifier_unit_out_of_game = class({}) end
if modifier_unit_boss == nil then modifier_unit_boss = class({}) end
if modifier_unit_boss_2 == nil then modifier_unit_boss_2 = class({}) end

LinkLuaModifier( "modifier_unit_on_death", 'spawnunits', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_unit_out_of_game", 'spawnunits', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_unit_boss", 'spawnunits', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_unit_boss_2", 'spawnunits', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_boss_zeus_secret", "modifiers/modifier_evil_citadel", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_creep_elite", "modifiers/modifier_creep_elite", LUA_MODIFIER_MOTION_NONE)

function modifier_unit_boss:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
    }

    return funcs
end

function modifier_unit_boss:GetModifierIgnoreMovespeedLimit()
    return 1
end

function modifier_unit_boss:GetModifierMoveSpeed_Limit()
    return 2000
end

function modifier_unit_boss:GetModifierProvidesFOWVision()
    if _G.FinalGameWavesEnabled then return 0 end
    return 1
end

function modifier_unit_boss:OnCreated(event)
    if not IsServer() then return end

    self:GetParent():AddItemByName("item_monkey_king_bar")

    self:StartIntervalThink(1)
end

function modifier_unit_boss:OnIntervalThink()
    local parent = self:GetParent()

    if not parent:IsAlive() then return end

    if _G.FinalGameWavesEnabled then
        Timers:CreateTimer(parent:entindex()/1000, function()
            UTIL_RemoveImmediate(parent)
        end)
        return
    end
end

function modifier_unit_boss:GetModifierStatusResistance()
    return 75
end

function modifier_unit_boss:IsHidden()
    return true
end

function modifier_unit_boss:IsPurgable()
    return false
end

function modifier_unit_boss:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
        [MODIFIER_STATE_ALLOW_PATHING_THROUGH_CLIFFS] = false,
        [MODIFIER_STATE_ALLOW_PATHING_THROUGH_FISSURE] = false,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        --[MODIFIER_STATE_CANNOT_MISS] = true,
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true
    }

    return state
end
--
function modifier_unit_boss_2:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
    }

    return funcs
end

function modifier_unit_boss_2:OnCreated()
    if not IsServer() then return end

    if self:GetParent():GetUnitName() == "npc_dota_creature_roshan_boss" then
        local parent = self:GetParent()
        local level = GetLevelFromDifficulty()

        Timers:CreateTimer(1.0, function()
            for i = 0, parent:GetAbilityCount() - 1 do
                local abil = parent:GetAbilityByIndex(i)
                if abil ~= nil then
                    abil:SetLevel(level)
                end
            end
        end)
    end

    self:StartIntervalThink(1)
end

function modifier_unit_boss_2:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if parent:IsAlive() then
        if _G.FinalGameWavesEnabled then
            Timers:CreateTimer(parent:entindex()/1000, function()
                UTIL_RemoveImmediate(parent)
            end)
            return
        end
    end

    if not parent:IsAlive() or not parent:IsAttacking() or parent:GetUnitName() ~= "npc_dota_creature_roshan_boss" then return end

    local slam = parent:FindAbilityByName("roshan_slam_custom")
    if slam ~= nil and slam:IsCooldownReady() and slam:IsFullyCastable() then
        --SpellCaster:Cast(slam, parent, true)
        parent:CastAbilityImmediately(slam, -1)
    end
end

function modifier_unit_boss_2:GetModifierIgnoreMovespeedLimit()
    return 1
end


function modifier_unit_boss_2:GetModifierMoveSpeed_Limit()
    return 2000
end

function modifier_unit_boss_2:GetModifierProvidesFOWVision()
    if _G.FinalGameWavesEnabled then return 0 end
    return 1
end

function modifier_unit_boss_2:IsHidden()
    return true
end

function modifier_unit_boss_2:IsPurgable()
    return false
end

function modifier_unit_boss_2:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
        [MODIFIER_STATE_ALLOW_PATHING_THROUGH_CLIFFS] = false,
        [MODIFIER_STATE_ALLOW_PATHING_THROUGH_FISSURE] = false,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true
    }

    return state
end
--

function modifier_unit_out_of_game:CheckState()
    local state = {
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
    return state
end

function modifier_unit_out_of_game:OnCreated()
    if not IsServer() then return end

    self:GetCaster():AddNoDraw()
end

function modifier_unit_out_of_game:OnRemoved()
    if not IsServer() then return end

    self:GetCaster():RemoveNoDraw()
end

function modifier_unit_out_of_game:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_unit_on_death:OnCreated(kv)
  if not IsServer() then return end

  self.spawnPos = Vector(kv.posX, kv.posY, kv.posZ)
  self.unitName = kv.name
  self.unit = self:GetParent()
end

function modifier_unit_on_death:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_DEATH
  }

  return funcs
end

function modifier_unit_on_death:IsHidden()
  return true
end

function modifier_unit_on_death:CheckState()
    local states = {
        --[MODIFIER_STATE_NO_HEALTH_BAR] = true
    }

    return states
end

--------------------------------------------------------------------------------

function modifier_unit_on_death:IsPurgable()
  return false
end

function modifier_unit_on_death:OnDeath(event)
    if not IsServer() then return end

    local creep = event.unit
    
    if creep ~= self:GetParent() then
        return
    end

    if creep:GetUnitName() == "boss_arc_warden" then return end

    if creep:GetUnitName() == "npc_dota_creature_roshan_boss" then
        local heroes = HeroList:GetAllHeroes()
        for _,hero in ipairs(heroes) do
            if UnitIsNotMonkeyClone(hero) and not hero:IsTempestDouble() then
                if PlayerResource:GetConnectionState(hero:GetPlayerID()) == DOTA_CONNECTION_STATE_CONNECTED then
                    hero:ModifyGold(5000, false, 0)
                end
            end
        end

        DropNeutralItemAtPositionForHero("item_roshan_soul", event.unit:GetAbsOrigin(), event.unit, 1, false)
    end

    local amountTime = CREEP_RESPAWN_TIME

    if IsBossTCOTRPG(creep) then
        amountTime = BOSS_RESPAWN_TIME
    end

    if creep:GetUnitName() == "npc_tcot_tormentor" then
        amountTime = 300
    end

    --[[
    if creep:GetUnitName() == "npc_dota_creature_140_crip_Robo" or creep:GetUnitName() == "npc_dota_creature_100_crip" or creep:GetUnitName() == "npc_dota_creature_100_crip_2" then
        amountTime = 0.1
    end
    --]]

    if FAST_BOSSES_VOTE_RESULT:upper() == "ENABLE" and IsCreepTCOTRPG(creep) then
        amountTime = 1
    end

    if IsBossTCOTRPG(creep) then
        local soulDrop = ""
        local bossName = creep:GetUnitName()
        if bossName == "npc_dota_creature_40_boss_2" then
            soulDrop = "item_spider_soul"
        elseif bossName == "npc_dota_creature_80_boss" then
            soulDrop = "item_elder_soul"
        elseif bossName == "npc_dota_creature_roshan_boss" then
            soulDrop = "item_roshan_soul"
        end

        local heroes = HeroList:GetAllHeroes()
        for _,hero in ipairs(heroes) do
            if UnitIsNotMonkeyClone(hero) and not hero:IsTempestDouble() then
                if PlayerResource:GetConnectionState(hero:GetPlayerID()) == DOTA_CONNECTION_STATE_CONNECTED then
                    if hero:FindItemInAnyInventory(soulDrop) == nil then
                        if _G.autoPickup[hero:GetPlayerID()] ~= AUTOLOOT_ON_NO_SOULS then
                            --hero:AddItemByName(soulDrop)
                        end
                    end
                    hero:ModifyGold(1000, false, 0)
                end
            end
        end
    end

    if IsCreepTCOTRPG(creep) then
        if creep:GetUnitName() == "npc_dota_creature_100_crip" and event.attacker:GenerateDropChance() <= 5.0 then
            DropNeutralItemAtPositionForHero("item_forgotten_book", creep:GetAbsOrigin(), creep, 1, false)
        end
    end
    
    Timers:CreateTimer(amountTime, function()
      if _G.FinalGameWavesEnabled then return end
      if IsPvP() then return end

      CreateUnitByNameAsync(self.unitName, self.spawnPos, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_unit_on_death", {
                posX = self.spawnPos.x,
                posY = self.spawnPos.y,
                posZ = self.spawnPos.z,
                name = self.unitName
            })

            if IsBossTCOTRPG(unit) then
                if unit:GetUnitName() == "npc_dota_creature_100_boss_2" then
                    unit:AddNewModifier(unit, nil, "modifier_unit_boss", {})
                else
                    unit:AddNewModifier(unit, nil, "modifier_unit_boss_2", {})
                end
            else
                if RollPercentage(ELITE_SPAWN_CHANCE) and unit:GetUnitName() ~= "npc_tcot_tormentor" then
                    unit:AddNewModifier(unit, nil, "modifier_creep_elite", {})
                end
            end
        end)
    end)
end

function SpawnAllUnits()
    function SpawnBossInZone(zoneName, unitName)
        local zones = Entities:FindAllByName(zoneName)

        for _, zone in ipairs(zones) do
            local point = zone:GetAbsOrigin() + RandomVector(RandomFloat( 0, 10))
            CreateUnitByNameAsync(unitName, point, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
                -- Add Keymaster AI only
                if string.match(unit:GetUnitName(), "npc_dota_boss_keymaster") then
                    unit:AddNewModifier(unit, nil, "boss_keymaster_ai", {})
                    return
                end

                --Async is faster and will help reduce stutter
                if unit:GetUnitName() == "npc_dota_creature_100_boss_2" then
                    unit:AddNewModifier(unit, nil, "modifier_unit_boss", {})
                else
                    unit:AddNewModifier(unit, nil, "modifier_unit_boss_2", {})
                end
                --

                if unit:GetUnitName() == "npc_dota_creature_70_boss" then
                    unit:AddNewModifier(unit, nil, "modifier_walking_animation_fix", {})
                end

                if unitName == "npc_dota_creature_30_boss" then 
                    unit:AddNewModifier(unit, nil, "modifier_boss_skafian", {
                        posX = unit:GetAbsOrigin().x,
                        posY = unit:GetAbsOrigin().y,
                        posZ = unit:GetAbsOrigin().z,
                    })
                elseif unitName == "npc_dota_creature_80_boss" then 
                    unit:AddNewModifier(unit, nil, "modifier_boss_spider", {
                        posX = unit:GetAbsOrigin().x,
                        posY = unit:GetAbsOrigin().y,
                        posZ = unit:GetAbsOrigin().z,
                    })  
                elseif unitName == "npc_dota_creature_40_boss" then 
                    unit:AddNewModifier(unit, nil, "modifier_boss_zombie", {
                        posX = unit:GetAbsOrigin().x,
                        posY = unit:GetAbsOrigin().y,
                        posZ = unit:GetAbsOrigin().z,
                    }) 
                elseif unitName == "npc_dota_creature_70_boss" then 
                    unit:AddNewModifier(unit, nil, "modifier_boss_mine", {
                        posX = unit:GetAbsOrigin().x,
                        posY = unit:GetAbsOrigin().y,
                        posZ = unit:GetAbsOrigin().z,
                    }) 
                elseif unitName == "npc_dota_creature_130_boss_death" then 
                    unit:AddNewModifier(unit, nil, "modifier_boss_lake", {
                        posX = unit:GetAbsOrigin().x,
                        posY = unit:GetAbsOrigin().y,
                        posZ = unit:GetAbsOrigin().z,
                    }) 
                elseif unitName == "npc_dota_creature_100_boss" then 
                    unit:AddNewModifier(unit, nil, "modifier_boss_lava", {
                        posX = unit:GetAbsOrigin().x,
                        posY = unit:GetAbsOrigin().y,
                        posZ = unit:GetAbsOrigin().z,
                    }) 
                elseif unitName == "npc_dota_creature_150_boss_last" then 
                    unit:AddNewModifier(unit, nil, "modifier_boss_divine", {
                        posX = unit:GetAbsOrigin().x,
                        posY = unit:GetAbsOrigin().y,
                        posZ = unit:GetAbsOrigin().z,
                    }) 
                else
                    unit:AddNewModifier(unit, nil, "modifier_unit_on_death", {
                        posX = unit:GetAbsOrigin().x,
                        posY = unit:GetAbsOrigin().y,
                        posZ = unit:GetAbsOrigin().z,
                        name = unitName
                    })
                end
                --
            end)
        end
    end
    
    function SpawnUnitsInZone(zoneName, unitName, max, boss)
        local zones = Entities:FindAllByName(zoneName)

        for _, zone in ipairs(zones) do
            local point = zone:GetAbsOrigin() + RandomVector(RandomFloat( 0, 10))
            
            for i = 1, max do
                CreateUnitByNameAsync(unitName, point, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
                    --Async is faster and will help reduce stutter

                    if modifier_boss_lake:IsFollower(unit) then 
                        unit:AddNewModifier(unit, nil, "modifier_boss_lake_follower", {
                            posX = unit:GetAbsOrigin().x,
                            posY = unit:GetAbsOrigin().y,
                            posZ = unit:GetAbsOrigin().z,
                        }):ForceRefresh() 
                        return
                    end

                    if modifier_boss_skafian:IsFollower(unit) then 
                        unit:AddNewModifier(unit, nil, "modifier_boss_skafian_follower", {
                            posX = unit:GetAbsOrigin().x,
                            posY = unit:GetAbsOrigin().y,
                            posZ = unit:GetAbsOrigin().z,
                        }):ForceRefresh() 
                    elseif modifier_boss_spider:IsFollower(unit) then 
                        unit:AddNewModifier(unit, nil, "modifier_boss_spider_follower", {
                            posX = unit:GetAbsOrigin().x,
                            posY = unit:GetAbsOrigin().y,
                            posZ = unit:GetAbsOrigin().z,
                        }):ForceRefresh() 
                    elseif modifier_boss_zombie:IsFollower(unit) then 
                        unit:AddNewModifier(unit, nil, "modifier_boss_zombie_follower", {
                            posX = unit:GetAbsOrigin().x,
                            posY = unit:GetAbsOrigin().y,
                            posZ = unit:GetAbsOrigin().z,
                        }):ForceRefresh() 
                    elseif modifier_boss_mine:IsFollower(unit) then 
                        unit:AddNewModifier(unit, nil, "modifier_boss_mine_follower", {
                            posX = unit:GetAbsOrigin().x,
                            posY = unit:GetAbsOrigin().y,
                            posZ = unit:GetAbsOrigin().z,
                        }):ForceRefresh() 
                    elseif modifier_boss_lava:IsFollower(unit) then 
                        unit:AddNewModifier(unit, nil, "modifier_boss_lava_follower", {
                            posX = unit:GetAbsOrigin().x,
                            posY = unit:GetAbsOrigin().y,
                            posZ = unit:GetAbsOrigin().z,
                        }):ForceRefresh() 
                    elseif modifier_boss_divine:IsFollower(unit) then 
                        unit:AddNewModifier(unit, nil, "modifier_boss_divine_follower", {
                            posX = unit:GetAbsOrigin().x,
                            posY = unit:GetAbsOrigin().y,
                            posZ = unit:GetAbsOrigin().z,
                        }):ForceRefresh() 
                    else 
                        unit:AddNewModifier(unit, nil, "modifier_unit_on_death", {
                            posX = unit:GetAbsOrigin().x,
                            posY = unit:GetAbsOrigin().y,
                            posZ = unit:GetAbsOrigin().z,
                            name = unitName,
                        })
                    end
                end)
            end
        end
    end

    if IsPvP() then
        SpawnUnitsInZone("spawn_creep_1", "npc_dota_creature_1_crip", 1) -- Mole
        SpawnUnitsInZone("spawn_creep_2", "npc_dota_creature_30_crip", 3) -- Bear
        SpawnUnitsInZone("spawn_creep_13", "npc_dota_creature_30_crip_2", 2) -- Wolf
        SpawnUnitsInZone("spawn_creep_10", "npc_dota_creature_10_crip_2", 1)
        SpawnUnitsInZone("spawn_creep_16", "npc_dota_creature_10_crip_4", 1)
        SpawnUnitsInZone("spawn_creep_11", "npc_dota_creature_10_crip_3", 1)
    else
        --SpawnBossInZone("spawn_boss_keymaster_1", "npc_dota_boss_keymaster_1")
        --SpawnBossInZone("spawn_boss_keymaster_2", "npc_dota_boss_keymaster_2")
        --SpawnBossInZone("spawn_boss_keymaster_3", "npc_dota_boss_keymaster_3")

        -- Forest + Starting Zone --
        SpawnUnitsInZone("spawn_creep_1", "npc_dota_creature_1_crip", 1) -- Mole
        
        SpawnBossInZone("spawn_boss_roshan", "npc_dota_creature_roshan_boss")
        SpawnBossInZone("spawn_boss_skafian2", "npc_dota_creature_30_boss")
        SpawnUnitsInZone("spawn_creep_2", "npc_dota_creature_30_crip", 3) -- Bear
        SpawnUnitsInZone("spawn_creep_13", "npc_dota_creature_30_crip_2", 3) -- Wolf
        SpawnUnitsInZone("spawn_creep_21", "npc_dota_creature_30_crip_3", 1) -- Wolf Leader
        SpawnUnitsInZone("spawn_creep_10", "npc_dota_creature_10_crip_2", 1)
        SpawnUnitsInZone("spawn_creep_11", "npc_dota_creature_10_crip_3", 1)
        SpawnUnitsInZone("spawn_creep_16", "npc_dota_creature_10_crip_4", 1)

        -- Desert Zone --
        SpawnBossInZone("spawn_boss_spider", "npc_dota_creature_40_boss")
        SpawnUnitsInZone("spawn_creep_27", "npc_dota_creature_40_crip_7", 1) -- Tombstone

        -- Mines -- 
        SpawnBossInZone("spawn_boss_morphling", "npc_dota_creature_80_boss")
        SpawnUnitsInZone("spawn_creep_28", "npc_dota_creature_40_crip_2", 1)
        SpawnUnitsInZone("spawn_creep_29", "npc_dota_creature_40_crip_10", 1)
        SpawnUnitsInZone("spawn_creep_30", "npc_dota_creature_40_crip_4", 1)

        -- Winter Zone --
        SpawnBossInZone("spawn_boss_necro", "npc_dota_creature_130_boss_death")
        SpawnUnitsInZone("spawn_creep_4", "npc_dota_creature_130_crip2_death", 1) -- Creep in frozen lake
        SpawnUnitsInZone("spawn_creep_5", "npc_dota_creature_130_crip1_death", 1) -- Regular frozen lake (outside lake) enemy
        SpawnUnitsInZone("spawn_creep_18", "npc_dota_creature_130_crip3_death", 1) -- Creep in frozen lake but on the hill
        SpawnUnitsInZone("spawn_creep_19", "npc_dota_creature_130_crip4_death", 1) -- Frozen zone enemy (bird)
        SpawnUnitsInZone("spawn_creep_20", "npc_dota_creature_130_crip5_death", 1) -- Frozen zone enemy (wolf)

        -- Red Demon Zone --
        SpawnBossInZone("spawn_boss_enigma", "npc_dota_creature_70_boss")
        SpawnUnitsInZone("spawn_creep_7", "npc_dota_creature_70_crip", 1) -- Primal Beast mobs
        SpawnUnitsInZone("spawn_creep_15", "npc_dota_creature_70_crip_2", 1) -- Primal Beast mobs

        -- Dummy --
        SpawnUnitsInZone("spawn_target_dummy", "npc_dota_creature_target_dummy", 1)

        -- Lava Zone --
        SpawnUnitsInZone("spawn_creep_22", "npc_dota_creature_lava_1", 1) -- Lava mob
        SpawnUnitsInZone("spawn_creep_23", "npc_dota_creature_lava_2", 1) -- Lava mob
        SpawnBossInZone("spawn_boss_nevermore", "npc_dota_creature_100_boss")
        SpawnUnitsInZone("spawn_creep_9", "npc_dota_creature_100_crip", 1) 
        SpawnUnitsInZone("spawn_creep_12", "npc_dota_creature_140_crip_Robo", 1)

        -- Divine --
        SpawnBossInZone("spawn_boss_zeus", "npc_dota_creature_150_boss_last")

        -- Tormentor --
        SpawnUnitsInZone("spawn_tormentor", "npc_tcot_tormentor", 1)

        -- Uber Boss: Arc Warden
        SpawnUnitsInZone("spawn_boss_arc_warden", "boss_arc_warden", 1)
    end
    --
    
    if _G.DebugEnabled then
        SpawnBossInZone("spawn_boss_aghanim", "npc_dota_boss_aghanim")
    end
end