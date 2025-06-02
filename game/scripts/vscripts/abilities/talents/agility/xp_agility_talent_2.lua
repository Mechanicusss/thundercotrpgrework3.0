LinkLuaModifier("modifier_xp_agility_talent_2", "abilities/talents/agility/xp_agility_talent_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_agility_talent_2 = class(ItemBaseClass)
modifier_xp_agility_talent_2 = class(xp_agility_talent_2)
-------------
function xp_agility_talent_2:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_2"
end
-------------
function modifier_xp_agility_talent_2:OnCreated()
end

function modifier_xp_agility_talent_2:OnDestroy()
end

function modifier_xp_agility_talent_2:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS, --GetModifierProjectileSpeedBonus   
    }
end

function modifier_xp_agility_talent_2:GetModifierProjectileSpeedBonus()
    if self:GetParent():IsRangedAttacker() then
        return 5 * self:GetStackCount()
    end
end