LinkLuaModifier("modifier_stargazer_gamma_ray_unit", "heroes/hero_stargazer/gamma_ray.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stargazer_gamma_ray_debuff", "heroes/hero_stargazer/gamma_ray.lua", LUA_MODIFIER_MOTION_NONE)

modifier_stargazer_gamma_ray_unit = class({})
modifier_stargazer_gamma_ray_debuff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

function OnSpellStart(keys)
	local caster = keys.caster
	local ability = keys.ability
end

function OnAttack(keys)
	if not IsServer() then return end

	local caster = keys.caster
    local ability = keys.ability
    local target = keys.target

    if not caster:HasModifier("modifier_gamma_ray_passive") then return end

    if RollPercentage(ability:GetSpecialValueFor("chance")) and ability:IsCooldownReady() then
    	local point = target:GetAbsOrigin()
    	local level = ability:GetLevel() - 1

	    local radius = math.min(ability:GetLevelSpecialValueFor("base_radius", level) + (caster:GetBaseIntellect() * (ability:GetLevelSpecialValueFor("int_to_radius_pct", level) * 0.01)), ability:GetAbilityValues("max_radius"))
	
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		
		for _, enemy in ipairs(enemies) do
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				damage = (ability:GetLevelSpecialValueFor("base_damage", level) + caster:GetBaseIntellect()) + (caster:GetBaseIntellect() * (ability:GetLevelSpecialValueFor("int_to_dmg_pct", level) * 0.01)),
				damage_type = ability:GetAbilityDamageType(),
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
				ability = ability
			})
			enemy:AddNewModifier(caster, ability, "modifier_stargazer_gamma_ray_debuff", {
				duration = ability:GetSpecialValueFor("duration")
			})
		end
		
		CreateUnitByNameAsync("npc_dummy_unit", point, false, nil, nil, caster:GetTeamNumber(), function(dummy)
			dummy:AddNewModifier(dummy, nil, "modifier_stargazer_gamma_ray_unit", {
				duration = 0.5
			})
			dummy:EmitSound("Arena.Hero_Stargazer.GammaRay.Cast")
			local particle = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_stargazer/gamma_ray_immortal1.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy, caster)
			ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
		end)
	end
end

function modifier_stargazer_gamma_ray_unit:CheckState()
	return {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
	}
end

function modifier_stargazer_gamma_ray_unit:OnRemoved()
	 if not IsServer() then return end

	 self:GetParent():ForceKill(false)
end

function modifier_stargazer_gamma_ray_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
	}
end

function modifier_stargazer_gamma_ray_debuff:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("magic_res")
end