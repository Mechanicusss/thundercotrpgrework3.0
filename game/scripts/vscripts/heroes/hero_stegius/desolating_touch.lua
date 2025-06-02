function ReduceArmor(keys)
	if not IsServer() then return end

	local caster = keys.caster
	local unit = keys.target
	local ability = keys.ability
	local stacks = ability:GetSpecialValueFor("armor_per_hit")

	if IsBossTCOTRPG(unit) then
		stacks = math.min(stacks, ability:GetSpecialValueFor("boss_max_armor") - unit:GetModifierStackCount("modifier_stegius_desolating_touch_debuff", ability))
	end

	local mod = ability:ApplyDataDrivenModifier(caster, unit, "modifier_stegius_desolating_touch_debuff", {
		duration = ability:GetSpecialValueFor("duration")
	})
	
	mod:SetStackCount(mod:GetStackCount() + stacks)
	mod:ForceRefresh()
end
