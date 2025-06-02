LinkLuaModifier("modifier_keymaster_combat_proficiency", "heroes/bosses/keymaster/keymaster_combat_proficiency", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

keymaster_combat_proficiency = class(ItemBaseClass)
modifier_keymaster_combat_proficiency = class(keymaster_combat_proficiency)
-------------
function keymaster_combat_proficiency:GetIntrinsicModifierName()
    return "modifier_keymaster_combat_proficiency"
end

function modifier_keymaster_combat_proficiency:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_keymaster_combat_proficiency:GetModifierTotalDamageOutgoing_Percentage(event)
    local target = event.target 

    if target:GetLevel() < self:GetParent():GetLevel() then
        local diff = self:GetParent():GetLevel() - target:GetLevel()
        return diff * self:GetAbility():GetSpecialValueFor("damage_increase")
    end
end

function modifier_keymaster_combat_proficiency:GetModifierIncomingDamage_Percentage(event)
    local attacker = event.attacker 

    if attacker:GetLevel() < self:GetParent():GetLevel() then
        local diff = self:GetParent():GetLevel() - attacker:GetLevel()
        return diff * self:GetAbility():GetSpecialValueFor("damage_reduction")
    end
end