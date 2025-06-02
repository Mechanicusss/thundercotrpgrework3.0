function OnBuffDestroy(keys)
	
end

function ThinkPenalty(keys)
	
end

function IncreaseDamage(keys)
	local caster = keys.caster
	local target = keys.unit
	local ability = keys.ability
	local damage
	if IsCreepTCOTRPG(target) or IsBossTCOTRPG(target) then
		ModifyStacks(ability, caster, caster, "modifier_stegius_brightness_of_desolate_steal_buff", 1, false)
		damage = ability:GetSpecialValueFor("bonus_damage_from_creep")
	end

	ModifyStacks(ability, caster, caster, "modifier_stegius_brightness_of_desolate_damage", damage, true)

	Timers:CreateTimer(ability:GetSpecialValueFor("bonus_damage_duration"), function()
		if IsValidEntity(caster) then
			ModifyStacks(ability, caster, caster, "modifier_stegius_brightness_of_desolate_damage", -damage)
		end
	end)
end
