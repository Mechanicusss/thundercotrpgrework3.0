void_spirit_resonant_pulse_custom = class({})
LinkLuaModifier( "modifier_generic_ring_lua", "modifiers/modifier_generic_ring_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_void_spirit_resonant_pulse_custom", "heroes/hero_void_spirit/void_spirit_resonant_pulse_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_void_spirit_resonant_pulse_custom_debuff", "heroes/hero_void_spirit/void_spirit_resonant_pulse_custom", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

modifier_void_spirit_resonant_pulse_custom_debuff = class(ItemBaseClassDebuff)
--------------------------------------------------------------------------------
-- Ability Start
function void_spirit_resonant_pulse_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()

    -- load data
    local duration = self:GetSpecialValueFor( "buff_duration" )

    -- add modifier
    caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_void_spirit_resonant_pulse_custom", -- modifier name
        { duration = duration } -- kv
    )
end

--------------------------------------------------------------------------------
-- Projectile
function void_spirit_resonant_pulse_custom:OnProjectileHit( target, location )
    if not target then return end

    local modifier = target:FindModifierByNameAndCaster( "modifier_void_spirit_resonant_pulse_custom", self:GetCaster() )
    if not modifier then return end
    modifier:Absorb()
end

modifier_void_spirit_resonant_pulse_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_void_spirit_resonant_pulse_custom:IsHidden()
    return false
end

function modifier_void_spirit_resonant_pulse_custom:IsDebuff()
    return false
end

function modifier_void_spirit_resonant_pulse_custom:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_void_spirit_resonant_pulse_custom:OnCreated( kv )
    self:SetHasCustomTransmitterData(true)

    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.speed = self:GetAbility():GetSpecialValueFor( "speed" )
    self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
    self.base_absorb = self:GetAbility():GetSpecialValueFor( "base_absorb_amount" )
    self.hero_absorb = self:GetAbility():GetSpecialValueFor( "absorb_per_hero_hit" )
    self.return_speed = self:GetAbility():GetSpecialValueFor( "return_projectile_speed" )

    if not IsServer() then return end

    self.publicShield = 0

    -- set up shield
    self.shield = self:GetParent():GetMaxMana() * (self.base_absorb/100)

    -- precache damage
    self.damageTable = {
        -- victim = target,
        attacker = self:GetParent(),
        damage = self.damage + (self:GetParent():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100)),
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(), --Optional.
    }

    if self:GetParent():HasModifier("modifier_void_spirit_aether_remnant_custom_emitter") then
        self.damageTable.attacker = self:GetParent():GetOwner():GetAssignedHero()
    end

    -- precache projectile
    self.info = {
        Target = self:GetParent(),
        -- Source = caster,
        Ability = self:GetAbility(),    
        EffectName = "",
        iMoveSpeed = self.return_speed,
        bDodgeable = false,                           -- Optional
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
    }

    -- Create pulse
    local pulse = self:GetParent():AddNewModifier(
        self:GetParent(), -- player source
        self:GetAbility(), -- ability source
        "modifier_generic_ring_lua", -- modifier name
        {
            end_radius = self.radius,
            speed = self.speed,
            target_team = DOTA_UNIT_TARGET_TEAM_ENEMY,
            target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        } -- kv
    )
    pulse:SetCallback( function( enemy )
        -- apply damage
        self.damageTable.victim = enemy
        ApplyDamage(self.damageTable)

        enemy:AddNewModifier(
            self:GetParent(),
            self:GetAbility(),
            "modifier_void_spirit_resonant_pulse_custom_debuff",
            {
                duration = self:GetAbility():GetSpecialValueFor("debuff_duration")
            }
        )

        -- Play effects
        self:PlayEffects3( enemy )

        --if not enemy:IsHero() then return end

        -- create projectile
        self.info.Source = enemy
        ProjectileManager:CreateTrackingProjectile(self.info)

        -- Play effects
        self:PlayEffects4( enemy )
    end)

    -- Play effects
    self:PlayEffects1()
    self:PlayEffects2()
end

