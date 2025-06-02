LinkLuaModifier("modifier_morphling_adaptive_strike_custom", "heroes/hero_morphling/morphling_adaptive_strike_custom/morphling_adaptive_strike_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_morphling_adaptive_strike_custom = class(ItemBaseClass)
--modifier_item_aghanims_shard
morphling_adaptive_strike_custom = class({})

function modifier_morphling_adaptive_strike_custom:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_morphling_adaptive_strike_custom:OnAttackLanded(event)
	if not IsServer() then return end

	local parent = self:GetParent()

	if event.attacker ~= parent then return end
	if parent:IsSilenced() then return end
	if not parent:HasModifier("modifier_item_aghanims_shard") then return end

	local ability = self:GetAbility()

	if not ability:IsCooldownReady() or parent:GetMana() < ability:GetManaCost(-1) then return end
	
	SpellCaster:Cast(ability, event.target, true)
end

function morphling_adaptive_strike_custom:GetIntrinsicModifierName()
    return "modifier_morphling_adaptive_strike_custom"
end

function morphling_adaptive_strike_custom:GetProjectileName()
	return "particles/units/heroes/hero_morphling/morphling_waveform.vpcf"
end

function morphling_adaptive_strike_custom:OnSpellStart()
	-- Radius
	local adaptive_strike_radius = self:GetSpecialValueFor("adaptive_strike_radius")
	-- Ability range
	local adaptive_strike_range = self:GetSpecialValueFor("adaptive_strike_range")
	-- Ability projectile speed
	local adaptive_strike_speed = self:GetSpecialValueFor("adaptive_strike_speed")
	--	Position
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local origin = caster:GetOrigin()
	-- projectile data
	local projectile_name = "particles/units/heroes/hero_morphling/morphling_adaptive_strike_agi.vpcf"
	local projectile_radius = adaptive_strike_radius
	local projectile_speed = adaptive_strike_speed
	local projectile_distance = adaptive_strike_range
	-- create projectile
	local info = {
		Ability = self,
        EffectName = projectile_name,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = projectile_distance,
        fStartRadius = point,
        fEndRadius = projectile_radius,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		bDeleteOnHit = true,
		vVelocity = caster:GetForwardVector() * projectile_speed,
		bProvidesVision = true,
		iVisionRadius = projectile_radius,
		iVisionTeamNumber = caster:GetTeamNumber()
	}
	ProjectileManager:CreateLinearProjectile(info)
	self:PlayEffects( origin, point )
end

function morphling_adaptive_strike_custom:OnProjectileHit( target, location )
	if not target then return end
	-- Damage
	local adaptive_strike_damage = self:GetSpecialValueFor("adaptive_strike_damage")
	local adaptive_strike_attributes_to_damage_pct = self:GetSpecialValueFor("adaptive_strike_attributes_to_damage_pct")
	local adaptive_strike_damage_agi = self:GetCaster():GetStrength() / 100 * adaptive_strike_attributes_to_damage_pct
	local adaptive_strike_damage_str = self:GetCaster():GetAgility() / 100 * adaptive_strike_attributes_to_damage_pct
	local adaptive_strike_damage_total = adaptive_strike_damage + adaptive_strike_damage_agi + adaptive_strike_damage_str
	-- apply damage
	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = adaptive_strike_damage_total,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self, --Optional.
	}
	ApplyDamage(damageTable)
end

--------------------------------------------------------------------------------
function morphling_adaptive_strike_custom:PlayEffects( origin, target )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_morphling/morphling_adaptive_strike.vpcf"
	local sound_cast = "Hero_Morphling.AdaptiveStrike"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, origin )
	ParticleManager:SetParticleControl( effect_cast, 1, target )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
end