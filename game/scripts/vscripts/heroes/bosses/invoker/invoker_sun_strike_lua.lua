invoker_sun_strike_lua = class({})
LinkLuaModifier( "modifier_invoker_sun_strike_lua_thinker", "heroes/bosses/invoker/modifier_invoker_sun_strike_lua_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_invoker_sun_strike_lua_thinker_cast_ability", "heroes/bosses/invoker/invoker_sun_strike_lua", LUA_MODIFIER_MOTION_NONE )

modifier_invoker_sun_strike_lua_thinker_cast_ability = class({
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end
})
--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function invoker_sun_strike_lua:GetAOERadius()
	return self:GetSpecialValueFor( "area_of_effect" )
end

-- Commented out for Cataclysm talent when available
--------------------------------------------------------------------------------
-- function invoker_sun_strike_lua:GetCooldown( level )
-- 	if self:GetCaster():HasScepter() then
-- 		return self:GetSpecialValueFor( "cooldown_scepter" )
-- 	end

-- 	return self.BaseClass.GetCooldown( self, level )
-- end

--------------------------------------------------------------------------------
-- Ability Cast Filter
-- function invoker_sun_strike_lua:CastFilterResultTarget( hTarget )
-- 	if self:GetCaster() == hTarget then
-- 		return UF_FAIL_CUSTOM
-- 	end

-- 	local nResult = UnitFilter(
-- 		hTarget,
-- 		DOTA_UNIT_TARGET_TEAM_BOTH,
-- 		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
-- 		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
-- 		self:GetCaster():GetTeamNumber()
-- 	)
-- 	if nResult ~= UF_SUCCESS then
-- 		return nResult
-- 	end

-- 	return UF_SUCCESS
-- end

-- function invoker_sun_strike_lua:GetCustomCastErrorTarget( hTarget )
-- 	if self:GetCaster() == hTarget then
-- 		return "#dota_hud_error_cant_cast_on_self"
-- 	end

-- 	return ""
-- end

--------------------------------------------------------------------------------
-- Ability Start
function invoker_sun_strike_lua:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	caster:AddNewModifier(caster, self, "modifier_invoker_sun_strike_lua_thinker_cast_ability", {
		duration = 12
	})
end
---------
function modifier_invoker_sun_strike_lua_thinker_cast_ability:OnCreated()
	if not IsServer() then return end

	self:StartIntervalThink(0.4)
end

function modifier_invoker_sun_strike_lua_thinker_cast_ability:OnIntervalThink()
	if not IsServer() then return end

	local parent = self:GetParent()
	local pos = parent:GetAbsOrigin()
	local ability = self:GetAbility()
	local radius = 600

	-- get values
	local delay = ability:GetSpecialValueFor("delay")
	local vision_distance = ability:GetSpecialValueFor("vision_distance")
	local vision_duration = ability:GetSpecialValueFor("vision_duration")

	local randomPos = Vector(pos.x+RandomInt(-radius, radius), pos.y+RandomInt(-radius, radius), pos.z)

	-- create modifier thinker
	CreateModifierThinker(
		parent,
		ability,
		"modifier_invoker_sun_strike_lua_thinker",
		{ duration = delay },
		randomPos,
		bit.bor(DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS),
		false
	)

	-- create vision
	AddFOWViewer(bit.bor(DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS), randomPos, vision_distance, vision_duration, false )
end