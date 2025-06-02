LinkLuaModifier("modifier_item_socket_rune_agility", "modifiers/runes/modifier_item_socket_rune_agility", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_agility = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_agility:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
    }
end

function modifier_item_socket_rune_agility:GetModifierBonusStats_Agility()
    return 30 * self:GetStackCount()
end