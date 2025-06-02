LinkLuaModifier("modifier_item_socket_rune_lesser_gold", "modifiers/runes/modifier_item_socket_rune_lesser_gold", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_lesser_gold = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_lesser_gold:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_GOLD_RATE_BOOST  
    }
end

function modifier_item_socket_rune_lesser_gold:GetModifierPercentageGoldRateBoost()
    return 2 * self:GetStackCount()
end