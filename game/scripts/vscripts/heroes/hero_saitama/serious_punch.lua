LinkLuaModifier("modifier_saitama_limiter", "heroes/hero_saitama/modifier_saitama_limiter.lua", LUA_MODIFIER_MOTION_NONE)

saitama_serious_punch = class({})

if IsServer() then
	function saitama_serious_punch:OnSpellStart()
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		if not target:TriggerSpellAbsorb(self) then
			target:TriggerSpellReflect(self)
			local damage = caster:GetAverageTrueAttackDamage(target) * (self:GetSpecialValueFor("base_damage_multiplier_pct") + self:GetSpecialValueFor("damage_multiplier_per_stack_pct") * caster:GetModifierStackCount("modifier_saitama_limiter", caster)) * 0.01

			target:EmitSound("Hero_Earthshaker.EchoSlam")
			ParticleManager:CreateParticle("particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_start_fallback_mid_egset.vpcf", PATTACH_ABSORIGIN, target)

			ApplyDamage({
				attacker = caster,
				victim = target,
				damage = damage,
				damage_type = self:GetAbilityDamageType(),
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
				ability = self
			})
		end
	end
end
