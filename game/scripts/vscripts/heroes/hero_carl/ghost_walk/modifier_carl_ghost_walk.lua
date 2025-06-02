modifier_carl_ghost_walk = class({})
local intPack = require( "util/intPack" )
--------------------------------------------------------------------------------
-- Classifications
function modifier_carl_ghost_walk:IsHidden()
	return false
end

function modifier_carl_ghost_walk:IsDebuff()
	return false
end

function modifier_carl_ghost_walk:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Aura
function modifier_carl_ghost_walk:IsAura()
	return true
end

function modifier_carl_ghost_walk:GetModifierAura()
	return "modifier_carl_ghost_walk_debuff"
end

function modifier_carl_ghost_walk:GetAuraRadius()
	return self.radius
end

function modifier_carl_ghost_walk:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_carl_ghost_walk:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_carl_ghost_walk:GetAuraDuration()
	return self.aura_duration
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_carl_ghost_walk:OnCreated( kv )
	if IsServer() then
		-- references
		self.radius = self:GetAbility():GetSpecialValueFor( "area_of_effect" )
		self.aura_duration = self:GetAbility():GetSpecialValueFor( "aura_fade_time" )
		self.self_slow = self:GetAbility():GetOrbSpecialValueFor( "self_slow", "w" )
		self.enemy_slow = self:GetAbility():GetOrbSpecialValueFor( "enemy_slow", "q" )

		-- send to client
		local sign = 0
		if self.self_slow<0 then sign = 2 end
		local tbl = {
			sign,
			math.abs(self.self_slow),
		}
		self:SetStackCount( intPack.Pack( tbl, 60 ) )
	else
		-- receive from server
		local tbl = intPack.Unpack( self:GetStackCount(), 2, 60 )
		self.self_slow = (1-tbl[1])*tbl[2]
		self:SetStackCount( 0 )
	end
end

function modifier_carl_ghost_walk:OnRefresh( kv )
	if IsServer() then
		-- references
		self.radius = self:GetAbility():GetSpecialValueFor( "area_of_effect" )
		self.aura_duration = self:GetAbility():GetSpecialValueFor( "aura_fade_time" )
		self.self_slow = self:GetAbility():GetOrbSpecialValueFor( "self_slow", "w" )
		self.enemy_slow = self:GetAbility():GetOrbSpecialValueFor( "enemy_slow", "q" )

		-- send to client
		local sign = 0
		if self.self_slow<0 then sign = 2 end
		local tbl = {
			sign,
			math.abs(self.self_slow),
		}
		self:SetStackCount( intPack.Pack( tbl, 60 ) )
	else
		-- receive from server
		local tbl = intPack.Unpack( self:GetStackCount(), 2, 60 )
		self.self_slow = (1-tbl[1])*tbl[2]
		self:SetStackCount( 0 )
	end
end

function modifier_carl_ghost_walk:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_carl_ghost_walk:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,

		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_EVENT_ON_ATTACK,
	}

	return funcs
end

function modifier_carl_ghost_walk:GetModifierMoveSpeedBonus_Percentage()
	return self.self_slow
end

function modifier_carl_ghost_walk:GetModifierInvisibilityLevel()
	return 1
end

function modifier_carl_ghost_walk:OnAbilityExecuted( params )
	if IsServer() then
		if params.unit~=self:GetParent() then return end

		self:Destroy()
	end
end

function modifier_carl_ghost_walk:OnAttack( params )
	if IsServer() then
		if params.attacker~=self:GetParent() then return end

		self:Destroy()
	end
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_carl_ghost_walk:CheckState()
	local state = {
		[MODIFIER_STATE_INVISIBLE] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
-- function modifier_carl_ghost_walk:GetEffectName()
-- 	return "particles/string/here.vpcf"
-- end

-- function modifier_carl_ghost_walk:GetEffectAttachType()
-- 	return PATTACH_ABSORIGIN_FOLLOW
-- end

-- function modifier_carl_ghost_walk:PlayEffects()
-- 	-- Get Resources
-- 	local particle_cast = "string"
-- 	local sound_cast = "string"

-- 	-- Get Data

-- 	-- Create Particle
-- 	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_NAME, hOwner )
-- 	ParticleManager:SetParticleControl( effect_cast, iControlPoint, vControlVector )
-- 	ParticleManager:SetParticleControlEnt(
-- 		effect_cast,
-- 		iControlPoint,
-- 		hTarget,
-- 		PATTACH_NAME,
-- 		"attach_name",
-- 		vOrigin, -- unknown
-- 		bool -- unknown, true
-- 	)
-- 	ParticleManager:SetParticleControlForward( effect_cast, iControlPoint, vForward )
-- 	SetParticleControlOrientation( effect_cast, iControlPoint, vForward, vRight, vUp )
-- 	ParticleManager:ReleaseParticleIndex( effect_cast )

-- 	-- buff particle
-- 	self:AddParticle(
-- 		nFXIndex,
-- 		bDestroyImmediately,
-- 		bStatusEffect,
-- 		iPriority,
-- 		bHeroEffect,
-- 		bOverheadEffect
-- 	)

-- 	-- Create Sound
-- 	EmitSoundOnLocationWithCaster( vTargetPosition, sound_location, self:GetCaster() )
-- 	EmitSoundOn( sound_target, target )
-- end