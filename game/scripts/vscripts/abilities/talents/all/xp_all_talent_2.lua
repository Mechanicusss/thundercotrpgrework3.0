LinkLuaModifier("modifier_xp_all_talent_2", "abilities/talents/all/xp_all_talent_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_all_talent_2 = class(ItemBaseClass)
modifier_xp_all_talent_2 = class(xp_all_talent_2)
-------------
function xp_all_talent_2:GetIntrinsicModifierName()
    return "modifier_xp_all_talent_2"
end
-------------
function modifier_xp_all_talent_2:OnCreated()
end

function modifier_xp_all_talent_2:OnDestroy()
end

function modifier_xp_all_talent_2:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_GOLD_RATE_BOOST     
    }
end

function modifier_xp_all_talent_2:GetModifierPercentageGoldRateBoost()
    return 1 * self:GetStackCount()
end