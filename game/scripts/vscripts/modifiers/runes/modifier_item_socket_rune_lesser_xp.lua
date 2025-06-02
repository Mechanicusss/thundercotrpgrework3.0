LinkLuaModifier("modifier_item_socket_rune_lesser_xp", "modifiers/runes/modifier_item_socket_rune_lesser_xp", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_lesser_xp = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_lesser_xp:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_EXP_RATE_BOOST,
    }

    return funcs
end

function modifier_item_socket_rune_lesser_xp:GetModifierPercentageExpRateBoost()
    return 2 * self:GetStackCount()
end