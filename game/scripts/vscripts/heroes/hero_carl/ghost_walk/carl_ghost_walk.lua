carl_ghost_walk = class({})
LinkLuaModifier( "modifier_carl_ghost_walk", "heroes/hero_carl/ghost_walk/modifier_carl_ghost_walk", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_carl_ghost_walk_debuff", "heroes/hero_carl/ghost_walk/modifier_carl_ghost_walk_debuff", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function carl_ghost_walk:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- load data
	local duration = self:GetSpecialValueFor("duration")

	-- add modifier
	caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_carl_ghost_walk", -- modifier name
		{ duration = duration } -- kv
	)

	-- Effects
	self:PlayEffects()
end

function carl_ghost_walk:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_invoker/invoker_ghost_walk.vpcf"
	local sound_cast = "Hero_Invoker.GhostWalk"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
end