boss_dragon_sun_apocalypse = class({})
LinkLuaModifier( "modifier_boss_dragon_sun_apocalypse_thinker", "heroes/bosses/dragon/boss_dragon_sun_apocalypse", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function boss_dragon_sun_apocalypse:GetAOERadius()
	return self:GetSpecialValueFor( "search_radius" )
end

-- Commented out for Cataclysm talent when available
--------------------------------------------------------------------------------
-- function boss_dragon_sun_apocalypse:GetCooldown( level )
-- 	if self:GetCaster():HasScepter() then
-- 		return self:GetSpecialValueFor( "cooldown_scepter" )
-- 	end

-- 	return self.BaseClass.GetCooldown( self, level )
-- end

--------------------------------------------------------------------------------
-- Ability Cast Filter
-- function boss_dragon_sun_apocalypse:CastFilterResultTarget( hTarget )
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

-- function boss_dragon_sun_apocalypse:GetCustomCastErrorTarget( hTarget )
-- 	if self:GetCaster() == hTarget then
-- 		return "#dota_hud_error_cant_cast_on_self"
-- 	end

-- 	return ""
-- end

--------------------------------------------------------------------------------
-- Ability Start
function boss_dragon_sun_apocalypse:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- get values
	local delay = self:GetSpecialValueFor("delay")
	local vision_distance = self:GetSpecialValueFor("vision_distance")
	local vision_duration = self:GetSpecialValueFor("vision_duration")
	local search_radius = self:GetSpecialValueFor("search_radius")
	local enemy_count = self:GetSpecialValueFor("enemy_count")

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
				"modifier_boss_dragon_sun_apocalypse_thinker",
				{ duration = delay },
				randomEnemy:GetAbsOrigin(),
				caster:GetTeamNumber(),
				false
			)
        end)
    end

	-- create vision
	AddFOWViewer(DOTA_TEAM_GOODGUYS, point, vision_distance, vision_duration, false )
end

function boss_dragon_sun_apocalypse:OnStolen( hAbility )
	self.orbs = hAbility.orbs
end

function boss_dragon_sun_apocalypse:GetOrbSpecialValueFor( key_name, orb_name )
	if not IsServer() then return 0 end
	if not self.orbs[orb_name] then return 0 end
	return self:GetLevelSpecialValueFor( key_name, self.orbs[orb_name] )
end

---------

modifier_boss_dragon_sun_apocalypse_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_boss_dragon_sun_apocalypse_thinker:IsHidden()
	return true
end

function modifier_boss_dragon_sun_apocalypse_thinker:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_boss_dragon_sun_apocalypse_thinker:OnCreated( kv )
	if IsServer() then
		-- references
		self.damage = self:GetAbility():GetSpecialValueFor("damage") 
		self.radius = self:GetAbility():GetSpecialValueFor("area_of_effect")

		-- Play effects
		self:PlayEffects1()
	end
end

function modifier_boss_dragon_sun_apocalypse_thinker:OnDestroy( kv )
	if IsServer() then
		-- Damage enemies
		local damageTable = {
			-- victim = target,
			attacker = self:GetCaster(),
			-- damage = self.damage,
			damage_type = DAMAGE_TYPE_PURE,
			ability = self:GetAbility(), --Optional.
		}

		local enemies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),	-- int, your team number
			self:GetParent():GetOrigin(),	-- point, center point
			nil,	-- handle, cacheUnit. (not known)
			self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
			DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,	-- int, flag filter
			0,	-- int, order filter
			false	-- bool, can grow cache
		)

		for _,enemy in pairs(enemies) do
			damageTable.victim = enemy
			damageTable.damage = self.damage/#enemies
			ApplyDamage(damageTable)
		end

		-- Play effects
		self:PlayEffects2()

		-- remove thinker
		UTIL_Remove( self:GetParent() )
	end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_boss_dragon_sun_apocalypse_thinker:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_invoker/invoker_sun_strike_team.vpcf"
	local sound_cast = "Hero_Invoker.SunStrike.Charge"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticleForTeam( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster(), DOTA_TEAM_GOODGUYS )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end

function modifier_boss_dragon_sun_apocalypse_thinker:PlayEffects2()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_invoker/invoker_sun_strike.vpcf"
	local sound_cast = "Hero_Invoker.SunStrike.Ignite"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end