-- Created by Elfansoer
--[[
Ability checklist (erase if done/checked):
- Scepter Upgrade
- Break behavior
- Linken/Reflect behavior
- Spell Immune/Invulnerable/Invisible behavior
- Illusion behavior
- Stolen behavior
]]

--------------------------------------------------------------------------------
snapfire_scatterblast_custom = class({})
LinkLuaModifier( "modifier_snapfire_scatterblast_custom_intrin", "heroes/hero_snapfire/snapfire_scatterblast_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_snapfire_scatterblast_custom", "heroes/hero_snapfire/snapfire_scatterblast_custom", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_snapfire_scatterblast_custom_intrin = class(ItemBaseClass)
--------------------------------------------------------------------------------
-- Init Abilities
function snapfire_scatterblast_custom:GetIntrinsicModifierName()
    return "modifier_snapfire_scatterblast_custom_intrin"
end
----------------------------------------
function modifier_snapfire_scatterblast_custom_intrin:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_CANCELLED,
    }
end

function modifier_snapfire_scatterblast_custom_intrin:OnCreated()
    if not IsServer() then return end 

    self.attack = false
end

function modifier_snapfire_scatterblast_custom_intrin:OnAttackCancelled(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    self.attack = false
end

function modifier_snapfire_scatterblast_custom_intrin:OnAttackStart(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")
    if not RollPercentage(chance) then return end

    parent:StartGesture(ACT_DOTA_CAST_ABILITY_1)

    self.attack = true
    
end

function modifier_snapfire_scatterblast_custom_intrin:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    if not self.attack then return end

    local sound_cast = "Hero_Snapfire.Shotgun.Load"
	EmitSoundOn( sound_cast, self:GetCaster() )

    local caster = self:GetCaster()
	local point = target:GetAbsOrigin()
	local origin = caster:GetOrigin()

	-- load data
	local projectile_name = "particles/units/heroes/hero_snapfire/hero_snapfire_shotgun.vpcf"
	local projectile_distance = ability:GetCastRange( point, nil )
	local projectile_start_radius = ability:GetSpecialValueFor( "blast_width_initial" )/2
	local projectile_end_radius = ability:GetSpecialValueFor( "blast_width_end" )/2
	local projectile_speed = ability:GetSpecialValueFor( "blast_speed" )
	local projectile_direction = point-origin
	projectile_direction.z = 0
	projectile_direction = projectile_direction:Normalized()	

	-- create projectile
	local info = {
		Source = caster,
		Ability = ability,
		vSpawnOrigin = caster:GetAbsOrigin(),
		
	    bDeleteOnHit = false,
	    
	    iUnitTargetTeam = ability:GetAbilityTargetTeam(),
	    iUnitTargetFlags = ability:GetAbilityTargetFlags(),
	    iUnitTargetType = ability:GetAbilityTargetType(),
	    
	    EffectName = projectile_name,
	    fDistance = projectile_distance,
	    fStartRadius = projectile_start_radius,
	    fEndRadius =projectile_end_radius,
		vVelocity = projectile_direction * projectile_speed,
	
		bProvidesVision = false,
		ExtraData = {
			pos_x = origin.x,
			pos_y = origin.y,
		}
	}
	ProjectileManager:CreateLinearProjectile(info)

	-- play sound
	local sound_cast = "Hero_Snapfire.Shotgun.Fire"
	EmitSoundOn( sound_cast, caster )

    self.attack = false
end
--------------------------------------------------------------------------------
-- Ability Phase Start
--------------------------------------------------------------------------------
-- Projectile
function snapfire_scatterblast_custom:OnProjectileHit_ExtraData( target, location, extraData )
	if not target then return end

	-- load data
	local caster = self:GetCaster()
	local location = target:GetOrigin()
	local point_blank_range = self:GetSpecialValueFor( "point_blank_range" )
	local point_blank_mult = self:GetSpecialValueFor( "point_blank_dmg_bonus_pct" )/100
	local damage = self:GetSpecialValueFor( "damage" )
	local slow = self:GetSpecialValueFor( "debuff_duration" )

	-- check position
	local origin = Vector( extraData.pos_x, extraData.pos_y, 0 )
	local length = (location-origin):Length2D()

	-- manual check due to projectile's circle shape
	-- if length>self:GetCastRange( location, nil )+150 then return end

	local point_blank = (length<=point_blank_range)
	if point_blank then damage = damage + point_blank_mult*damage end

    damage = damage + (caster:GetAverageTrueAttackDamage(caster) * (self:GetSpecialValueFor("damage_from_attack")/100))

	-- damage
	local damageTable = {
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
		ability = self, --Optional.
	}
	ApplyDamage(damageTable)

	-- debuff
	target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_snapfire_scatterblast_custom", -- modifier name
		{ duration = slow } -- kv
	)

	-- effect
	self:PlayEffects( target, point_blank )
end

--------------------------------------------------------------------------------
function snapfire_scatterblast_custom:PlayEffects( target, point_blank )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_snapfire/hero_snapfire_shotgun_impact.vpcf"
	local particle_cast2 = "particles/units/heroes/hero_snapfire/hero_snapfire_shells_impact.vpcf"
	local particle_cast3 = "particles/units/heroes/hero_snapfire/hero_snapfire_shotgun_pointblank_impact_sparks.vpcf"
	local sound_target = "Hero_Snapfire.Shotgun.Target"

	-- Get Data

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	if point_blank then
		local effect_cast = ParticleManager:CreateParticle( particle_cast2, PATTACH_POINT_FOLLOW, target )
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			3,
			target,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(0,0,0), -- unknown
			true -- unknown, true
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )

		local effect_cast = ParticleManager:CreateParticle( particle_cast3, PATTACH_POINT_FOLLOW, target )
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			4,
			target,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(0,0,0), -- unknown
			true -- unknown, true
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end

	-- Create Sound
	EmitSoundOn( sound_target, target )
end

modifier_snapfire_scatterblast_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_snapfire_scatterblast_custom:IsHidden()
	return false
end

function modifier_snapfire_scatterblast_custom:IsDebuff()
	return true
end

function modifier_snapfire_scatterblast_custom:IsStunDebuff()
	return false
end

function modifier_snapfire_scatterblast_custom:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_snapfire_scatterblast_custom:OnCreated( kv )
	-- references
	self.slow = -self:GetAbility():GetSpecialValueFor( "movement_slow_pct" )
end

function modifier_snapfire_scatterblast_custom:OnRefresh( kv )
	-- references
	self.slow = -self:GetAbility():GetSpecialValueFor( "movement_slow_pct" )	
end

function modifier_snapfire_scatterblast_custom:OnRemoved()
end

function modifier_snapfire_scatterblast_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_snapfire_scatterblast_custom:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_snapfire_scatterblast_custom:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_snapfire_scatterblast_custom:GetEffectName()
	return "particles/units/heroes/hero_snapfire/hero_snapfire_shotgun_debuff.vpcf"
end

function modifier_snapfire_scatterblast_custom:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_snapfire_scatterblast_custom:GetStatusEffectName()
	return "particles/status_fx/status_effect_snapfire_slow.vpcf"
end

function modifier_snapfire_scatterblast_custom:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end