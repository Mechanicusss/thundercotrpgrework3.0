morphling_wavestorm_custom = class({})

LinkLuaModifier( "modifier_morphling_wavestorm_custom", "heroes/hero_morphling/morphling_wavestorm_custom/modifier_morphling_wavestorm_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- AOE Radius
function morphling_wavestorm_custom:GetAOERadius()
	return self:GetSpecialValueFor( "wavestrom_radius" )
end

--------------------------------------------------------------------------------
-- Ability Start
function morphling_wavestorm_custom:OnSpellStart()
	-- Props
	local caster = self:GetCaster()

	-- Ability props
	local wavestorm_duration = self:GetSpecialValueFor("wavestorm_duration")

	caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_morphling_wavestorm_custom", -- modifier name
		{ duration = wavestorm_duration } -- kv
	)
end

