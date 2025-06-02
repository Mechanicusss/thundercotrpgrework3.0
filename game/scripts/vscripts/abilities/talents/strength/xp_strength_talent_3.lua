LinkLuaModifier("modifier_xp_strength_talent_3", "abilities/talents/strength/xp_strength_talent_3", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_strength_talent_3 = class(ItemBaseClass)
modifier_xp_strength_talent_3 = class(xp_strength_talent_3)
-------------
function xp_strength_talent_3:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_3"
end
-------------
function modifier_xp_strength_talent_3:OnCreated()
end

function modifier_xp_strength_talent_3:OnDestroy()
end

function modifier_xp_strength_talent_3:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING    
    }
end

function modifier_xp_strength_talent_3:GetModifierStatusResistanceStacking()
    return 1.5 * self:GetStackCount()
end