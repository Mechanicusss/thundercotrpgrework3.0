LinkLuaModifier("modifier_item_socket_rune_lesser_armor", "modifiers/runes/modifier_item_socket_rune_lesser_armor", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_lesser_armor = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_lesser_armor:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS  
    }
end

function modifier_item_socket_rune_lesser_armor:GetModifierPhysicalArmorBonus()
    return 2 * self:GetStackCount()
end