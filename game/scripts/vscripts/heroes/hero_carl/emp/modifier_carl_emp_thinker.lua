modifier_carl_emp_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_carl_emp_thinker:IsHidden()
	return true
end

function modifier_carl_emp_thinker:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_carl_emp_thinker:OnCreated( kv )
	if IsServer() then
		self.radius = self:GetAbility():GetOrbSpecialValueFor( "area_of_effect", "q" )
		self.damage_pct = self:GetAbility():GetOrbSpecialValueFor( "mana_multiplier", "w" )

		self.mana = kv.mana

		-- play effects
		self:PlayEffects1()
	end
end

function modifier_carl_emp_thinker:OnDestroy( kv )
	if IsServer() then
		-- find caught units
		local enemies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),	-- int, your team number
			self:GetParent():GetOrigin(),	-- point, center point
			nil,	-- handle, cacheUnit. (not known)
			self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
			DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
			DOTA_UNIT_TARGET_FLAG_NONE,	-- int, flag filter
			0,	-- int, order filter
			false	-- bool, can grow cache
		)

		-- precache damage
		local damageTable = {
			-- victim = target,
			attacker = self:GetCaster(),
			-- damage = 500,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(), --Optional.
		}

		local mana_burn = self.mana
		
		for _,enemy in pairs(enemies) do
			-- burn mana
			
			-- damage based on mana burned
			damageTable.victim = enemy
			damageTable.damage = (mana_burn + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor( "int_to_damage" )/100))) * self.damage_pct
			ApplyDamage(damageTable)
		end

		-- play effects
		self:PlayEffects2()

		-- remove thinker
		UTIL_Remove( self:GetParent() )
	end
end

function modifier_carl_emp_thinker:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_invoker/invoker_emp.vpcf"
	local sound_cast = "Hero_Invoker.EMP.Charge"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( self.radius, 0, 0 ) )
	-- ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end

function modifier_carl_emp_thinker:PlayEffects2()
	-- Get Resources
	local sound_cast = "Hero_Invoker.EMP.Discharge"

	ParticleManager:DestroyParticle( self.effect_cast, false )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end