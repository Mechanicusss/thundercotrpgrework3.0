modifier_morphling_wavestorm_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_morphling_wavestorm_custom:IsHidden()
	return true
end

function modifier_morphling_wavestorm_custom:IsDebuff()
	return false
end

function modifier_morphling_wavestorm_custom:IsStunDebuff()
	return false
end

function modifier_morphling_wavestorm_custom:IsPurgable()
	return false
end

function modifier_morphling_wavestorm_custom:AllowIllusionDuplicate()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_morphling_wavestorm_custom:OnCreated()
    self.wavestrom_radius = self:GetAbility():GetSpecialValueFor("wavestrom_radius")
    self.wavestrom_interval = self:GetAbility():GetSpecialValueFor("wavestrom_interval")
    self.wavestrom_damage = self:GetAbility():GetSpecialValueFor("wavestrom_damage")
    self.wavestorm_attributes_to_damage_pct = self:GetAbility():GetSpecialValueFor("wavestorm_attributes_to_damage_pct")
    self.wavestorm_duration = self:GetAbility():GetSpecialValueFor("wavestorm_duration")

    self.damage_total = self.wavestrom_damage + self:GetCaster():GetAgility() / 100 * self.wavestorm_attributes_to_damage_pct + self:GetCaster():GetStrength() / 100 * self.wavestorm_attributes_to_damage_pct
    
    -- generate data
	self.quartal = -1

    if IsServer() then
		-- precache damage
		self.damageTable = {
			-- victim = target,
			attacker = self:GetCaster(),
			damage = self.damage_total,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(), --Optional.
		}

		-- Start interval
		self:StartIntervalThink( self.wavestrom_interval )
		self:OnIntervalThink()

		-- Play Effects
		self:PlayEffects1()
	end
end

function modifier_morphling_wavestorm_custom:OnRefresh()
    self.wavestrom_radius = self:GetAbility():GetSpecialValueFor("wavestrom_radius")
    self.wavestrom_interval = self:GetAbility():GetSpecialValueFor("wavestrom_interval")
    self.wavestrom_damage = self:GetAbility():GetSpecialValueFor("wavestrom_damage")
    self.wavestorm_attributes_to_damage_pct = self:GetAbility():GetSpecialValueFor("wavestorm_attributes_to_damage_pct")
    self.wavestorm_duration = self:GetAbility():GetSpecialValueFor("wavestorm_duration")

    self.damage_total = self.wavestrom_damage + self:GetCaster():GetAgility() / 100 * self.wavestorm_attributes_to_damage_pct + self:GetCaster():GetStrength() / 100 * self.wavestorm_attributes_to_damage_pct
    
    -- generate data
	self.quartal = -1
    
    if IsServer() then
		-- precache damage
		self.damageTable = {
			-- victim = target,
			attacker = self:GetCaster(),
			damage = self.damage_total,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(), --Optional.
		}

		-- Start interval
		self:StartIntervalThink( self.wavestrom_interval )
		self:OnIntervalThink()

		-- Play Effects
		self:PlayEffects1()
	end
end

function modifier_morphling_wavestorm_custom:OnDestroy()
    if IsServer() then
		self:StartIntervalThink( -1 )
		self:StopEffects1()
	end
end

function modifier_morphling_wavestorm_custom:OnRemoved()
    if IsServer() then
		self:StartIntervalThink( -1 )
		self:StopEffects1()
	end
end

--------------------------------------------------------------------------------
-- Modifier Effects
--function modifier_morphling_wavestorm_custom:DeclareFunction()
--    local funcs = {
--
--    }
--    return funcs
--end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_morphling_wavestorm_custom:OnIntervalThink()
	-- Set explosion quartal
	self.quartal = self.quartal+1
	if self.quartal>3 then self.quartal = 0 end

	-- determine explosion relative position
	local a = RandomInt(0,90) + self.quartal*90
	local r = RandomInt(0,self.wavestrom_radius)
	local point = Vector( math.cos(a), math.sin(a), 0 ):Normalized() * r

	-- actual position
	point = self:GetCaster():GetOrigin() + point

	-- Explode at point
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		point,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.wavestrom_radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	-- damage units
	for _,enemy in pairs(enemies) do
		self.damageTable.victim = enemy
		ApplyDamage( self.damageTable )
	end

	-- Play effects
	self:PlayEffects2( point )
end
--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_morphling_wavestorm_custom:PlayEffects1()
	local particle_cast = "particles/econ/items/tidehunter/tidehunter_divinghelmet/tidehunter_gush_splash_water3c_diving_helmet.vpcf"
    
	self.sound_cast = "Hero_Morphling.Waveform"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	--self.effect_cast = assert(loadfile("lua_abilities/rubick_spell_steal_lua/rubick_spell_steal_lua_arcana"))(self, particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( self.slow_radius, self.slow_radius, 1 ) )
	self:AddParticle(
		self.effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	-- Play sound
	EmitSoundOn( self.sound_cast, self:GetCaster() )
end

function modifier_morphling_wavestorm_custom:PlayEffects2( point )
	-- Play particles
	local particle_cast = "particles/units/heroes/hero_kunkka/kunkka_spell_torrent_splash_water4.vpcf"
    
	-- Create particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	--local effect_cast = assert(loadfile("lua_abilities/rubick_spell_steal_lua/rubick_spell_steal_lua_arcana"))(self, particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, point )

	-- Play sound
	local sound_cast = "Hero_Morphling.Waveform"
	EmitSoundOnLocationWithCaster( point, sound_cast, self:GetCaster() )
end

function modifier_morphling_wavestorm_custom:StopEffects1()
	StopSoundOn( self.sound_cast, self:GetCaster() )
end