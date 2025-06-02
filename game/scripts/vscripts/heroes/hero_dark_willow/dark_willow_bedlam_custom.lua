dark_willow_bedlam_custom = class({})
LinkLuaModifier( "modifier_wisp_ambient", "heroes/hero_dark_willow/modifier_wisp_ambient.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dark_willow_bedlam_custom", "heroes/hero_dark_willow/dark_willow_bedlam_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dark_willow_bedlam_custom_attack", "heroes/hero_dark_willow/dark_willow_bedlam_custom.lua", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_dark_willow_bedlam_custom = class(ItemBaseClassBuff)

--------------------------------------------------------------------------------
-- Ability Start
function dark_willow_bedlam_custom:OnToggle()
	-- unit identifier
	local caster = self:GetCaster()

    if self:GetToggleState() then
        -- add buff
        caster:AddNewModifier(
            caster, -- player source
            self, -- ability source
            "modifier_dark_willow_bedlam_custom", -- modifier name
            {} -- kv
        )
    else
        caster:RemoveModifierByName("modifier_dark_willow_bedlam_custom")
    end
end
--------------------------------------------------------------------------------
-- Projectile
function dark_willow_bedlam_custom:OnProjectileHit_ExtraData( target, location, ExtraData )
	-- destroy effect projectile
	local effect_cast = ExtraData.effect
	ParticleManager:DestroyParticle( effect_cast, false )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	if not target then return end

	-- damage
	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = ExtraData.damage,
		damage_type = self:GetAbilityDamageType(),
		ability = self, --Optional.
	}
	ApplyDamage(damageTable)

    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        self:GetCaster():PerformAttack(target, true, true, true, false, false, true, true)
    end
end

--------------------------------------------------------------------------------
-- Classifications
function modifier_dark_willow_bedlam_custom:IsHidden()
	return false
end

function modifier_dark_willow_bedlam_custom:IsDebuff()
	return false
end

function modifier_dark_willow_bedlam_custom:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_dark_willow_bedlam_custom:OnCreated( kv )
	self.parent = self:GetParent()
	self.zero = Vector(0,0,0)

	-- references
	self.revolution = self:GetAbility():GetSpecialValueFor( "roaming_seconds_per_rotation" )
	self.rotate_radius = self:GetAbility():GetSpecialValueFor( "roaming_radius" )

	if not IsServer() then return end

	-- init data
	self.interval = 0.03
	self.base_facing = Vector(0,1,0)
	self.relative_pos = Vector( -self.rotate_radius, 0, 100 )
	self.rotate_delta = 360/self.revolution * self.interval

	-- set init location
	self.position = self.parent:GetOrigin() + self.relative_pos
	self.rotation = 0
	self.facing = self.base_facing

	-- create wisp
	self.wisp = CreateUnitByName(
		"npc_dota_dark_willow_creature",
		self.position,
		true,
		self.parent,
		self.parent:GetOwner(),
		self.parent:GetTeamNumber()
	)
	self.wisp:SetForwardVector( self.facing )
	self.wisp:AddNewModifier(
		self:GetCaster(), -- player source
		self:GetAbility(), -- ability source
		"modifier_wisp_ambient", -- modifier name
		{} -- kv
	)

	-- add attack modifier
	self.wisp:AddNewModifier(
		self:GetCaster(), -- player source
		self:GetAbility(), -- ability source
		"modifier_dark_willow_bedlam_custom_attack", -- modifier name
		{ duration = kv.duration } -- kv
	)

	-- Start interval
	self:StartIntervalThink( self.interval )

	-- play effects
	self:PlayEffects()
end

function modifier_dark_willow_bedlam_custom:OnRefresh( kv )
	-- refresh references
	self.revolution = self:GetAbility():GetSpecialValueFor( "roaming_seconds_per_rotation" )
	self.rotate_radius = self:GetAbility():GetSpecialValueFor( "roaming_radius" )

	if not IsServer() then return end

	self.relative_pos = Vector( -self.rotate_radius, 0, 100 )
	self.rotate_delta = 360/self.revolution * self.interval

	-- refresh attack modifier
	self.wisp:AddNewModifier(
		self:GetCaster(), -- player source
		self:GetAbility(), -- ability source
		"modifier_dark_willow_bedlam_custom_attack", -- modifier name
		{ duration = kv.duration } -- kv
	)
end

function modifier_dark_willow_bedlam_custom:OnRemoved()
end

