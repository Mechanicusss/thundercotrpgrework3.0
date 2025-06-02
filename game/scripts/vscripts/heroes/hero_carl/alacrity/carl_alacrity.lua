carl_alacrity = class({})
LinkLuaModifier( "modifier_carl_alacrity", "heroes/hero_carl/alacrity/modifier_carl_alacrity", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function carl_alacrity:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- load data
	local duration = self:GetSpecialValueFor("duration")

	-- add modifier
	target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_carl_alacrity", -- modifier name
		{ duration = duration } -- kv
	)
end