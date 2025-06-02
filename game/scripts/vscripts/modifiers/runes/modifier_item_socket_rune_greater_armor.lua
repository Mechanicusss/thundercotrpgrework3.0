LinkLuaModifier("modifier_item_socket_rune_greater_armor", "modifiers/runes/modifier_item_socket_rune_greater_armor", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_greater_armor = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_greater_armor:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS  
    }
end

function modifier_item_socket_rune_greater_armor:GetModifierPhysicalArmorBonus()
    return 50 * self:GetStackCount()
end