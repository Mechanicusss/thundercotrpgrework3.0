crystal_maiden_freezing_field_custom = class({})
modifier_crystal_maiden_freezing_field_custom_emitter = class({})
LinkLuaModifier( "modifier_crystal_maiden_freezing_field_custom", "heroes/hero_crystal_maiden/crystal_maiden_freezing_field_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_crystal_maiden_freezing_field_custom_effect", "heroes/hero_crystal_maiden/crystal_maiden_freezing_field_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_crystal_maiden_freezing_field_custom_emitter", "heroes/hero_crystal_maiden/crystal_maiden_freezing_field_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function crystal_maiden_freezing_field_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    self.spellDuration = self:GetSpecialValueFor("duration_tooltip")

    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNewModifier(caster, self, "modifier_crystal_maiden_freezing_field_custom_emitter", { 
        duration = self.spellDuration
    })

    -- Add modifier
    self.modifier = emitter:AddNewModifier(
        emitter, -- player source
        self, -- ability source
        "modifier_crystal_maiden_freezing_field_custom", -- modifier name
        { duration = self.spellDuration, owner = caster:GetPlayerID() } -- kv
    )
end

function crystal_maiden_freezing_field_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function modifier_crystal_maiden_freezing_field_custom_emitter:OnDestroy()
    if not IsServer() then return end

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end
end

function modifier_crystal_maiden_freezing_field_custom_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true
    }   

    return state
end

--------------------------------------------------------------------------------
-- Ability Channeling
-- function crystal_maiden_freezing_field_custom:GetChannelTime()

-- end
--[[
function crystal_maiden_freezing_field_custom:OnChannelFinish( bInterrupted )
    if self.modifier then
        self.modifier:Destroy()
        self.modifier = nil
    end
end
--]]

--------------------------------------------------------------------------------
-- Ability Considerations
function crystal_maiden_freezing_field_custom:AbilityConsiderations()
    -- Scepter
    local bScepter = caster:HasScepter()

    -- Linken & Lotus
    local bBlocked = target:TriggerSpellAbsorb( self )

    -- Break
    local bBroken = caster:PassivesDisabled()

    -- Advanced Status
    local bInvulnerable = target:IsInvulnerable()
    local bInvisible = target:IsInvisible()
    local bHexed = target:IsHexed()
    local bMagicImmune = target:IsMagicImmune()

    -- Illusion Copy
    local bIllusion = target:IsIllusion()
end

modifier_crystal_maiden_freezing_field_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_crystal_maiden_freezing_field_custom:IsHidden()
    return true
end

function modifier_crystal_maiden_freezing_field_custom:IsDebuff()
    return false
end

function modifier_crystal_maiden_freezing_field_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Aura
function modifier_crystal_maiden_freezing_field_custom:IsAura()
    return true
end

function modifier_crystal_maiden_freezing_field_custom:GetModifierAura()
    return "modifier_crystal_maiden_freezing_field_custom_effect"
end

function modifier_crystal_maiden_freezing_field_custom:GetAuraRadius()
    return self.slow_radius
end

function modifier_crystal_maiden_freezing_field_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_crystal_maiden_freezing_field_custom:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
end

function modifier_crystal_maiden_freezing_field_custom:GetAuraDuration()
    return self.slow_duration
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_crystal_maiden_freezing_field_custom:OnCreated( kv )
    -- references
    self.slow_radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.slow_duration = self:GetAbility():GetSpecialValueFor( "slow_duration" )
    self.explosion_radius = self:GetAbility():GetSpecialValueFor( "explosion_radius" )
    self.explosion_interval = self:GetAbility():GetSpecialValueFor( "explosion_interval" )
    self.explosion_min_dist = self:GetAbility():GetSpecialValueFor( "explosion_min_dist" )
    self.explosion_max_dist = self:GetAbility():GetSpecialValueFor( "explosion_max_dist" )
    local explosion_damage = self:GetAbility():GetSpecialValueFor( "damage" )

    -- generate data
    self.quartal = -1

    

    if IsServer() then
        local attacker = PlayerResource:GetPlayer(kv.owner):GetAssignedHero()

        -- precache damage
        self.damageTable = {
            -- victim = target,
            attacker = attacker,
            damage = explosion_damage + (attacker:GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100)),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility(), --Optional.
        }

        -- Start interval
        self:StartIntervalThink( self.explosion_interval )
        self:OnIntervalThink()

        -- Play Effects
        self:PlayEffects1()
    end
