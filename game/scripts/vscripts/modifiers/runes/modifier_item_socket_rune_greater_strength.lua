LinkLuaModifier("modifier_item_socket_rune_greater_strength", "modifiers/runes/modifier_item_socket_rune_greater_strength", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_greater_strength = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_greater_strength:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS 
    }
end

function modifier_item_socket_rune_greater_strength:GetModifierBonusStats_Strength()
    return 300 * self:GetStackCount()
end