LinkLuaModifier("modifier_critical_strikes_custom", "modifiers/modifier_critical_strikes_custom.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_critical_strikes_custom = class(BaseClass)
---------------------------------------------------
function modifier_critical_strikes_custom:OnCreated()
    if not IsServer() then return end 

    self.critSources = {}
    self.defaultCritChance = 0
    self.defaultCritDamage = 50
end

function modifier_critical_strikes_custom:GetTotalCrit()
    local chance = self.defaultCritChance
    local damage = self.defaultCritDamage

    for ability,critData in pairs(self.critSources) do 
        chance = chance + (critData["critChance"] or 0)
        damage = damage + (critData["critDamage"] or 0)
    end

    return chance,damage
end

function modifier_critical_strikes_custom:GetTotalCritAbility(ability)
    local name = ability:GetAbilityName()
    
    local chance = self.critSources[name]["critChance"] or 0
    local damage = self.critSources[name]["critDamage"] or 0

    return chance,damage
end

function modifier_critical_strikes_custom:OnCriticalStrikeCustom(event)
    if not IsServer() then return end 

    local inflictor = event.inflictor

    -- If there is no inflictor it means it was triggered by a basic attack
    if not inflictor then 
    
    else
        -- Triggered by an ability/item source
        
    end
end
