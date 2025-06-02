LinkLuaModifier("modifier_xp_intellect_talent_15", "abilities/talents/intellect/xp_intellect_talent_15", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_15 = class(ItemBaseClass)
modifier_xp_intellect_talent_15 = class(xp_intellect_talent_15)
-------------
function xp_intellect_talent_15:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_15"
end
-------------
function modifier_xp_intellect_talent_15:OnCreated()
end

function modifier_xp_intellect_talent_15:OnDestroy()
end

function modifier_xp_intellect_talent_15:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_MANA_PERCENTAGE     
    }
end

function modifier_xp_intellect_talent_15:GetModifierExtraManaPercentage()
    return 2.5 * self:GetStackCount()
end