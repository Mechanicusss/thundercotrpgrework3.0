LinkLuaModifier("modifier_xp_intellect_talent_18", "abilities/talents/intellect/xp_intellect_talent_18", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_18 = class(ItemBaseClass)
modifier_xp_intellect_talent_18 = class(xp_intellect_talent_18)
-------------
function xp_intellect_talent_18:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_18"
end
-------------
function modifier_xp_intellect_talent_18:OnCreated()
end

function modifier_xp_intellect_talent_18:OnDestroy()
end

function modifier_xp_intellect_talent_18:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE      
    }
end

function modifier_xp_intellect_talent_18:GetModifierMPRegenAmplify_Percentage()
    return 5 * self:GetStackCount()
end