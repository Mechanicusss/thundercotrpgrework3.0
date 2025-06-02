carl_cold_snap = class({})
LinkLuaModifier( "modifier_carl_cold_snap", "heroes/hero_carl/cold_snap/modifier_carl_cold_snap", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_stunned_lua", "modifiers/modifier_generic_stunned_lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function carl_cold_snap:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- load data
	local duration = self:GetOrbSpecialValueFor("duration", "q")

	-- logic
	target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_carl_cold_snap", -- modifier name
		{ duration = duration } -- kv
	)

	self:PlayEffects( target )
end

--------------------------------------------------------------------------------
function carl_cold_snap:PlayEffects( target )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_invoker/invoker_cold_snap.vpcf"
	local sound_cast = "Hero_Invoker.ColdSnap.Cast"
	local sound_target = "Hero_Invoker.ColdSnap"

	-- Get Data
	local direction = target:GetOrigin()-self:GetCaster():GetOrigin()

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControl( effect_cast, 1, self:GetCaster():GetOrigin() + direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
	EmitSoundOn( sound_target, target )
end