LinkLuaModifier("modifier_xp_intellect_talent_1", "abilities/talents/intellect/xp_intellect_talent_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_1 = class(ItemBaseClass)
modifier_xp_intellect_talent_1 = class(xp_intellect_talent_1)
-------------
function xp_intellect_talent_1:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_1"
end
-------------
function modifier_xp_intellect_talent_1:OnCreated()
end

function modifier_xp_intellect_talent_1:OnDestroy()
end

function modifier_xp_intellect_talent_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
end

function modifier_xp_intellect_talent_1:GetModifierSpellAmplify_Percentage()
    return 2 * self:GetStackCount()
end