function modifier_dark_willow_bedlam_custom:OnDestroy()
	if not IsServer() then return end

	-- kill the wisp
	UTIL_Remove( self.wisp )
	-- self.wisp:ForceKill( false )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_dark_willow_bedlam_custom:OnIntervalThink()
	-- update position
	self.rotation = self.rotation + self.rotate_delta
	local origin = self.parent:GetOrigin()
	self.position = RotatePosition( origin, QAngle( 0, -self.rotation, 0 ), origin + self.relative_pos )
	self.facing = RotatePosition( self.zero, QAngle( 0, -self.rotation, 0 ), self.base_facing )

	-- update wisp
	self.wisp:SetOrigin( self.position )
	self.wisp:SetForwardVector( self.facing )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_dark_willow_bedlam_custom:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_aoe_cast.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self:GetParent(),
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		2,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControl( effect_cast, 3, Vector( self.rotate_radius, self.rotate_radius, self.rotate_radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

modifier_dark_willow_bedlam_custom_attack = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_dark_willow_bedlam_custom_attack:IsHidden()
	return false
end

function modifier_dark_willow_bedlam_custom_attack:IsDebuff()
	return false
end

function modifier_dark_willow_bedlam_custom_attack:IsStunDebuff()
	return false
end

function modifier_dark_willow_bedlam_custom_attack:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_dark_willow_bedlam_custom_attack:OnCreated( kv )
	-- references
	local damage = self:GetAbility():GetSpecialValueFor( "attack_damage" )
    local manaDrainPct = self:GetAbility():GetSpecialValueFor( "mana_drain_per_attack_pct" )
    local manaDmgMultiplier = self:GetAbility():GetSpecialValueFor( "mana_drain_multiplier" )
    local manaDmgMultiplierPerInt = self:GetAbility():GetSpecialValueFor( "mana_drain_multiplier_per_int" )
    self.damageFromMana = self:GetCaster():GetMaxMana() * (manaDrainPct/100) 
	self.interval = self:GetAbility():GetSpecialValueFor( "attack_interval" )
	self.radius = self:GetAbility():GetSpecialValueFor( "attack_radius" )

    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        self.radius = self:GetAbility():GetSpecialValueFor( "shard_attack_radius" )
    end

	if not IsServer() then return end
	-- precache projectile
	-- local projectile_name = "particles/units/heroes/hero_dark_willow/dark_willow_willowisp_base_attack.vpcf"
	local projectile_name = ""
	local projectile_speed = 1400

	self.info = {
		-- Target = target,
		Source = self:GetParent(),
		Ability = self:GetAbility(),	
		
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		bDodgeable = true,                           -- Optional
		-- bIsAttack = false,                                -- Optional

		ExtraData = {
			damage = damage + (self.damageFromMana * ((manaDmgMultiplier+(self:GetCaster():GetIntellect()*manaDmgMultiplierPerInt))/100)),
		}
	}

	-- Start interval
	self:StartIntervalThink( self.interval )

	-- play effects
	self:PlayEffects()
end

function modifier_dark_willow_bedlam_custom_attack:OnRefresh( kv )
	-- references
	local damage = self:GetAbility():GetSpecialValueFor( "attack_damage" )
    local manaDrainPct = self:GetAbility():GetSpecialValueFor( "mana_drain_per_attack_pct" )
    local manaDmgMultiplier = self:GetAbility():GetSpecialValueFor( "mana_drain_multiplier" )
    local manaDmgMultiplierPerInt = self:GetAbility():GetSpecialValueFor( "mana_drain_multiplier_per_int" )
    self.damageFromMana = self:GetCaster():GetMaxMana() * (manaDrainPct/100)
	self.interval = self:GetAbility():GetSpecialValueFor( "attack_interval" )
	self.radius = self:GetAbility():GetSpecialValueFor( "attack_radius" )

    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        self.radius = self:GetAbility():GetSpecialValueFor( "shard_attack_radius" )
    end

	if not IsServer() then return end
	-- update projectile
	self.info.ExtraData.damage = damage + (self.damageFromMana * ((manaDmgMultiplier+(self:GetCaster():GetIntellect()*manaDmgMultiplierPerInt))/100))

	-- play effects
	local sound_cast = "Hero_DarkWillow.WispStrike.Cast"
	EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_dark_willow_bedlam_custom_attack:OnRemoved()
end

function modifier_dark_willow_bedlam_custom_attack:OnDestroy()
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_dark_willow_bedlam_custom_attack:OnIntervalThink()
	-- find enemies
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self:GetParent():GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	for _,enemy in pairs(enemies) do
        if self.damageFromMana > self:GetCaster():GetMana() then
            self:GetAbility():ToggleAbility()
            return
        end
    
        self:GetCaster():SpendMana(self.damageFromMana, self:GetAbility())

        -- create projectile effect
        local effect = self:PlayEffects1( enemy, self.info.iMoveSpeed )

        -- launch attack
        self.info.Target = enemy
        self.info.ExtraData.effect = effect

        ProjectileManager:CreateTrackingProjectile( self.info )

        -- play effects
        local sound_cast = "Hero_DarkWillow.WillOWisp.Damage"
        EmitSoundOn( sound_cast, self:GetParent() )

        break
	end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_dark_willow_bedlam_custom_attack:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_aoe.vpcf"
	local sound_cast = "Hero_DarkWillow.WispStrike.Cast"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, self.radius, self.radius ) )

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_dark_willow_bedlam_custom_attack:PlayEffects1( target, speed )
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_willowisp_base_attack.vpcf"
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )

	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( speed, 0, 0 ) )

	return effect_cast
end