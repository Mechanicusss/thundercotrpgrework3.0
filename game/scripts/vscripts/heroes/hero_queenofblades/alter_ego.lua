function AlterEgo(keys)
	local caster = keys.caster
	local ability = keys.ability

	local unit = CreateUnitByName("npc_queenofblades_alter_ego", caster:GetAbsOrigin(), true, caster, nil, caster:GetTeamNumber())
	local damage = ability:GetAbilityValues("attack_damage")
	local hp = ability:GetAbilityValues("hp")
	if caster:HasScepter() then
		damage = ability:GetAbilityValues("attack_damage_scepter")
		hp = ability:GetAbilityValues("hp_scepter")
	end
	unit:AddNewModifier(caster, ability, "modifier_kill", {duration = ability:GetAbilityValues("duration")})
	ability:ApplyDataDrivenModifier(caster, unit, "modifier_queenofblades_alter_ego", nil)
	unit:SetControllableByPlayer(caster:GetPlayerID(), true)
	unit:SetOwner(caster)
	unit:SetBaseMaxHealth(hp)
	unit:SetMaxHealth(hp)
	unit:SetHealth(hp)
	unit:SetBaseDamageMin(damage)
	unit:SetBaseDamageMax(damage)
	unit:SetPhysicalArmorBaseValue(ability:GetAbilityValues("armor"))
	unit:SetBaseAttackTime(ability:GetAbilityValues("bat"))
	unit:SetBaseMoveSpeed(ability:GetAbilityValues("movespeed"))
	if ability:GetLevel() > 1 then
		unit:CreatureLevelUp(ability:GetLevel() - 1)
	end
	for i = 0, unit:GetAbilityCount() - 1 do
		local a = unit:GetAbilityByIndex(i)
		if a then
			if a:GetAbilityName() ~= "queenofblades_alter_ego_soul_breaker" or caster:HasScepter() then
				a:SetLevel(ability:GetLevel())
			else
				a:SetLevel(0)
			end
		end
	end
end

function SoulBreakerDeactivate(keys)
	keys.ability:SetActivated(false)
end
