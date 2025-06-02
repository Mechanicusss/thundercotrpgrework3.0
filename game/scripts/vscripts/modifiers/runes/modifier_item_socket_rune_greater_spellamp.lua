LinkLuaModifier("modifier_item_socket_rune_greater_spellamp", "modifiers/runes/modifier_item_socket_rune_greater_spellamp", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_greater_spellamp = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_greater_spellamp:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE  
    }
end

function modifier_item_socket_rune_greater_spellamp:GetModifierSpellAmplify_Percentage()
    return 7.5 * self:GetStackCount()
end