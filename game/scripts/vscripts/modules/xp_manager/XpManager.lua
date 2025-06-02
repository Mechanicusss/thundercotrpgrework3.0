XpManager = XpManager or class({})

modifier_xp_manager_player = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

function XpManager:Init()
    self.talents = {}
    self.playerTalents = {}
    self.playerResetCooldownTimer = {}
    self.playerCanLearn = {}

    self:LoadTalentData()

    CustomGameEventManager:RegisterListener("xp_manager_talent_learn", function(userId, event)
        if not IsInToolsMode() and (not IsDedicatedServer() or GameRules:IsCheatMode()) then return end
        if not _G.GlobalTalentsInitiated then return end

        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local accountID = PlayerResource:GetSteamID(id)

        local talentName = event.talent 

        if talentName == nil then
            --print("[Talents] Could not learn talent because talent is missing")
            return
        end

        local canLearnID = tostring(PlayerResource:GetSteamID(id))
        if not self.playerCanLearn[canLearnID] then
            DisplayError(id, "Waiting For Server.")
            return
        end

        local primaryAttribute = unit:GetPrimaryAttribute()
        local primaryAttribute_String = ""

        -- We have to do this since they are technically enums
        if primaryAttribute == DOTA_ATTRIBUTE_STRENGTH then
            primaryAttribute_String = "DOTA_ATTRIBUTE_STRENGTH"
        elseif primaryAttribute == DOTA_ATTRIBUTE_AGILITY then
            primaryAttribute_String = "DOTA_ATTRIBUTE_AGILITY"
        elseif primaryAttribute == DOTA_ATTRIBUTE_INTELLECT then
            primaryAttribute_String = "DOTA_ATTRIBUTE_INTELLECT"
        elseif primaryAttribute == DOTA_ATTRIBUTE_ALL then
            primaryAttribute_String = "DOTA_ATTRIBUTE_ALL"
        end

        local lookup = self:LookupTalent(talentName)
        if not lookup then return end 

        -- This makes it so players can only spend points on talents in their tree
        if lookup.attribute ~= primaryAttribute_String and lookup.attribute ~= "DOTA_ATTRIBUTE_ALL" then
            DisplayError(id, "Cannot Learn Talent Of Different Attribute.")
            return
        end

        -- This handles the previous talent requirement
        -- Meaning you can't level a talent if the required talent is not learned or is not the correct level
        --todo: make it so a talent can require multiple talents instead of just 1
        --todo: make it so the error says what talent it requires
        for _,requirement in pairs(lookup.requirement) do
            local requiredTalentName = requirement.name
            local requiredTalentLevel = requirement.level

            if requiredTalentName ~= "none" then
                local requiredTalent = unit:FindModifierByName("modifier_"..requiredTalentName)
                if not requiredTalent then
                    DisplayError(id, "Requires '#DOTA_Tooltip_Ability_"..requiredTalentName.."'")
                    return
                end
                
                if (requiredTalent ~= nil and requiredTalent:GetStackCount() ~= requiredTalentLevel) then
                    DisplayError(id, "Requires '#DOTA_Tooltip_Ability_"..requiredTalentName.."' At Level "..requiredTalentLevel)
                    return
                end
            end
        end

        -- Check if the player has enough points
        for k,v in pairs(self.playerTalents) do
            if k == accountID then
                local points = v.body.points
                if points < 1 then
                    DisplayError(id, "Not Enough Points.")
                    return
                end
                
                break
            end
        end

        -- Talent learning logic
        local modifierName = "modifier_"..talentName
        local talent = unit:FindModifierByName(modifierName)
        local talentLevel = 0
        local talentMaxLevel = 0

        if talent == nil then
            talent = unit:AddNewModifier(unit, nil, modifierName, {})

            if talent ~= nil then
                talent:SetStackCount(1)
                talentMaxLevel = lookup.max_level
                talentLevel = 1

                self:UpdateDatabaseRecord(unit, talentName, talentLevel)
                self:UpdateTalentPoints(unit, -1, false)
            end
        else
            talentLevel = talent:GetStackCount()
            talentMaxLevel = lookup.max_level

            local newLevel = talentLevel+1
            if newLevel <= talentMaxLevel then
                talentLevel = newLevel

                talent:SetStackCount(talentLevel)
                self:UpdateDatabaseRecord(unit, talentName, talentLevel)
                self:UpdateTalentPoints(unit, -1, false)
            else
                DisplayError(id, "Talent Is Max Level")
            end
        end

        CustomGameEventManager:Send_ServerToPlayer(player, "xp_manager_talent_learn_complete", {
            talent = talentName,
            attribute = event.attribute,
            talentNum = event.talentNum,
            level = talentLevel,
            maxLevel = talentMaxLevel,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    CustomGameEventManager:RegisterListener("xp_manager_fetch_levels", function(userId, event)
        if not IsInToolsMode() and (not IsDedicatedServer() or GameRules:IsCheatMode()) then return end
        if not _G.GlobalTalentsInitiated then return end

        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end
        

        local accountID = PlayerResource:GetSteamID(id)
        local talents = self.playerTalents[accountID]

        -- I don't know why we need a loop for this, but accessing the table with index does not work...
        for k,v in pairs(self.playerTalents) do
            if k == accountID then
                local xp = v.body.experience
                local points = v.body.points
                local playerLevel, XPNeededForNextLevel, XPForPrevLevel = self:GetLevel(xp)

                CustomGameEventManager:Send_ServerToPlayer(player, "xp_manager_fetch_levels_complete", {
                    level = playerLevel,
                    exp = xp,
                    nextLevelExp = XPNeededForNextLevel,
                    prevLevelExp = XPForPrevLevel,
                    points = points,
                    a = RandomFloat(1,1000),
                    b = RandomFloat(1,1000),
                    c = RandomFloat(1,1000),
                })

                break
            end
        end
    end)

    CustomGameEventManager:RegisterListener("xp_manager_talent_reset", function(userId, event)
        if not IsInToolsMode() and (not IsDedicatedServer() or GameRules:IsCheatMode()) then return end
        if not _G.GlobalTalentsInitiated then return end

        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local accountID = tostring(PlayerResource:GetSteamID(id))

        self.playerResetCooldownTimer[accountID] = self.playerResetCooldownTimer[accountID] or nil

        if self.playerResetCooldownTimer[accountID] == nil then
            self.playerResetCooldownTimer[accountID] = true
            self:ResetTalents(unit)
            
            -- 5m cooldown (remember to change panorama JS accordingly)
            Timers:CreateTimer(300, function()
                self.playerResetCooldownTimer[accountID] = nil
            end)
        else
            DisplayError(id, "Cannot Reset Talents Yet (Cooldown).")
            return
        end

        CustomGameEventManager:Send_ServerToPlayer(player, "xp_manager_reset_complete", {
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    _G.GlobalTalentsInitiated = true
end

function XpManager:OnPlayerSpawnedForTheFirstTime(player)
    if UnitIsNotMonkeyClone(player) and not player:IsIllusion() and player:IsRealHero() and not player:IsClone() and not player:IsTempestDouble() and not IsSummonTCOTRPG(player) then
        self:LoadPlayerTalentData(player)
    end
end

function XpManager:LoadTalentData()
    local req = CreateHTTPRequestScriptVM("GET", SERVER_URI.."/hamtatalents")

    req:Send(function(res)
        if not res.StatusCode == 201 then
            --print("Failed to send data to server for talents, error: " .. res.StatusCode)
            return
        end

        if res.StatusCode == 201 then
            --print("[Talents] Retrieved Talent Data")

            self.talents = res.Body

            CustomGameEventManager:Send_ServerToAllClients("xp_manager_fetch_talents_complete", {
                talents = self.talents,
                a = RandomFloat(1,1000),
                b = RandomFloat(1,1000),
                c = RandomFloat(1,1000),
            })

            -- Load player specific data 
            --[[
            local heroes = HeroList:GetAllHeroes()
            for _,hero in ipairs(heroes) do
                if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and not IsSummonTCOTRPG(hero) then
                    self:LoadPlayerTalentData(hero)
                end
            end
            --]]
        end
    end)
end

function XpManager:LoadPlayerTalentData(player)
    local accountID = PlayerResource:GetSteamID(player:GetPlayerID())
    local req = CreateHTTPRequestScriptVM("GET", SERVER_URI.."/hamtaspelartalents?steamid="..tostring(accountID))

    req:Send(function(res)
        if not res.StatusCode == 201 then
            --print("Failed to send data to server for talents, error: " .. res.StatusCode)
            return
        end

        if res.StatusCode == 201 then
            --print("[Talents] Retrieved Talent Data For Player: "..tostring(accountID))

            local sAccountID = tostring(accountID)
            self.playerTalents[accountID] = self.playerTalents[accountID] or {}
            self.playerTalents[accountID] = json.decode(res.Body)

            self.playerCanLearn[sAccountID] = self.playerCanLearn[sAccountID] or true
            self.playerCanLearn[sAccountID] = true

            local playerController = PlayerResource:GetPlayer(player:GetPlayerID())
            local primaryAttribute = player:GetPrimaryAttribute()
            local primaryAttribute_String = ""

            -- We have to do this since they are technically enums
            if primaryAttribute == DOTA_ATTRIBUTE_STRENGTH then
                primaryAttribute_String = "DOTA_ATTRIBUTE_STRENGTH"
            elseif primaryAttribute == DOTA_ATTRIBUTE_AGILITY then
                primaryAttribute_String = "DOTA_ATTRIBUTE_AGILITY"
            elseif primaryAttribute == DOTA_ATTRIBUTE_INTELLECT then
                primaryAttribute_String = "DOTA_ATTRIBUTE_INTELLECT"
            elseif primaryAttribute == DOTA_ATTRIBUTE_ALL then
                primaryAttribute_String = "DOTA_ATTRIBUTE_ALL"
            end

            -- We have to add the abilities to the player before we pass it onto Panorama
            local talents = self.playerTalents[accountID]
            if talents ~= nil then
                for _,obj in pairs(talents) do
                    if obj.talents ~= nil then
                        for _,talent in pairs(obj.talents) do
                            local name = talent.name
                            local level = talent.level 

                            local lookup = self:LookupTalent(name)
                            if lookup ~= nil and (lookup.attribute == primaryAttribute_String or lookup.attribute == "DOTA_ATTRIBUTE_ALL") then
                                local ability = player:FindModifierByName("modifier_"..name)
                                if not ability then
                                    ability = player:AddNewModifier(player, nil, "modifier_"..name, {})
                                end

                                if ability ~= nil then
                                    ability:SetStackCount(level)
                                end
                            end
                        end
                    end
                end
            end

            -- Add tracker
            player:AddNewModifier(player, nil, "modifier_xp_manager_player", {})

            CustomGameEventManager:Send_ServerToPlayer(playerController, "xp_manager_fetch_talents_complete", {
                talents = self.talents,
                personalTalents = self.playerTalents[accountID],
                attribute = primaryAttribute_String,
                a = RandomFloat(1,1000),
                b = RandomFloat(1,1000),
                c = RandomFloat(1,1000),
            })
        end
    end)
end

function XpManager:GetLevel(experience)
    local baseExperience = 100  -- Experience required for the first level
    local growthFactor = 1.15  -- Experience growth factor (20% increase per level)

    local level = math.floor(math.log((experience / baseExperience), growthFactor)) + 1
    local nextLevelExperience = math.floor(baseExperience * math.pow(growthFactor, level))
    local prevLevelExperience = math.floor(baseExperience * math.pow(growthFactor, level - 1))
    
    if level < 1 or experience < baseExperience then
        nextLevelExperience = baseExperience
        level = 0
        prevLevelExperience = 0
    end

    return level, nextLevelExperience, prevLevelExperience
end

function XpManager:UpdateDatabaseRecord(player, talent, level)
    if not IsInToolsMode() and (not IsDedicatedServer() or GameRules:IsCheatMode()) then return end
    
    local playerSteamID = tostring(PlayerResource:GetSteamID(player:GetPlayerID()))
    local serverData = {
        steamid = playerSteamID,
        talent = talent,
        level = level,
        server_key = GetDedicatedServerKeyV2(SERVER_KEY),
        date_key = SERVER_DATE_KEY
    }

    local req = CreateHTTPRequestScriptVM("POST", SERVER_URI.."/skapatalent")

    req:SetHTTPRequestRawPostBody("application/json", json.encode(serverData))

    req:Send(function(res)
        if not res.StatusCode == 201 then
            --print("[Talents] Failed to update record: " .. res.StatusCode)
            return
        end

        if res.StatusCode == 201 then
            --print("[Talents] Successfully updated talents for player ", playerSteamID)
        end
    end)
end

function XpManager:LookupTalent(name)
    local talents = json.decode(self.talents)

    for _,talent in pairs(talents.body) do
        if talent.name == name then
            return talent 
        end
    end
end

function XpManager:AddExperience(player, amount)
    if not IsInToolsMode() and (not IsDedicatedServer() or GameRules:IsCheatMode()) then return end
    if not _G.GlobalTalentsInitiated then return end

    local totalMultiplier = 1

    if (player:HasModifier("modifier_effect_scoreboard_first_easy") or player:HasModifier("modifier_effect_scoreboard_first_normal") or player:HasModifier("modifier_effect_scoreboard_first_hard")) then
        totalMultiplier = totalMultiplier + 0.05
    elseif player:HasModifier("modifier_effect_scoreboard_first_impossible") then
        totalMultiplier = totalMultiplier + 0.10
    elseif player:HasModifier("modifier_effect_scoreboard_first_hell") then
        totalMultiplier = totalMultiplier + 0.20
    elseif player:HasModifier("modifier_effect_scoreboard_first_hardcore") then
        totalMultiplier = totalMultiplier + 0.40
    end

    local difficulty = GetLevelFromDifficulty()

    if difficulty == 2 then
        totalMultiplier = totalMultiplier + DIFFICULTY_GPOINTS_MULTIPLIER_HARD
    elseif difficulty == 3 then
        totalMultiplier = totalMultiplier + DIFFICULTY_GPOINTS_MULTIPLIER_IMPOSSIBLE
    elseif difficulty == 4 then
        totalMultiplier = totalMultiplier + DIFFICULTY_GPOINTS_MULTIPLIER_HELL
    elseif difficulty == 5 then
        totalMultiplier = totalMultiplier + DIFFICULTY_GPOINTS_MULTIPLIER_HARDCORE
    end

    if player:IsDonator() then
        totalMultiplier = totalMultiplier + 1
    end

    amount = amount * totalMultiplier

    amount = math.floor(amount)

    --todo: when adding experience, make sure that if they reach the next level limit, its updated properly,
    --and they should get +1 point... but idk how to keep track of it
    local playerSteamID = tostring(PlayerResource:GetSteamID(player:GetPlayerID()))
    local serverData = {
        steamid = playerSteamID,
        amount = amount,
        server_key = GetDedicatedServerKeyV2(SERVER_KEY),
        date_key = SERVER_DATE_KEY
    }

    local req = CreateHTTPRequestScriptVM("POST", SERVER_URI.."/uppdateraexp")

    req:SetHTTPRequestRawPostBody("application/json", json.encode(serverData))

    req:Send(function(res)
        if not res.StatusCode == 201 then
            --print("[Talents] Failed to update record: " .. res.StatusCode)
            return
        end

        if res.StatusCode == 201 then
            --print("[Talents] Successfully updated experience for player ", playerSteamID)

            for k,v in pairs(self.playerTalents) do
                if tostring(k) == playerSteamID then
                    --[[local playerLevel, XPNeededForNextLevel = self:GetLevel(xp)

                    if (v.body.experience + amount) >= XPNeededForNextLevel then
                        local remainingXP = (v.body.experience + amount) - XPNeededForNextLevel
                    end--]]
                    local xp = v.body.experience
                    local points = v.body.points
                    local playerLevel, XPNeededForNextLevel, _ = self:GetLevel(xp)
                    
                    -- Use GetLevel to predict what level we would become with the added XP
                    local newLevel, _, XPForPrevLevel = self:GetLevel(xp + amount)
                    local levelsGained = newLevel - playerLevel

                    v.body.experience = v.body.experience + amount

                    self:UpdateTalentPoints(player, levelsGained, false) -- Hopefully this doesn't interfer since these methods kinda update the same thing at the same time

                    local playerController = PlayerResource:GetPlayer(player:GetPlayerID())
                    CustomGameEventManager:Send_ServerToPlayer(playerController, "xp_manager_fetch_levels_complete", {
                        level = playerLevel,
                        exp = v.body.experience,
                        nextLevelExp = XPNeededForNextLevel,
                        prevLevelExp = XPForPrevLevel,
                        points = points,
                        a = RandomFloat(1,1000),
                        b = RandomFloat(1,1000),
                        c = RandomFloat(1,1000),
                    })
                end
            end
        end
    end)
end

function XpManager:AddExperienceAllPlayers(amount)
    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsIllusion() and hero:IsRealHero() and not hero:IsClone() and not hero:IsTempestDouble() and not IsSummonTCOTRPG(hero) then
            local id = hero:GetPlayerID()
            local connState = PlayerResource:GetConnectionState(id)
            if connState == DOTA_CONNECTION_STATE_CONNECTED then
                self:AddExperience(hero, amount)
            end
        end
    end
end

-- @forceOverride is used to simply set the value of the points instead of add/subtract
function XpManager:UpdateTalentPoints(player, amount, forceOverride)
    if not IsInToolsMode() and (not IsDedicatedServer() or GameRules:IsCheatMode()) then return end
    if not _G.GlobalTalentsInitiated then return end

    local playerSteamID = tostring(PlayerResource:GetSteamID(player:GetPlayerID()))
    local serverData = {
        steamid = playerSteamID,
        amount = amount,
        forceOverride = forceOverride,
        server_key = GetDedicatedServerKeyV2(SERVER_KEY),
        date_key = SERVER_DATE_KEY
    }

    local req = CreateHTTPRequestScriptVM("POST", SERVER_URI.."/uppdaterapoang")

    req:SetHTTPRequestRawPostBody("application/json", json.encode(serverData))

    -- We have to change these here, otherwise players can end up with negative points if they spend them too fast
    -- This does mean however that if the request fails, it will deduct points from the player, but only visually, so if they reconnect it should be fine
    for k,v in pairs(self.playerTalents) do
        if tostring(k) == playerSteamID then
            if not forceOverride then
                v.body.points = v.body.points + amount
            else
                v.body.points = amount
            end
        end
    end

    req:Send(function(res)
        if not res.StatusCode == 201 then
            --print("[Talents] Failed to update record: " .. res.StatusCode)
            return
        end

        if res.StatusCode == 201 then
            --print("[Talents] Successfully updated points for player ", playerSteamID)
            
            for k,v in pairs(self.playerTalents) do
                if tostring(k) == playerSteamID then
                    local xp = v.body.experience
                    local points = v.body.points
                    local playerLevel, XPNeededForNextLevel, XPForPrevLevel = self:GetLevel(xp)

                    if forceOverride then
                        points = amount
                    end

                    local playerController = PlayerResource:GetPlayer(player:GetPlayerID())
                    CustomGameEventManager:Send_ServerToPlayer(playerController, "xp_manager_fetch_levels_complete", {
                        level = playerLevel,
                        exp = xp,
                        nextLevelExp = XPNeededForNextLevel,
                        prevLevelExp = XPForPrevLevel,
                        points = points,
                        a = RandomFloat(1,1000),
                        b = RandomFloat(1,1000),
                        c = RandomFloat(1,1000),
                    })
                end
            end
        end
    end)
end

function XpManager:ResetTalents(player)
    if not IsInToolsMode() and (not IsDedicatedServer() or GameRules:IsCheatMode()) then return end

    local playerSteamID = tostring(PlayerResource:GetSteamID(player:GetPlayerID()))

    self.playerCanLearn[playerSteamID] = self.playerCanLearn[playerSteamID] or false
    self.playerCanLearn[playerSteamID] = false

    -- Prepare request
    local serverData = {
        steamid = playerSteamID,
        server_key = GetDedicatedServerKeyV2(SERVER_KEY),
        date_key = SERVER_DATE_KEY
    }

    local req = CreateHTTPRequestScriptVM("POST", SERVER_URI.."/aterstalltalents")

    -- Remove their modifiers
    local mods = player:FindAllModifiers()
    for _,mod in ipairs(mods) do 
        if string.match(mod:GetName(), "modifier_xp_agility_talent") or string.match(mod:GetName(), "modifier_xp_strength_talent") or string.match(mod:GetName(), "modifier_xp_intellect_talent") or string.match(mod:GetName(), "modifier_xp_all_talent") then
            mod:Destroy()
        end
    end

    -- Refund Points
    for k,v in pairs(self.playerTalents) do
        if tostring(k) == playerSteamID then
            local xp = v.body.experience
            local points = v.body.points
            local playerLevel, XPNeededForNextLevel, XPForPrevLevel = self:GetLevel(xp)
            
            self:UpdateTalentPoints(player, playerLevel, true) -- Hopefully this doesn't interfer since these methods kinda update the same thing at the same time
        end
    end

    -- Send request

    req:SetHTTPRequestRawPostBody("application/json", json.encode(serverData))

    req:Send(function(res)
        if not res.StatusCode == 201 then
            --print("[Talents] Failed to update record: " .. res.StatusCode)
            return
        end

        if res.StatusCode == 201 then
            --print("[Talents] Successfully reset talents for player ", playerSteamID)
            self.playerCanLearn[playerSteamID] = true

            self:LoadPlayerTalentData(player)
        end
    end)
end

function XpManager:HeroSwapFix(player)
    local mods = player:FindAllModifiers()
    for _,mod in ipairs(mods) do 
        if string.match(mod:GetName(), "modifier_xp_agility_talent") or string.match(mod:GetName(), "modifier_xp_strength_talent") or string.match(mod:GetName(), "modifier_xp_intellect_talent") then
            mod:Destroy()
        end
    end

    self:LoadPlayerTalentData(player)
end
-------------
function modifier_xp_manager_player:DeclareFunctions()
    return {
        --MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_xp_manager_player:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    self.kills = 0

    --self:StartIntervalThink(5)
end

function modifier_xp_manager_player:OnIntervalThink()
    local parent = self:GetParent()

    local points = self.kills * 5

    XpManager:AddExperience(parent, points)

    self.kills = 0
end

function modifier_xp_manager_player:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker ~= parent then return end 

    local target = event.unit 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    self.kills = self.kills + 1
end