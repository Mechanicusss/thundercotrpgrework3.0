LinkLuaModifier("modifier_item_socket_rune_greater_damageamp", "modifiers/runes/modifier_item_socket_rune_greater_damageamp", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_greater_damageamp = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_greater_damageamp:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE   
    }
end

function modifier_item_socket_rune_greater_damageamp:GetModifierDamageOutgoing_Percentage()
    return 2.45 * self:GetStackCount()
end