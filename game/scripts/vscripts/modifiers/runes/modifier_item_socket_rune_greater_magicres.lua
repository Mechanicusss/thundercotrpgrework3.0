LinkLuaModifier("modifier_item_socket_rune_greater_magicres", "modifiers/runes/modifier_item_socket_rune_greater_magicres", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_greater_magicres = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_greater_magicres:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS  
    }
end

function modifier_item_socket_rune_greater_magicres:GetModifierMagicalResistanceBonus()
    return 10 * self:GetStackCount()
end