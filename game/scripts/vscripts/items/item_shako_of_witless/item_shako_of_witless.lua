LinkLuaModifier("modifier_item_shako_of_witless", "items/item_shako_of_witless/item_shako_of_witless", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_shako_of_witless = class(ItemBaseClass)
modifier_item_shako_of_witless = class(item_shako_of_witless)
-------------
function item_shako_of_witless:GetIntrinsicModifierName()
    return "modifier_item_shako_of_witless"
end

function modifier_item_shako_of_witless:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
        MODIFIER_PROPERTY_EXTRA_MANA_PERCENTAGE 
    }
end

function modifier_item_shako_of_witless:GetModifierExtraHealthPercentage()
    return self:GetAbility():GetSpecialValueFor("extra_health_pct")
end

function modifier_item_shako_of_witless:GetModifierExtraManaPercentage()
    return self:GetAbility():GetSpecialValueFor("mana_penalty_pct")
end
