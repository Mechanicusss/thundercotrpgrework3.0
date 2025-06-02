LinkLuaModifier("modifier_item_socket_rune_greater_gold", "modifiers/runes/modifier_item_socket_rune_greater_gold", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_greater_gold = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_greater_gold:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_GOLD_RATE_BOOST  
    }
end

function modifier_item_socket_rune_greater_gold:GetModifierPercentageGoldRateBoost()
    return 10 * self:GetStackCount()
end