LinkLuaModifier("modifier_xp_strength_talent_14", "abilities/talents/strength/xp_strength_talent_14", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_strength_talent_14 = class(ItemBaseClass)
modifier_xp_strength_talent_14 = class(xp_strength_talent_14)
-------------
function xp_strength_talent_14:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_14"
end
-------------
function modifier_xp_strength_talent_14:OnCreated()
end

function modifier_xp_strength_talent_14:OnDestroy()
end

function modifier_xp_strength_talent_14:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }
end

function modifier_xp_strength_talent_14:GetModifierPreAttack_BonusDamage()
    return self:GetParent():GetMaxHealth() * ((1/100) * self:GetStackCount())
end