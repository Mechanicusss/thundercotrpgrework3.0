LinkLuaModifier("modifier_xp_intellect_talent_2", "abilities/talents/intellect/xp_intellect_talent_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_2 = class(ItemBaseClass)
modifier_xp_intellect_talent_2 = class(xp_intellect_talent_2)
-------------
function xp_intellect_talent_2:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_2"
end
-------------
function modifier_xp_intellect_talent_2:OnCreated()
end

function modifier_xp_intellect_talent_2:OnDestroy()
end

function modifier_xp_intellect_talent_2:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_CAST_RANGE_BONUS  
    }
end

function modifier_xp_intellect_talent_2:GetModifierCastRangeBonus()
    return 100 * self:GetStackCount()
end