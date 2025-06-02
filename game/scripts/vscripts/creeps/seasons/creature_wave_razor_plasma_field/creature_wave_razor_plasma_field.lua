creature_wave_razor_plasma_field = class({})

modifier_creature_wave_razor_plasma_field_base = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

LinkLuaModifier( "modifier_creature_wave_razor_plasma_field", "creeps/seasons/creature_wave_razor_plasma_field/creature_wave_razor_plasma_field", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_creature_wave_razor_plasma_field_base", "creeps/seasons/creature_wave_razor_plasma_field/creature_wave_razor_plasma_field", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_ring_lua", "modifiers/modifier_generic_ring_lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Init Abilities
function creature_wave_razor_plasma_field:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_razor.vsndevts", context )
    PrecacheResource( "particle", "particles/econ/items/razor/razor_arcana/razor_arcana_plasma_field.vpcf", context )
end

function creature_wave_razor_plasma_field:Spawn()
    if not IsServer() then return end
end

function creature_wave_razor_plasma_field:GetIntrinsicModifierName()
    return "modifier_creature_wave_razor_plasma_field_base"
end
--------------------------------------------------------------------------------
-- Ability Start
function modifier_creature_wave_razor_plasma_field_base:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_creature_wave_razor_plasma_field_base:OnTakeDamage(event)
    if not IsServer() then return end

    -- unit identifier
    local caster = self:GetCaster()

    if event.unit ~= caster or event.unit == event.attacker then return end
    if not event.attacker:IsRealHero() then return end
    if caster:PassivesDisabled() then return end
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= 0 then
        return
    end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    if not RollPercentage(ability:GetSpecialValueFor("chance")) then return end

    ability:UseResources(false, false, false, true)

    -- load data
    local radius = ability:GetSpecialValueFor( "radius" )
    local speed = ability:GetSpecialValueFor( "speed" )

    -- play effects
    local effect = self:PlayEffects( radius, speed )

    -- create ring
    local pulse = caster:AddNewModifier(
        caster, -- player source
        ability, -- ability source
        "modifier_generic_ring_lua", -- modifier name
        {
            end_radius = radius,
            speed = speed,
            target_team = DOTA_UNIT_TARGET_TEAM_ENEMY,
            target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        } -- kv
    )
    pulse:SetCallback( function( enemy )
        self:OnHit( enemy, event.original_damage )
    end)

    pulse:SetEndCallback( function()
        -- set effects
        ParticleManager:SetParticleControl( effect, 1, Vector( speed, radius, -1 ) )

        -- create retract ring
        local retract
        local dead = false
        if not caster:IsAlive() then
            dead = true
            -- dead units can't get modifiers
            local thinker = CreateModifierThinker(
                caster, -- player source
                ability, -- ability source
                "modifier_generic_ring_lua", -- modifier name
                {
                    start_radius = radius,
                    end_radius = 0,
                    speed = speed,
                    target_team = DOTA_UNIT_TARGET_TEAM_ENEMY,
                    target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                }, -- kv
                caster:GetOrigin(),
                caster:GetTeamNumber(),
                false
            )
            retract = thinker:FindModifierByName( "modifier_generic_ring_lua" )
        else
            retract = caster:AddNewModifier(
                caster, -- player source
                ability, -- ability source
                "modifier_generic_ring_lua", -- modifier name
                {
                    start_radius = radius,
                    end_radius = 0,
                    speed = speed,
                    target_team = DOTA_UNIT_TARGET_TEAM_ENEMY,
                    target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                } -- kv
            )
        end
        retract:SetCallback( function( enemy )
            self:OnHit( enemy, event.original_damage )
        end)

        retract:SetEndCallback( function()
            -- destroy particle
            ParticleManager:DestroyParticle( effect, false )
            ParticleManager:ReleaseParticleIndex( effect )
        end)
    end)
end

function modifier_creature_wave_razor_plasma_field_base:OnHit( enemy, damageTaken )
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    -- load data
    local radius = ability:GetSpecialValueFor( "radius" )
    local damage_flat = ability:GetSpecialValueFor( "damage_reflected" )
    local duration = ability:GetSpecialValueFor( "slow_duration" )

    -- calculate damage
    local distance = (enemy:GetOrigin()-caster:GetOrigin()):Length2D()
    local pct = (distance/radius)
    pct = math.min(pct,1)
    local damage = damageTaken * (damage_flat/100)

    -- apply damage
    local damageTable = {
        victim = enemy,
        attacker = caster,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability, --Optional.
    }
    ApplyDamage(damageTable)

    -- Play effects
    -- self:PlayEffects2( enemy )
    local sound_cast = "Ability.PlasmaFieldImpact"
    EmitSoundOn( sound_cast, enemy )
end

--------------------------------------------------------------------------------
-- Effects
function modifier_creature_wave_razor_plasma_field_base:PlayEffects( radius, speed )
    -- Get Resources
    local particle_cast = "particles/econ/items/razor/razor_arcana/razor_arcana_plasma_field.vpcf"
    local sound_cast = "Ability.PlasmaField"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( speed, radius, 1 ) )

    EmitSoundOn( sound_cast, self:GetCaster() )

    return effect_cast
end

modifier_creature_wave_razor_plasma_field = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_creature_wave_razor_plasma_field:IsHidden()
    return false
end

function modifier_creature_wave_razor_plasma_field:IsDebuff()
    return true
end

function modifier_creature_wave_razor_plasma_field:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_creature_wave_razor_plasma_field:OnCreated( kv )
    if not IsServer() then return end
    -- send init data from server to client
    self:SetHasCustomTransmitterData( true )
end

function modifier_creature_wave_razor_plasma_field:OnRefresh( kv )
    if not IsServer() then return end
    -- references
end

function modifier_creature_wave_razor_plasma_field:OnRemoved()
end

function modifier_creature_wave_razor_plasma_field:OnDestroy()
end

--------------------------------------------------------------------------------
-- Transmitter data


--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_creature_wave_razor_plasma_field:DeclareFunctions()
    local funcs = {
    }

    return funcs
end

