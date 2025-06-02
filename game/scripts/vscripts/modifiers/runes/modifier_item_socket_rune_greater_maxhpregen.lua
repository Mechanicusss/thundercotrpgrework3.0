LinkLuaModifier("modifier_item_socket_rune_greater_maxhpregen", "modifiers/runes/modifier_item_socket_rune_greater_maxhpregen", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_greater_maxhpregen = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_greater_maxhpregen:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE   
    }
end

function modifier_item_socket_rune_greater_maxhpregen:GetModifierHealthRegenPercentage()
    return 1.5 * self:GetStackCount()
end