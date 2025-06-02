LinkLuaModifier("modifier_item_socket_rune_intellect", "modifiers/runes/modifier_item_socket_rune_intellect", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_intellect = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_intellect:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS 
    }
end

function modifier_item_socket_rune_intellect:GetModifierBonusStats_Intellect()
    return 30 * self:GetStackCount()
end