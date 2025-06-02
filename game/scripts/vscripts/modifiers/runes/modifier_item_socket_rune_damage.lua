LinkLuaModifier("modifier_item_socket_rune_damage", "modifiers/runes/modifier_item_socket_rune_damage", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_damage = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_damage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE  
    }
end

function modifier_item_socket_rune_damage:GetModifierPreAttack_BonusDamage()
    return 75 * self:GetStackCount()
end