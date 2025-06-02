LinkLuaModifier("modifier_morphling_wave_custom", "heroes/hero_morphling/morphling_wave_custom/morphling_wave_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

morphling_wave_custom = class({})
modifier_morphling_wave_custom = class(ItemBaseClass)

function morphling_wave_custom:GetProjectileName()
	return "particles/units/heroes/hero_morphling/morphling_waveform.vpcf"
end

function morphling_wave_custom:GetIntrinsicModifierName()
    return "modifier_morphling_wave_custom"
end

function modifier_morphling_wave_custom:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK
	}
end

function modifier_morphling_wave_custom:OnAttack(event)
	if not IsServer() then return end

	local parent = self:GetParent()

	if event.attacker ~= parent then return end
	if parent:IsSilenced() then return end
	if not parent:HasModifier("modifier_item_aghanims_shard") then return end

	local ability = self:GetAbility()

	if not ability:IsCooldownReady() or parent:GetMana() < ability:GetManaCost(-1) then return end
	
	SpellCaster:Cast(ability, event.target, true)
end

function morphling_wave_custom:OnSpellStart()
	-- Radius
	local wave_radius = self:GetSpecialValueFor("wave_radius")
	-- Ability range
	local wave_range = self:GetSpecialValueFor("wave_range")
	-- Ability projectile speed
	local wave_speed = self:GetSpecialValueFor("wave_speed")
	--	Position
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local origin = caster:GetOrigin()
	-- projectile data
	local projectile_name = "particles/units/heroes/hero_morphling/morphling_waveform.vpcf"
	local projectile_radius = wave_radius
	local projectile_speed = wave_speed
	local projectile_distance = wave_range
	-- create projectile
	local info = {
		Ability = self,
        EffectName = projectile_name,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = wave_range,
        fStartRadius = 64,
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

function morphling_wave_custom:OnProjectileHit( target, location )
	if not target then return end
	-- Damage
	local wave_damage = self:GetSpecialValueFor("wave_damage")
	local wave_attributes_to_damage_pct = self:GetSpecialValueFor("wave_attributes_to_damage_pct")
	local wave_damage_agi = self:GetCaster():GetStrength() / 100 * wave_attributes_to_damage_pct
	local wave_damage_str = self:GetCaster():GetAgility() / 100 * wave_attributes_to_damage_pct
	local wave_damage_total = wave_damage + wave_damage_agi + wave_damage_str
	-- apply damage
	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = wave_damage_total,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self, --Optional.
	}
	ApplyDamage(damageTable)
end

function morphling_wave_custom:PlayEffects( origin, target )
	-- Get Resources
	local sound_cast = "Hero_Morphling.Waveform"

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
end