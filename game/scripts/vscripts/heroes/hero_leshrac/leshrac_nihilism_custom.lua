LinkLuaModifier("modifier_leshrac_nihilism_custom", "heroes/hero_leshrac/leshrac_nihilism_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

leshrac_nihilism_custom = class(ItemBaseClass)
modifier_leshrac_nihilism_custom = class(leshrac_nihilism_custom)
-------------
function leshrac_nihilism_custom:GetIntrinsicModifierName()
    return "modifier_leshrac_nihilism_custom"
end
