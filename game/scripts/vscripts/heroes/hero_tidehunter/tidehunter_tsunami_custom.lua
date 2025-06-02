LinkLuaModifier("modifier_tidehunter_tsunami_custom", "heroes/hero_tidehunter/tidehunter_tsunami_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

tidehunter_tsunami_custom = class(ItemBaseClass)
modifier_tidehunter_tsunami_custom = class(tidehunter_tsunami_custom)
-------------
function tidehunter_tsunami_custom:GetIntrinsicModifierName()
    return "modifier_tidehunter_tsunami_custom"
end
-------------
function modifier_tidehunter_tsunami_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MODEL_SCALE 
	}
end

function modifier_tidehunter_tsunami_custom:GetModifierExtraHealthPercentage()
	return self:GetAbility():GetSpecialValueFor("bonus_health_pct")
end

function modifier_tidehunter_tsunami_custom:GetModifierModelScale()
	return 10
end

function modifier_tidehunter_tsunami_custom:GetModifierPreAttack_BonusDamage()
	local hpMultiplier = self:GetAbility():GetSpecialValueFor("damage_from_hp_pct")/100
	local damage = self:GetParent():GetMaxHealth() * hpMultiplier

	return damage
end