function modifier_void_spirit_resonant_pulse_custom:OnRefresh( kv )
    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.speed = self:GetAbility():GetSpecialValueFor( "speed" )
    self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
    self.base_absorb = self:GetAbility():GetSpecialValueFor( "base_absorb_amount" )
    self.hero_absorb = self:GetAbility():GetSpecialValueFor( "absorb_per_hero_hit" )
    self.return_speed = self:GetAbility():GetSpecialValueFor( "return_speed" )

    if not IsServer() then return end

    -- set up shield
    self.shield = self.shield + self:GetParent():GetMaxMana() * (self.base_absorb/100)

    -- precache damage
    self.damageTable = {
        -- victim = target,
        attacker = self:GetParent(),
        damage = self.damage + (self:GetParent():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100)),
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(), --Optional.
    }

    if self:GetParent():HasModifier("modifier_void_spirit_aether_remnant_custom_emitter") then
        self.damageTable.attacker = self:GetParent():GetOwner():GetAssignedHero()
    end

    -- Create pulse
    local pulse = self:GetParent():AddNewModifier(
        self:GetParent(), -- player source
        self:GetAbility(), -- ability source
        "modifier_generic_ring_lua", -- modifier name
        {
            end_radius = self.radius,
            speed = self.speed,
            target_team = DOTA_UNIT_TARGET_TEAM_ENEMY,
            target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        } -- kv
    )
    pulse:SetCallback( function( enemy )
        -- apply damage
        self.damageTable.victim = enemy
        ApplyDamage(self.damageTable)

        enemy:AddNewModifier(
            self:GetParent(),
            self:GetAbility(),
            "modifier_void_spirit_resonant_pulse_custom_debuff",
            {
                duration = self:GetAbility():GetSpecialValueFor("debuff_duration")
            }
        )

        -- Play effects
        self:PlayEffects3( enemy )

        --if not enemy:IsHero() then return end

        -- create projectile
        self.info.Source = enemy
        ProjectileManager:CreateTrackingProjectile(self.info)

        -- Play effects
        self:PlayEffects4( enemy )
    end)

    -- Play effects
    self:PlayEffects1()
end

function modifier_void_spirit_resonant_pulse_custom:OnRemoved()
end

function modifier_void_spirit_resonant_pulse_custom:OnDestroy()
    if not IsServer() then return end
    local sound_destroy = "Hero_VoidSpirit.Pulse.Destroy"
    EmitSoundOn( sound_destroy, self:GetParent() )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_void_spirit_resonant_pulse_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
    }

    return funcs
end

function modifier_void_spirit_resonant_pulse_custom:GetModifierIncomingPhysicalDamageConstant( params )
    if not IsServer() then return end

    -- play effects
    self:PlayEffects5()

    -- block based on damage
    if params.damage>self.shield then
        self:Destroy()
        return -self.shield
    else
        self.shield = self.shield-params.damage
        return -params.damage
    end
end

--------------------------------------------------------------------------------
-- Helper
function modifier_void_spirit_resonant_pulse_custom:Absorb()
    self.shield = self.shield + (self:GetParent():GetMaxMana() * (self.hero_absorb/100))
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_void_spirit_resonant_pulse_custom:GetStatusEffectName()
    return "particles/status_fx/status_effect_void_spirit_pulse_buff.vpcf"
end

function modifier_void_spirit_resonant_pulse_custom:StatusEffectPriority()
    return MODIFIER_PRIORITY_NORMAL
end

function modifier_void_spirit_resonant_pulse_custom:PlayEffects1()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse.vpcf"
    local sound_cast = "Hero_VoidSpirit.Pulse"

    -- adjustment
    local radius = self.radius * 2

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_void_spirit_resonant_pulse_custom:PlayEffects2()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse_shield.vpcf"
    local particle_cast2 = "particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse_buff.vpcf"
    local sound_cast = "Hero_VoidSpirit.Pulse.Cast"

    -- Get Data
    local radius = self:GetParent():GetModelRadius() * 1.25

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )

    local effect_cast = ParticleManager:CreateParticle( particle_cast2, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
end


function modifier_void_spirit_resonant_pulse_custom:PlayEffects3( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse_impact.vpcf"
    local particle_cast2 = "particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse_absorb.vpcf"
    local sound_cast = "Hero_VoidSpirit.Pulse.Target"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

function modifier_void_spirit_resonant_pulse_custom:PlayEffects4( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse_absorb.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_void_spirit_resonant_pulse_custom:PlayEffects5()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_void_spirit/pulse/void_spirit_pulse_shield_deflect.vpcf"

    -- Get Data
    local radius = 100

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
-------------
function modifier_void_spirit_resonant_pulse_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_void_spirit_resonant_pulse_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_resistance_reduction")
end