end

function modifier_crystal_maiden_freezing_field_custom:OnRefresh( kv )
    -- references
    self.slow_radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.explosion_radius = self:GetAbility():GetSpecialValueFor( "explosion_radius" )
    self.explosion_interval = self:GetAbility():GetSpecialValueFor( "explosion_interval" )
    self.explosion_min_dist = self:GetAbility():GetSpecialValueFor( "explosion_min_dist" )
    self.explosion_max_dist = self:GetAbility():GetSpecialValueFor( "explosion_max_dist" )
    local explosion_damage = self:GetAbility():GetSpecialValueFor( "damage" )

    -- generate data
    self.quartal = -1

    if IsServer() then
        local attacker = PlayerResource:GetPlayer(kv.owner):GetAssignedHero()

        -- precache damage
        self.damageTable = {
            -- victim = target,
            attacker = attacker,
            damage = explosion_damage + (attacker:GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100)),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility(), --Optional.
        }

        -- Start interval
        self:StartIntervalThink( self.explosion_interval )
        self:OnIntervalThink()
    end
end

function modifier_crystal_maiden_freezing_field_custom:OnDestroy( kv )
    if IsServer() then
        self:StartIntervalThink( -1 )
        self:StopEffects1()

        self:GetParent():RemoveModifierByName("modifier_crystal_maiden_freezing_field_custom_emitter")
    end
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_crystal_maiden_freezing_field_custom:OnIntervalThink()
    -- Set explosion quartal
    self.quartal = self.quartal+1
    if self.quartal>3 then self.quartal = 0 end

    -- determine explosion relative position
    local a = RandomInt(0,90) + self.quartal*90
    local r = RandomInt(self.explosion_min_dist,self.explosion_max_dist)
    local point = Vector( math.cos(a), math.sin(a), 0 ):Normalized() * r

    -- actual position
    point = self:GetCaster():GetOrigin() + point

    -- Explode at point
    local enemies = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(),   -- int, your team number
        point,  -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.explosion_radius,  -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
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
-- Effects
function modifier_crystal_maiden_freezing_field_custom:PlayEffects1()
    local particle_cast = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_snow.vpcf"
    self.sound_cast = "hero_Crystal.freezingField.wind"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
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

function modifier_crystal_maiden_freezing_field_custom:PlayEffects2( point )
    -- Play particles
    local particle_cast = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"

    -- Create particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, point )

    -- Play sound
    local sound_cast = "hero_Crystal.freezingField.explosion"
    EmitSoundOnLocationWithCaster( point, sound_cast, self:GetCaster() )
end

function modifier_crystal_maiden_freezing_field_custom:StopEffects1()
    StopSoundOn( self.sound_cast, self:GetCaster() )
end

modifier_crystal_maiden_freezing_field_custom_effect = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_crystal_maiden_freezing_field_custom_effect:IsHidden()
    return false
end

function modifier_crystal_maiden_freezing_field_custom_effect:IsDebuff()
    return true
end

function modifier_crystal_maiden_freezing_field_custom_effect:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_crystal_maiden_freezing_field_custom_effect:OnCreated( kv )
    -- references
    self.ms_slow = self:GetAbility():GetSpecialValueFor( "movespeed_slow" )
    self.as_slow = self:GetAbility():GetSpecialValueFor( "attack_slow" )
end

function modifier_crystal_maiden_freezing_field_custom_effect:OnRefresh( kv )
    -- references
    self.ms_slow = self:GetAbility():GetSpecialValueFor( "movespeed_slow" )
    self.as_slow = self:GetAbility():GetSpecialValueFor( "attack_slow" )    
end

function modifier_crystal_maiden_freezing_field_custom_effect:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_crystal_maiden_freezing_field_custom_effect:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }

    return funcs
end

function modifier_crystal_maiden_freezing_field_custom_effect:GetModifierMoveSpeedBonus_Percentage()
    return self.ms_slow
end

function modifier_crystal_maiden_freezing_field_custom_effect:GetModifierAttackSpeedBonus_Constant()
    return self.as_slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_crystal_maiden_freezing_field_custom_effect:GetEffectName()
    return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_crystal_maiden_freezing_field_custom_effect:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end