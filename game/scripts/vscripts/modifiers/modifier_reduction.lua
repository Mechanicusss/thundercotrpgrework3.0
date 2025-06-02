modifier_magic_resist_reduction = class(ModifierBaseClass)

function modifier_magic_resist_reduction:IsHidden()
	return true
end

function modifier_magic_resist_reduction:IsPurgable()
	return true
end

function modifier_magic_resist_reduction:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE,
	}
	return funcs
end

function modifier_magic_resist_reduction:GetModifierMagicalResistance()
	return -self:GetAbility():GetLevelSpecialValueFor("magic_resist_reduction_pct", self:GetAbility():GetLevel() - 1)
end