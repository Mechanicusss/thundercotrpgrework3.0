razor_plasma_field_custom = class({})
modifier_razor_plasma_field_custom_base = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})
LinkLuaModifier( "modifier_razor_plasma_field_custom", "heroes/hero_razor/razor_plasma_field_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_razor_plasma_field_custom_base", "heroes/hero_razor/razor_plasma_field_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_ring_lua", "modifiers/modifier_generic_ring_lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Init Abilities
function razor_plasma_field_custom:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_razor.vsndevts", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_razor/razor_plasmafield.vpcf", context )
end

function razor_plasma_field_custom:Spawn()
    if not IsServer() then return end
end

function razor_plasma_field_custom:GetIntrinsicModifierName()
    return "modifier_razor_plasma_field_custom_base"
end
--------------------------------------------------------------------------------
-- Ability Start
function modifier_razor_plasma_field_custom_base:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
    }
end

function modifier_razor_plasma_field_custom_base:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end
    if not event.inflictor then return end
    if event.inflictor:GetAbilityName() ~= "razor_plasma_field_custom" then return end

    local target = event.target
    local ability = self:GetAbility()

    local radius = ability:GetSpecialValueFor( "radius" )

    local distance = (target:GetOrigin()-parent:GetOrigin()):Length2D()
    local pct = (distance/radius)

    local damageMin = ability:GetSpecialValueFor("damage_min")/100
    local damageMax = ability:GetSpecialValueFor("damage_max")/100

    if pct < damageMin then
        pct = damageMin
    end

    if pct > damageMax then
        pct = damageMax
    end

    pct = pct * 100

    return pct
end

function modifier_razor_plasma_field_custom_base:OnAttack(event)
    if not IsServer() then return end

    -- unit identifier
    local caster = self:GetCaster()

    if event.attacker ~= caster then return end
    if caster:IsSilenced() then return end

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
        self:OnHit( enemy )
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
            self:OnHit( enemy )
        end)

        retract:SetEndCallback( function()
            -- destroy particle
            ParticleManager:DestroyParticle( effect, false )
            ParticleManager:ReleaseParticleIndex( effect )
        end)
    end)
end

function modifier_razor_plasma_field_custom_base:OnHit( enemy )
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    -- load data
    local radius = ability:GetSpecialValueFor( "radius" )
    local damage_flat = ability:GetSpecialValueFor( "damage" )
    local damage_min = ability:GetSpecialValueFor( "damage_min" )
    local damage_max = ability:GetSpecialValueFor( "damage_max" )
    local slow_min = ability:GetSpecialValueFor( "slow_min" )
    local slow_max = ability:GetSpecialValueFor( "slow_max" )
    local duration = ability:GetSpecialValueFor( "slow_duration" )

    -- calculate damage & slow
    local distance = (enemy:GetOrigin()-caster:GetOrigin()):Length2D()
    local pct = (distance/radius)
    pct = math.min(pct,1)
    local damage = (damage_flat + (caster:GetAverageTrueAttackDamage(caster)*(ability:GetSpecialValueFor("attack_conversion")/100)))
    local slow = slow_min + (slow_max-slow_min)*pct

    -- slow
    enemy:AddNewModifier(
        caster, -- player source
        ability, -- ability source
        "modifier_razor_plasma_field_custom", -- modifier name
        {
            duration = duration,
            slow = slow,
        } -- kv
    )

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
function modifier_razor_plasma_field_custom_base:PlayEffects( radius, speed )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_razor/razor_plasmafield.vpcf"
    local sound_cast = "Ability.PlasmaField"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( speed, radius, 1 ) )

    EmitSoundOn( sound_cast, self:GetCaster() )

    return effect_cast
end

modifier_razor_plasma_field_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_razor_plasma_field_custom:IsHidden()
    return false
end

function modifier_razor_plasma_field_custom:IsDebuff()
    return true
end

function modifier_razor_plasma_field_custom:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_razor_plasma_field_custom:OnCreated( kv )
    if not IsServer() then return end
    -- send init data from server to client
    self:SetHasCustomTransmitterData( true )

    -- references
    self.slow = kv.slow
    self:SetStackCount( self.slow )
end

function modifier_razor_plasma_field_custom:OnRefresh( kv )
    if not IsServer() then return end
    -- references
    self.slow = math.max(kv.slow,self.slow)
    self:SetStackCount( self.slow )
end

function modifier_razor_plasma_field_custom:OnRemoved()
end

function modifier_razor_plasma_field_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Transmitter data
function modifier_razor_plasma_field_custom:AddCustomTransmitterData()
    -- on server
    local data = {
        slow = self.slow
    }

    return data
end

function modifier_razor_plasma_field_custom:HandleCustomTransmitterData( data )
    -- on client
    self.slow = data.slow
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_razor_plasma_field_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_razor_plasma_field_custom:GetModifierMoveSpeedBonus_Percentage()
    return -self.slow
end