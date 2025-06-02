LinkLuaModifier("modifier_item_heart_transplant", "items/item_heart_transplant/item_heart_transplant", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_heart_transplant = class(ItemBaseClass)
modifier_item_heart_transplant = class(ItemBaseClass)
-------------
function item_heart_transplant:GetIntrinsicModifierName()
    return "modifier_item_heart_transplant"
end
---
function modifier_item_heart_transplant:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, --GetModifierTotalDamageOutgoing_Percentage
    }
    return funcs
end

function modifier_item_heart_transplant:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_heart_transplant:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_heart_transplant:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_max_hp_regen")
end

function modifier_item_heart_transplant:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_penalty")
end

