LinkLuaModifier("modifier_xp_agility_talent_1", "abilities/talents/agility/xp_agility_talent_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_agility_talent_1 = class(ItemBaseClass)
modifier_xp_agility_talent_1 = class(xp_agility_talent_1)
-------------
function xp_agility_talent_1:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_1"
end
-------------
function modifier_xp_agility_talent_1:OnCreated()
end

function modifier_xp_agility_talent_1:OnDestroy()
end

function modifier_xp_agility_talent_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS   
    }
end

function modifier_xp_agility_talent_1:GetModifierAttackRangeBonus()
    if not self:GetParent():IsRangedAttacker() then
        return 10 * self:GetStackCount()
    end
end