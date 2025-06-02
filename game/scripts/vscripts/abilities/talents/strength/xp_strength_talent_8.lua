LinkLuaModifier("modifier_xp_strength_talent_8", "abilities/talents/strength/xp_strength_talent_8", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_strength_talent_8 = class(ItemBaseClass)
modifier_xp_strength_talent_8 = class(xp_strength_talent_8)
-------------
function xp_strength_talent_8:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_8"
end
-------------
function modifier_xp_strength_talent_8:OnCreated()
end

function modifier_xp_strength_talent_8:OnDestroy()
end

function modifier_xp_strength_talent_8:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE    
    }
end

function modifier_xp_strength_talent_8:GetModifierExtraHealthPercentage()
    return 5
end

function modifier_xp_strength_talent_8:GetModifierDamageOutgoing_Percentage()
    return 14 * self:GetStackCount()
end