TalentManager = TalentManager or class({})

function TalentManager:Init()
    _G.PlayerTalentList = {}

    CustomGameEventManager:RegisterListener("talent_manager_verify_valid_talent_on_hero", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        SendToConsole("dota_hud_healthbars 1")

        local data = self:LoadKVDataForHero(unit:GetUnitName())
        local exists = 0 

        if data ~= nil then
            exists = 1
        end

        CustomGameEventManager:Send_ServerToPlayer(player, "talent_manager_send_verify_talent_exists_for_hero", {
            exists = exists,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end)

    CustomGameEventManager:RegisterListener("talent_manager_send_error", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)
        local reason = event.reason

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        DisplayError(id, reason)
    end)

    CustomGameEventManager:RegisterListener("talent_manager_reset_talents", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        if not unit:HasModifier("modifier_spawn_healing_aura") then
            DisplayError(id, "Can Only Reset Talents In Spawn.")
            return
        end

        local isAbilitiesNotOnCooldown = true

        for i=0, unit:GetAbilityCount()-1 do
            local abil = unit:GetAbilityByIndex(i)
            if abil ~= nil then
                if abil:GetCooldownTimeRemaining() > 0 then
                    isAbilitiesNotOnCooldown = false
                    break
                end
            end
        end

        if not isAbilitiesNotOnCooldown then
            DisplayError(id, "Cannot Reset Talents With Active Cooldowns.")
            return
        end

        local unitName = unit:GetUnitName()

        self:ResetTalents(player, unit)
    end) 

    CustomGameEventManager:RegisterListener("talent_manager_get_current_selected_talent", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end
        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end
        local unitName = unit:GetUnitName()

        local data = _G.PlayerCurrentTalent[unitName]

        if data == nil then
            data = {}
        end

        local ability = unit:FindAbilityByName(data)
        local level = ability:GetLevel()

        CustomGameEventManager:Send_ServerToPlayer(player, "talent_manager_send_current_selected_talent", {
            talent = data,
            level = level,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end) 

    CustomGameEventManager:RegisterListener("talent_manager_get_talents", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end
        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end
        local unitName = unit:GetUnitName()

        if _G.PlayerTalentList[unitName] == nil then
            _G.PlayerTalentList[unitName] = self:LoadKVDataForHero(unitName)
        end

        local talents = self:GetKVDataForHero(unitName)
        CustomGameEventManager:Send_ServerToPlayer(player, "talent_manager_send_talents", {
            talents = talents,
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })
    end) 

    CustomGameEventManager:RegisterListener("talent_manager_learn_talent", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        local talentName = event.talent

        if not talentName or talentName == nil then return end

        -- Verify --
        local unitName = unit:GetUnitName()

        -- Is talent valid and pre-defined?
        if not self:IsValidTalent(_G.PlayerTalentList[unitName], talentName) then return end

        -- Does the player already have an active talent?
        -- If so, don't continue
        if self:HasAnyTalents(unit, _G.PlayerTalentList[unitName]) then return end

        -- Add --
        local ability = unit:FindAbilityByName(talentName)

        if not ability then
            ability = unit:AddAbility(talentName)
        end

        if ability then
            local level = ability:GetLevel()

            -- Store local variable for future use
            -- Useful for passing existing talent to panorama in case user re-connects
            _G.PlayerCurrentTalent[unitName] = ability:GetAbilityName()

            if level < 1 then
                ability:SetLevel(1)
                level = 1
                return
            end

            if level >= 1 and level < 3 then
                local levelToLearn = level+1
                if levelToLearn == 2 and unit:GetLevel() < MAX_LEVEL/2 then
                    DisplayError(id, "Requires Level " .. MAX_LEVEL/2)
                    return
                end

                if levelToLearn == 3 and unit:GetLevel() < MAX_LEVEL then
                    DisplayError(id, "Requires Level " .. MAX_LEVEL)
                    return
                end

                ability:SetLevel(levelToLearn)
            end
        end
    end)

    CustomGameEventManager:Send_ServerToAllClients("talent_manager_initation_complete", {
        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
    })
end

function TalentManager:ResetTalents(player, unit)
    local unitName = unit:GetUnitName()

    local talents = self:GetKVDataForHero(unitName)
    
    if talents == nil or self:LoadKVDataForHero(unitName) == nil then return end

    for _,talent in pairs(talents) do
        local ability = unit:FindAbilityByName(talent)
        if ability ~= nil then
            unit:RemoveAbilityByHandle(ability)
        end
    end

    _G.PlayerCurrentTalent[unitName] = nil

    CustomGameEventManager:Send_ServerToPlayer(player, "talent_manager_reset_talents_complete", {
        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
    })
end

function TalentManager:GetKVDataForHero(hero)
    if _G.PlayerTalentList[hero] == nil then return nil end

    local temp = {}

    for talent,_ in pairs(_G.PlayerTalentList[hero]) do
        table.insert(temp, talent)
    end

    return temp
end

function TalentManager:LoadKVDataForHero(hero)
    local kv = LoadKeyValues("scripts/npc/overrides/hero_talents/"..hero..".txt")
    return kv
end

function TalentManager:HasAnyTalents(caster, data)
    local exists = false 

    if not data then return false end

    for i=0, caster:GetAbilityCount()-1 do
        local abil = caster:GetAbilityByIndex(i)
        if abil ~= nil then
            for _,talentName in ipairs(data) do
                if talentName == abil:GetAbilityName() then
                    exists = true
                end
            end
        end
    end

    return exists
end

function TalentManager:IsValidTalent(data, talent)
    local pass = false

    if not data then return false end

    for talentName,talents in pairs(data) do
        if talentName == talent then
            pass = true
            break
        end
    end

    return pass
end