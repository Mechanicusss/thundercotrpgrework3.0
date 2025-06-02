LinkLuaModifier("modifier_xp_intellect_talent_10", "abilities/talents/intellect/xp_intellect_talent_10", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_10 = class(ItemBaseClass)
modifier_xp_intellect_talent_10 = class(xp_intellect_talent_10)
-------------
function xp_intellect_talent_10:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_10"
end
-------------
function modifier_xp_intellect_talent_10:OnCreated()
end

function modifier_xp_intellect_talent_10:OnDestroy()
end

function modifier_xp_intellect_talent_10:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE   
    }
end

function modifier_xp_intellect_talent_10:GetModifierSpellAmplify_Percentage()
    local parent = self:GetParent()
    local intellect = parent:GetBaseIntellect()

    local amp = 0.01 * (intellect * self:GetStackCount())
    if amp > 50 then
        amp = 50
    end

    return amp
end