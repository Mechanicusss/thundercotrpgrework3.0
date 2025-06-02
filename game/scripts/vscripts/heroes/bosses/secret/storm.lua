secret_zeus_storm = class({})
modifier_secret_zeus_storm_thinker=class({})
LinkLuaModifier( "modifier_secret_zeus_storm", "heroes/bosses/secret/storm", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_secret_zeus_storm_thinker", "heroes/bosses/secret/storm", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function secret_zeus_storm:GetAOERadius()
    return self:GetSpecialValueFor( "radius" )
end

function modifier_secret_zeus_storm_thinker:IsHidden() return true end

function secret_zeus_storm:GetIntrinsicModifierName()
    return "modifier_secret_zeus_storm_thinker"
end

function modifier_secret_zeus_storm_thinker:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.5)
end

function modifier_secret_zeus_storm_thinker:OnIntervalThink()
    local parent = self:GetParent()

    local storm = self:GetAbility()

    if not parent:IsSilenced() and not parent:IsHexed() and not parent:IsStunned() and parent:IsAttacking() and storm:IsCooldownReady() then
        CreateModifierThinker(
            parent, -- player source
            storm, -- ability source
            "modifier_secret_zeus_storm", -- modifier name
            {}, -- kv
            parent:GetAbsOrigin(),
            parent:GetTeamNumber(),
            false
        )

        storm:UseResources(false, false, false, true)
    end

    -----
    local thunder = parent:FindAbilityByName("secret_zeus_thunder")
    if thunder ~= nil then
        if not thunder:IsCooldownReady() then return end

        parent:CastAbilityImmediately(thunder, 1)
        thunder:UseResources(false, false, false, true)
    end
end

--------------------------------------------------------------------------------
-- Ability Start
function secret_zeus_storm:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- create thinker
    CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_secret_zeus_storm", -- modifier name
        {}, -- kv
        point,
        caster:GetTeamNumber(),
        false
    )

    -- effects
    local sound_cast = "Hero_Disruptor.StaticStorm.Cast"
    EmitSoundOn( sound_cast, caster )
end

modifier_secret_zeus_storm = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_secret_zeus_storm:IsHidden()
    return false
end

function modifier_secret_zeus_storm:IsDebuff()
    return true
end

function modifier_secret_zeus_storm:IsStunDebuff()
    return false
end

function modifier_secret_zeus_storm:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_secret_zeus_storm:OnCreated( kv )
    -- scepter should known both client and server
    self.scepter = true

    if not IsServer() then return end

    -- check if it is thinker or aura targets
    self.owner = kv.isProvidedByAura~=1
    if not self.owner then return end

    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.pulses = self:GetAbility():GetSpecialValueFor( "pulses" )
    local duration = self:GetAbility():GetSpecialValueFor( "duration" )
    local damage = self:GetAbility():GetSpecialValueFor( "damage_max" )
    if self.scepter then
        self.pulses = self:GetAbility():GetSpecialValueFor( "pulses_scepter" )
        duration = self:GetAbility():GetSpecialValueFor( "duration_scepter" )
    end
    
    -- calculate interval
    local interval = duration/self.pulses

    -- calculate damage
    local max_tick_damage = damage*interval
    self.tick_damage = max_tick_damage/self.pulses
    self.pulse = 0

    -- precache damage
    self.damageTable = {
        -- victim = target,
        attacker = self:GetCaster(),
        -- damage = 500,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(), --Optional.
    }

    -- Start interval
    self:StartIntervalThink( interval )
    -- self:OnIntervalThink()

    -- play effects
    self:PlayEffects1( duration )
    self.sound_loop = "Hero_Disruptor.StaticStorm"
    EmitSoundOn( self.sound_loop, self:GetParent() )
end

function modifier_secret_zeus_storm:OnRefresh( kv )
    
end

function modifier_secret_zeus_storm:OnRemoved()
end

function modifier_secret_zeus_storm:OnDestroy()
    if not IsServer() then return end

    if self.owner then
        -- end sound
        StopSoundOn( self.sound_loop, self:GetParent() )
        local sound_stop = "Hero_Disruptor.StaticStorm.End"
        EmitSoundOn( sound_stop, self:GetParent() )

        UTIL_Remove( self:GetParent() )
    end
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_secret_zeus_storm:CheckState()
    local state = {
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED] = self.scepter,
    }

    return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_secret_zeus_storm:OnIntervalThink()
    -- increment pulse
    self.pulse = self.pulse + 1

    -- find enemies
    local enemies = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(),   -- int, your team number
        self:GetParent():GetOrigin(),   -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    -- set damage
    self.damageTable.damage = self.tick_damage * self.pulse

    for _,enemy in pairs(enemies) do
        -- damage enemies
        self.damageTable.victim = enemy
        if enemy:IsMagicImmune() then break end
        ApplyDamage( self.damageTable )

        -- effects
        self:PlayEffects2(enemy)
    end

    -- check for pulses
    if self.pulse >= self.pulses then
        self:Destroy()
    end
end

--------------------------------------------------------------------------------
-- Aura Effects
function modifier_secret_zeus_storm:IsAura()
    return self.owner
end

function modifier_secret_zeus_storm:GetModifierAura()
    return "modifier_secret_zeus_storm"
end

function modifier_secret_zeus_storm:GetAuraRadius()
    return self.radius
end

function modifier_secret_zeus_storm:GetAuraDuration()
    return 0.3
end

function modifier_secret_zeus_storm:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_secret_zeus_storm:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_secret_zeus_storm:PlayEffects1( duration )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetParent() )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, self.radius, self.radius ) )
    ParticleManager:SetParticleControl( effect_cast, 2, Vector( duration, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_secret_zeus_storm:PlayEffects2( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_disruptor/disruptor_static_storm_bolt_hero.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_OVERHEAD_FOLLOW, target )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end