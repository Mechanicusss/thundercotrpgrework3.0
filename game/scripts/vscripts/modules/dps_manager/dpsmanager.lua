LinkLuaModifier("modifier_dps_manager_player", "modules/dps_manager/DpsManager.lua", LUA_MODIFIER_MOTION_NONE)

DpsManager = DpsManager or class({})

local BaseClassPlayer = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_dps_manager_player = class(BaseClassPlayer)

function DpsManager:Init()
    self.StoredPlayerDamage = {}
    self.StoredPlayerDPS = {}

    CustomGameEventManager:RegisterListener("dps_manager_reset", function(userId, event)
        local id = event.PlayerID
        local player = PlayerResource:GetPlayer(id)

        if not player or player == nil or player:IsNull() then return end

        local hero = player:GetAssignedHero()

        local unit = EntIndexToHScript(event.unit)

        if not unit or unit == nil or unit:IsNull() then return end

        if event.heroName ~= hero:GetUnitName() then
            DisplayError(id, "Invalid Action.")
            return
        end

        local accountID = PlayerResource:GetSteamAccountID(id)
        accountID = tostring(accountID)

        self:Reset(accountID)
    end)

    Timers:CreateTimer(1.0, function()
        CustomGameEventManager:Send_ServerToAllClients("dps_manager_update", {
            storedDamage = self.StoredPlayerDamage,
            storedDPS = self.StoredPlayerDPS,
    
            a = RandomFloat(1,1000),
            b = RandomFloat(1,1000),
            c = RandomFloat(1,1000),
        })

        return 1.0
    end)
end

function DpsManager:Reset(steamID)
    self.StoredPlayerDamage[steamID] = nil
    self.StoredPlayerDPS[steamID] = nil

    CustomGameEventManager:Send_ServerToAllClients("dps_manager_reset_complete", {
        storedDamage = self.StoredPlayerDamage,
        storedDPS = self.StoredPlayerDPS,

        a = RandomFloat(1,1000),
        b = RandomFloat(1,1000),
        c = RandomFloat(1,1000),
    })
end

function DpsManager:OnPlayerSpawnedForTheFirstTime(player)
    player:AddNewModifier(player, nil, "modifier_dps_manager_player", {})
end
--------------
function modifier_dps_manager_player:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())
    self.accountID = tostring(self.accountID)

    DpsManager.StoredPlayerDamage[self.accountID] = DpsManager.StoredPlayerDamage[self.accountID] or {}

    self:StartIntervalThink(1)
end

function modifier_dps_manager_player:OnIntervalThink()
    DpsManager.StoredPlayerDPS[self.accountID] = DpsManager.StoredPlayerDPS[self.accountID] or 0
    DpsManager.StoredPlayerDPS[self.accountID] = 0
end

function modifier_dps_manager_player:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }
end

function modifier_dps_manager_player:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()
    local attacker = parent
    local inflictor = event.inflictor 
    local damageType = event.damage_type

    if parent == event.unit then return end -- If the player is the victim

    if parent ~= event.attacker then -- If the player is not the attacker
        if IsSummonTCOTRPG(event.attacker) then -- Check if the attacker is a summoned unit
            local owner = event.attacker:GetOwner()
            if not owner then
                return
            else
                if owner ~= parent then
                    return
                else
                    attacker = owner -- Assign the attacker to be the owner instead of the summoned unit
                    local assignedAbility = event.attacker.assignedAbility
                    if assignedAbility ~= nil then
                        inflictor = assignedAbility
                        --damageType = DAMAGE_TYPE_PHYSICAL
                    end
                end
            end
        else
            return
        end
    end

    if not IsCreepTCOTRPG(event.unit) and not IsBossTCOTRPG(event.unit) then return end

    local damageCategory = event.damage_category
    local damageFlags = event.damage_flags
    local inflictorName = "other" -- Default. If there is no source it will be displayed as this.

    -- If it's an attack
    if damageCategory == DOTA_DAMAGE_CATEGORY_ATTACK then
        inflictorName = "attack"
    end

    -- If it's from an ability
    if inflictor ~= nil then
        inflictorName = inflictor:GetAbilityName()
        inflictorName = inflictorName:match("^(.-)_?%d*$") -- Removes the level of the item from the name (e.g. item_name2, item_name_2, becomes item_name)
    end

    -- Override inflictor if custom damage flag is present
    if bit.band(damageFlags, 9991) == 9991 then
        inflictorName = "xp_intellect_talent_13"
    end 
    
    if bit.band(damageFlags, 9992) == 9992 then
        inflictorName = "xp_intellect_talent_7"
    end 
    
    if bit.band(damageFlags, 9993) == 9993 then
        inflictorName = "xp_strength_talent_17"
    end 
    
    if bit.band(damageFlags, 9994) == 9994 then
        inflictorName = "xp_agility_talent_5"
    end 
    
    if bit.band(damageFlags, 9995) == 9995 then
        inflictorName = "xp_agility_talent_10"
    end 
    
    if bit.band(damageFlags, 9996) == 9996 then
        inflictorName = "item_ability_gem_proc_lightning"
    end

    if bit.band(damageFlags, 9997) == 9997 then
        inflictorName = "item_ability_gem_mind_flare"
    end

    DpsManager.StoredPlayerDamage[self.accountID] = DpsManager.StoredPlayerDamage[self.accountID] or {}
    DpsManager.StoredPlayerDamage[self.accountID][inflictorName] = DpsManager.StoredPlayerDamage[self.accountID][inflictorName] or {}

    if DpsManager.StoredPlayerDamage[self.accountID][inflictorName] ~= nil then
        DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType] = DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType] or {}

        if DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType] ~= nil then
            DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType]["damage"] = DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType]["damage"] or 0
            DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType]["hero"] = DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType]["hero"] or 0
            DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType]["playerIndex"] = DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType]["playerIndex"] or 0

            DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType]["damage"] = DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType]["damage"] + event.damage
            DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType]["hero"] = attacker:GetUnitName()
            DpsManager.StoredPlayerDamage[self.accountID][inflictorName][damageType]["playerIndex"] = attacker:entindex()

            DpsManager.StoredPlayerDPS[self.accountID] = DpsManager.StoredPlayerDPS[self.accountID] or 0
            DpsManager.StoredPlayerDPS[self.accountID] = DpsManager.StoredPlayerDPS[self.accountID] + event.damage
        end
    end
end

--damagestored[cat]["ability_fire_storm"][physical]["damage"] = 12345
--damagestored[cat]["ability_fire_storm"][magical]["damage"] = 12345
--damagestored[cat]["ability_fire_storm"][pure]["damage"] = 12345