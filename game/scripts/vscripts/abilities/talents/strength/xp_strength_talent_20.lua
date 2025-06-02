LinkLuaModifier("modifier_xp_strength_talent_20", "abilities/talents/strength/xp_strength_talent_20", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_strength_talent_20 = class(ItemBaseClass)
modifier_xp_strength_talent_20 = class(xp_strength_talent_20)
-------------
function xp_strength_talent_20:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_20"
end
-------------
function modifier_xp_strength_talent_20:OnCreated()
end

function modifier_xp_strength_talent_20:OnDestroy()
end

function modifier_xp_strength_talent_20:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS  
    }
end

function modifier_xp_strength_talent_20:GetModifierBonusStats_Strength()
    return 0.1 * self:GetParent():GetLevel() * self:GetStackCount()
end