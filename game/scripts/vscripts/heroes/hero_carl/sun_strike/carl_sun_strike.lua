carl_sun_strike = class({})
LinkLuaModifier( "modifier_carl_sun_strike_thinker", "heroes/hero_carl/sun_strike/modifier_carl_sun_strike_thinker", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function carl_sun_strike:GetAOERadius()
	return self:GetSpecialValueFor( "search_radius" )
end

-- Commented out for Cataclysm talent when available
--------------------------------------------------------------------------------
-- function carl_sun_strike:GetCooldown( level )
-- 	if self:GetCaster():HasScepter() then
-- 		return self:GetSpecialValueFor( "cooldown_scepter" )
-- 	end

-- 	return self.BaseClass.GetCooldown( self, level )
-- end

--------------------------------------------------------------------------------
-- Ability Cast Filter
-- function carl_sun_strike:CastFilterResultTarget( hTarget )
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

-- function carl_sun_strike:GetCustomCastErrorTarget( hTarget )
-- 	if self:GetCaster() == hTarget then
-- 		return "#dota_hud_error_cant_cast_on_self"
-- 	end

-- 	return ""
-- end

--------------------------------------------------------------------------------
-- Ability Start
function carl_sun_strike:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- get values
	local delay = self:GetSpecialValueFor("delay")
	local vision_distance = self:GetSpecialValueFor("vision_distance")
	local vision_duration = self:GetSpecialValueFor("vision_duration")
	local search_radius = self:GetSpecialValueFor("search_radius")
	local enemy_count = self:GetOrbSpecialValueFor("enemy_count", "e")

	for i = 1, enemy_count, 1 do
		local time = i*(delay/enemy_count)
		if i == 1 then time = 0 end
        Timers:CreateTimer(time, function()
        	if not caster:IsAlive() then return end

        	local enemies = FindUnitsInRadius(
				caster:GetTeamNumber(),	-- int, your team number
				caster:GetOrigin(),	-- point, center point
				nil,	-- handle, cacheUnit. (not known)
				search_radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
				DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
				DOTA_UNIT_TARGET_FLAG_NONE,	-- int, flag filter
				0,	-- int, order filter
				false	-- bool, can grow cache
			)

			if not enemies then return end
            
            local randomEnemy = enemies[RandomInt(1, #enemies)]
            if not randomEnemy then return end

            -- create modifier thinker
			CreateModifierThinker(
				caster,
				self,
				"modifier_carl_sun_strike_thinker",
				{ duration = delay },
				randomEnemy:GetAbsOrigin(),
				caster:GetTeamNumber(),
				false
			)
        end)
    end

	-- create vision
	AddFOWViewer( caster:GetTeamNumber(), point, vision_distance, vision_duration, false )
end

function carl_sun_strike:OnStolen( hAbility )
	self.orbs = hAbility.orbs
end

function carl_sun_strike:GetOrbSpecialValueFor( key_name, orb_name )
	if not IsServer() then return 0 end
	if not self.orbs[orb_name] then return 0 end
	return self:GetLevelSpecialValueFor( key_name, self.orbs[orb_name] )
end