carl_emp = class({})
LinkLuaModifier( "modifier_carl_emp_thinker", "heroes/hero_carl/emp/modifier_carl_emp_thinker", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function carl_emp:GetAOERadius()
	return self:GetOrbSpecialValueFor( "area_of_effect", "q" )
end

--------------------------------------------------------------------------------
-- Ability Start
function carl_emp:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- load data
	local delay = self:GetSpecialValueFor("delay")

	local mana = caster:GetMana()
	
	caster:Script_ReduceMana( mana, nil )

	-- create modifier thinker
	CreateModifierThinker(
		caster, -- player source
		self, -- ability source
		"modifier_carl_emp_thinker", -- modifier name
		{ duration = delay, mana = mana },
		point,
		caster:GetTeamNumber(),
		false
	)

	-- Play effects
	local sound_cast = "Hero_Invoker.EMP.Cast"
	EmitSoundOn( sound_cast, self:GetCaster() )
end

function carl_emp:GetOrbSpecialValueFor( key_name, orb_name )
	if not IsServer() then return 0 end
	if not self.orbs[orb_name] then return 0 end
	return self:GetLevelSpecialValueFor( key_name, self.orbs[orb_name] )
end