LinkLuaModifier("modifier_dawnbreaker_solar_hammer", "heroes/hero_dawnbreaker/solar_hammer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dawnbreaker_solar_hammer_thinker", "heroes/hero_dawnbreaker/solar_hammer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dawnbreaker_solar_hammer_nohammer", "heroes/hero_dawnbreaker/solar_hammer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dawnbreaker_solar_hammer_emitter", "heroes/hero_dawnbreaker/solar_hammer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dawnbreaker_solar_hammer_emitter_aura", "heroes/hero_dawnbreaker/solar_hammer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dawnbreaker_solar_hammer_emitter_aura_ally", "heroes/hero_dawnbreaker/solar_hammer", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local BaseAuraAlly = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

dawnbreaker_solar_hammer = class(ItemBaseClass)
modifier_dawnbreaker_solar_hammer = class(dawnbreaker_solar_hammer)
modifier_dawnbreaker_solar_hammer_emitter = class(dawnbreaker_solar_hammer)
modifier_dawnbreaker_solar_hammer_emitter_aura = class(BaseAura)
modifier_dawnbreaker_solar_hammer_emitter_aura_ally = class(BaseAuraAlly)
-------------
function dawnbreaker_solar_hammer:GetIntrinsicModifierName()
    return "modifier_dawnbreaker_solar_hammer"
end

function dawnbreaker_solar_hammer:Precache(context)
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_dawnbreaker.vsndevts", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/dawnbreaker_celestial_hammer_projectile.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/dawnbreaker_celestial_hammer_grounded.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/dawnbreaker_celestial_hammer_aoe_impact.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/dawnbreaker_converge.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/dawnbreaker_converge_burning_trail.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/dawnbreaker_converge_trail.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/dawnbreaker_converge_debuff.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_dawnbreaker/dawnbreaker_solar_guardian_damage.vpcf", context )
    
    
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_ambient_solar_flare.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_aoe.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_beam_shaft.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_dark_center.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_embers.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_healing_decal.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_outer.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_outer_diamonds.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_outer_diamonds_small.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_ring_flames.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_ring_outer_rope.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreaker_solar_guardian_sunrays.vpcf", context )

end

function dawnbreaker_solar_hammer:CastFilterResultLocation( vLoc )
    -- check nohammer
    if self:GetCaster():HasModifier( "modifier_dawnbreaker_solar_hammer_nohammer" ) then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end

function dawnbreaker_solar_hammer:GetCustomCastErrorLocation( vLoc )
    -- check nohammer
    if self:GetCaster():HasModifier( "modifier_dawnbreaker_solar_hammer_nohammer" ) then
        return "#dota_hud_error_nohammer"
    end

    return ""
end

function dawnbreaker_solar_hammer:OnUpgrade()
    local sub = self:GetCaster():FindAbilityByName( "dawnbreaker_solar_hammer_replace" )
    if not sub then
        sub = self:GetCaster():AddAbility( "dawnbreaker_solar_hammer_replace" )
    end

    sub:SetLevel( self:GetLevel() )
end

function dawnbreaker_solar_hammer:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- load data
    local name = ""
    local radius = self:GetSpecialValueFor( "projectile_radius" )
    local speed = self:GetSpecialValueFor( "projectile_speed" )
    local distance = self:GetSpecialValueFor( "range" )

    -- get direction
    local direction = point-caster:GetOrigin()
    local len = direction:Length2D()
    direction.z = 0
    direction = direction:Normalized()

    distance = math.min( distance, len )

    -- create thinker
    local thinker = CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_dawnbreaker_solar_hammer_thinker", -- modifier name
        {}, -- kv
        caster:GetOrigin(),
        self:GetCaster():GetTeamNumber(),
        false
    )

    -- create linear projectile
    local info = {
        Source = caster,
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin(),
    
        -- bDeleteOnHit = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    
        EffectName = name,
        fDistance = distance,
        fStartRadius = radius,
        fEndRadius = radius,
        vVelocity = direction * speed,
    }
    local data = {
        cast = 1,
        targets = {},
        thinker = thinker,
    }
    local id = ProjectileManager:CreateLinearProjectile( info )
    thinker.id = id
    dawnbreaker_solar_hammer.projectiles[id] = data
    table.insert( dawnbreaker_solar_hammer.thinkers, thinker )

    -- swap with sub-ability
    local ability = caster:FindAbilityByName( "dawnbreaker_solar_hammer_replace" )
    if ability then
        ability:SetActivated( true )

        caster:SwapAbilities(
            "dawnbreaker_solar_hammer",
            "dawnbreaker_solar_hammer_replace",
            false,
            true
        )

        ability:StartCooldown( ability:GetCooldown( -1 ) )
    end

    -- set no hammer
    caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_dawnbreaker_solar_hammer_nohammer", -- modifier name
        {} -- kv
    )

    -- play effects
    data.effect = self:PlayEffects1( caster:GetOrigin(), distance, direction * speed )
    data.throwLocation = point
end

--------------------------------------------------------------------------------
-- Effects
function dawnbreaker_solar_hammer:PlayEffects1( start, distance, velocity )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_celestial_hammer_projectile.vpcf"
    local sound_cast = "Hero_Dawnbreaker.Celestial_Hammer.Cast"

    -- Get Data
    local min_rate = 1
    local duration = distance/velocity:Length2D()
    local rotation = 0.5

    local rate = rotation/duration
    while rate<min_rate do
        rotation = rotation + 1
        rate = rotation/duration
    end

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, start )
    ParticleManager:SetParticleControl( effect_cast, 1, velocity )
    ParticleManager:SetParticleControl( effect_cast, 4, Vector( rate, 0, 0 ) )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )

    return effect_cast
end

function dawnbreaker_solar_hammer:PlayEffects2( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_celestial_hammer_aoe_impact.vpcf"
    local sound_cast = "Hero_Dawnbreaker.Celestial_Hammer.Damage"

    -- Get Data
    local radius = self:GetSpecialValueFor( "projectile_radius" )

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

function dawnbreaker_solar_hammer:PlayEffects3()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_converge.vpcf"

    -- Get Data
    local radius = self:GetSpecialValueFor( "projectile_radius" )

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        3,
        hTarget,
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function dawnbreaker_solar_hammer:StopEffects( effect )
    ParticleManager:DestroyParticle( effect, false )
    ParticleManager:ReleaseParticleIndex( effect )
end

dawnbreaker_solar_hammer.projectiles = {}
dawnbreaker_solar_hammer.thinkers = {}
function dawnbreaker_solar_hammer:OnProjectileThinkHandle( handle )
    local data = dawnbreaker_solar_hammer.projectiles[handle]
    if not data then return end
    if data.thinker:IsNull() then return end

    if data.cast==1 then
        local location = ProjectileManager:GetLinearProjectileLocation( handle )
        -- move thinker along projectile
        data.thinker:SetOrigin( location )

        -- destroy trees
        local radius = self:GetSpecialValueFor( "projectile_radius" )
        GridNav:DestroyTreesAroundPoint( location, radius, false )
    elseif data.cast==2 then
        local location = ProjectileManager:GetTrackingProjectileLocation( handle )
        local radius = self:GetSpecialValueFor( "projectile_radius" )

        -- move thinker along projectile
        data.thinker:SetOrigin( location )

        -- find enemies not yet hit
        local enemies = FindUnitsInRadius(
            self:GetCaster():GetTeamNumber(),   -- int, your team number
            location,   -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            0,  -- int, flag filter
            0,  -- int, order filter
            false   -- bool, can grow cache
        )
        for _,enemy in pairs(enemies) do
            if not data.targets[enemy] then
                data.targets[enemy] = true

                -- hammer hit
                self:HammerHit( enemy, location )
            end
        end

        -- destroy trees
        local radius = self:GetSpecialValueFor( "projectile_radius" )
        GridNav:DestroyTreesAroundPoint( location, radius, false )
    end
end

function dawnbreaker_solar_hammer:OnProjectileHitHandle( target, location, handle )
    local data = dawnbreaker_solar_hammer.projectiles[handle]
    if not handle then return end
    if not data then return end

    if data.cast==1 then
        if target then
            self:HammerHit( target, location )
            return false
        end

        -- set thinker origin
        local loc = GetGroundPosition( location, self:GetCaster() )
        data.thinker:SetOrigin( loc )

        -- begin delay
        local mod = data.thinker:FindModifierByName( "modifier_dawnbreaker_solar_hammer_thinker" )
        mod:Delay()

        -- stop effect
        self:StopEffects( data.effect )

        -- destroy handle
        dawnbreaker_solar_hammer.projectiles[handle] = nil

    elseif data.cast==2 then
        local caster = self:GetCaster()

        -- destroy thinker
        for i,thinker in pairs(dawnbreaker_solar_hammer.thinkers) do
            if thinker == data.thinker then
                table.remove( dawnbreaker_solar_hammer.thinkers, i )
                break
            end
        end
        local mod = data.thinker:FindModifierByName( "modifier_dawnbreaker_solar_hammer_thinker" )
        mod:Destroy()

        -- reset sub-ability
        local ability = caster:FindAbilityByName( "dawnbreaker_solar_hammer_replace" )
        if ability then
            caster:SwapAbilities(
                "dawnbreaker_solar_hammer",
                "dawnbreaker_solar_hammer_replace",
                true,
                false
            )
        end

        -- remove nohammer
        local nohammer = caster:FindModifierByName( "modifier_dawnbreaker_solar_hammer_nohammer" )
        if nohammer then
            nohammer:Decrement()
        end

        -- destroy converge modifier
        local converge = caster:FindModifierByName( "modifier_dawnbreaker_solar_hammer" )
        if converge then
            converge:Destroy()
        end

        -- destroy handle
        dawnbreaker_solar_hammer.projectiles[handle] = nil

        -- play effects
        self:PlayEffects3()
    end
end

function dawnbreaker_solar_hammer:HammerHit( target, location )
    local damage = self:GetSpecialValueFor( "hammer_impact_damage" )
    if target:IsMagicImmune() then return end

    local damageTable = {
        victim = target,
        attacker = self:GetCaster(),
        damage = damage + (self:GetCaster():GetStrength() * (self:GetSpecialValueFor("str_to_damage")/100)),
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }
    ApplyDamage(damageTable)

    -- play effects
    self:PlayEffects2( target )
end

function dawnbreaker_solar_hammer:Converge()
    local caster = self:GetCaster()

    local target
    for i,thinker in ipairs(dawnbreaker_solar_hammer.thinkers) do
        target = thinker
        break
    end
    if not target then return end

    -- find projectile if exist
    if dawnbreaker_solar_hammer.projectiles[target.id] then
        print(dawnbreaker_solar_hammer.projectiles[target.id].throwLocation)
        -- stop effect
        self:StopEffects( dawnbreaker_solar_hammer.projectiles[target.id].effect )

        -- destroy projectile
        dawnbreaker_solar_hammer.projectiles[target.id] = nil
        ProjectileManager:DestroyLinearProjectile( target.id )
    end

    -- set thinker to return
    --caster:SetAbsOrigin(target:GetOrigin())
    FindClearSpaceForUnit(caster, target:GetOrigin(), false)

    local mod = target:FindModifierByName( "modifier_dawnbreaker_solar_hammer_thinker" )
    mod:Return()
    mod:SolarStorm()

    -- add travel modifier
    caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_dawnbreaker_solar_hammer", -- modifier name
        {
            target = target:entindex(),
        } -- kv
    )

    -- play effects
    local sound_cast = "Hero_Dawnbreaker.Converge.Cast"
    EmitSoundOn( sound_cast, caster )
end

--------------------------------------------------------------------------------
-- Effects
function dawnbreaker_solar_hammer:PlayEffects1( start, distance, velocity )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_celestial_hammer_projectile.vpcf"
    local sound_cast = "Hero_Dawnbreaker.Celestial_Hammer.Cast"

    -- Get Data
    local min_rate = 1
    local duration = distance/velocity:Length2D()
    local rotation = 0.5

    local rate = rotation/duration
    while rate<min_rate do
        rotation = rotation + 1
        rate = rotation/duration
    end

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, start )
    ParticleManager:SetParticleControl( effect_cast, 1, velocity )
    ParticleManager:SetParticleControl( effect_cast, 4, Vector( rate, 0, 0 ) )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )

    return effect_cast
end

modifier_dawnbreaker_solar_hammer_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_dawnbreaker_solar_hammer_thinker:IsHidden()
    return true
end

function modifier_dawnbreaker_solar_hammer_thinker:IsDebuff()
    return false
end

function modifier_dawnbreaker_solar_hammer_thinker:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_dawnbreaker_solar_hammer_thinker:OnCreated( kv )
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    -- references
    self.name = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_celestial_hammer_return.vpcf"
    self.speed = self:GetAbility():GetSpecialValueFor( "projectile_speed" )
    self.delay = self:GetAbility():GetSpecialValueFor( "pause_duration" )
    self.duration = self:GetAbility():GetSpecialValueFor( "hammer_field_duration" )
    self.aoeRadius = self:GetAbility():GetSpecialValueFor( "hammer_aoe_radius" )
    self.heal = self:GetAbility():GetSpecialValueFor( "heal_pct" )
    self.tickInterval = self:GetAbility():GetSpecialValueFor( "interval" )
    self.burnDamage = self:GetAbility():GetSpecialValueFor( "burn_damage" )
    self.vision = 200
    self.interval = 0.1

    -- NOTE: arbitrary decision to mimic original spell
    self.max_return = 1.5

    if not IsServer() then return end

    -- play effects
    local sound_loop = "Hero_Dawnbreaker.Celestial_Hammer.Projectile"
    EmitSoundOn( sound_loop, self.parent )
end

function modifier_dawnbreaker_solar_hammer_thinker:OnRefresh( kv )
end

function modifier_dawnbreaker_solar_hammer_thinker:OnRemoved()
end

function modifier_dawnbreaker_solar_hammer_thinker:OnDestroy()
    if not IsServer() then return end
    UTIL_Remove( self:GetParent() )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_dawnbreaker_solar_hammer_thinker:OnIntervalThink()
    if not self.converge then
        self:Return()
        return
    end

    self.prev_pos = self.parent:GetOrigin()
end

--------------------------------------------------------------------------------
-- Helper
function modifier_dawnbreaker_solar_hammer_thinker:SolarStorm()
    -- Create Placeholder Unit that holds the aura --
    self.emitter = CreateUnitByName("outpost_placeholder_unit", self.parent:GetOrigin(), false, self.caster, self.caster, self.caster:GetTeamNumber())
    self.emitter:AddNoDraw()
    self.emitter:AddNewModifier(self.caster, self:GetAbility(), "modifier_dawnbreaker_solar_hammer_emitter", { 
        duration = self.duration, 
        radius = self.aoeRadius, 
        heal = self.heal, 
        interval = self.tickInterval,
        damage = self.burnDamage
    })
    -- --

    -- Particle --
    local point = GetGroundPosition( self.parent:GetOrigin(), self.caster )
    self.vfx = ParticleManager:CreateParticle("particles/dawnbreaker/dawnbreaker_solar_guardian_aoe.vpcf", PATTACH_WORLDORIGIN, self.caster)
    ParticleManager:SetParticleControl( self.vfx, 0, point )
    ParticleManager:SetParticleControl( self.vfx, 1, point )
    ParticleManager:SetParticleControl( self.vfx, 2, Vector( self.aoeRadius, self.aoeRadius, self.aoeRadius ) )

    EmitSoundOnLocationWithCaster( point, "Hero_Dawnbreaker.Solar_Guardian.Target", self.caster )
    --

    Timers:CreateTimer(self.duration, function()
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
        self.emitter:ForceKill(false)
    end)
end

function modifier_dawnbreaker_solar_hammer_thinker:Delay()
    self:PlayEffects1()
    self:StartIntervalThink( self.delay )

    -- add viewer
    AddFOWViewer( self.caster:GetTeamNumber(), self.parent:GetOrigin(), self.vision, self.delay, false)
end

function modifier_dawnbreaker_solar_hammer_thinker:Return()
    if self.converge then return end

    self.converge = true
    self.prev_pos = self.parent:GetOrigin()
    self:StartIntervalThink( self.interval )
    self:OnIntervalThink()

    -- calculate speed
    self.distance = (self.parent:GetOrigin()-self.caster:GetOrigin()):Length2D()
    if self.distance > self.speed*self.max_return then
        self.speed = self.distance/self.max_return
    end

    -- create projectile
    local info = {
        Target = self.caster,
        Source = self.parent,
        Ability = self.ability, 
        
        EffectName = self.name,
        iMoveSpeed = self.speed,
        bDodgeable = false,
    }
    local data = {
        cast = 2,
        targets = {},
        thinker = self.parent,
    }
    local id = ProjectileManager:CreateTrackingProjectile(info)
    self.ability.projectiles[id] = data

    -- play effects
    self:PlayEffects2()
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_dawnbreaker_solar_hammer_thinker:PlayEffects1()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_celestial_hammer_grounded.vpcf"
    local sound_cast = "Hero_Dawnbreaker.Celestial_Hammer.Impact"

    -- Get Data
    local direction = self:GetParent():GetOrigin()-self:GetCaster():GetOrigin()
    direction.z = 0
    direction = direction:Normalized()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetParent() )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, self:GetCaster():GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
    self.effect_cast = effect_cast

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )

    -- Create Sound
    EmitSoundOn( sound_cast, self.parent )
end

function modifier_dawnbreaker_solar_hammer_thinker:PlayEffects2()
    if self.effect_cast then
        ParticleManager:DestroyParticle( self.effect_cast, false )
        ParticleManager:ReleaseParticleIndex( self.effect_cast )
    end

    local sound_cast = "Hero_Dawnbreaker.Celestial_Hammer.Return"
    EmitSoundOn( sound_cast, self.parent )
end

modifier_dawnbreaker_solar_hammer_nohammer = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_dawnbreaker_solar_hammer_nohammer:IsHidden()
    return true
end

function modifier_dawnbreaker_solar_hammer_nohammer:IsDebuff()
    return false
end

function modifier_dawnbreaker_solar_hammer_nohammer:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_dawnbreaker_solar_hammer_nohammer:OnCreated( kv )
    if not IsServer() then return end
    self:IncrementStackCount()
end

function modifier_dawnbreaker_solar_hammer_nohammer:OnRefresh( kv )
    self:OnCreated( kv )
end

function modifier_dawnbreaker_solar_hammer_nohammer:OnRemoved()
end

function modifier_dawnbreaker_solar_hammer_nohammer:OnDestroy()
    if not IsServer() then return end
end

--------------------------------------------------------------------------------
-- Other
function modifier_dawnbreaker_solar_hammer_nohammer:Decrement()
    self:DecrementStackCount()
    if self:GetStackCount()<1 then
        self:Destroy()
    end
end
--
dawnbreaker_solar_hammer_replace = class({})

function dawnbreaker_solar_hammer_replace:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()

    local main = caster:FindAbilityByName( "dawnbreaker_solar_hammer" )
    if main then
        main:Converge()
    end

    -- set as inactive
    self:SetActivated( false )
end
-----
function modifier_dawnbreaker_solar_hammer_emitter:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()

    self.caster = caster
    self.radius = params.radius
    self.duration = params.duration
    self.heal = params.heal
    self.interval = params.interval
    self.damage = params.damage

    self.aura_modifier_name = "modifier_dawnbreaker_solar_hammer_emitter_aura_ally"
    self.allyAura = "modifier_dawnbreaker_solar_hammer_emitter_aura_ally"
    self.enemyAura = "modifier_dawnbreaker_solar_hammer_emitter_aura"

    -- Start the thinker to drain hp/do damage --
    self:StartIntervalThink(self.interval)
    self:OnIntervalThink()
end

function modifier_dawnbreaker_solar_hammer_emitter:PlayEffects3( point, radius )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_solar_guardian_damage.vpcf"
    local sound_cast = "Hero_Dawnbreaker.Solar_Guardian.Damage"

    -- Get Data
    local point = GetGroundPosition( point, self.caster )

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self.caster )
    ParticleManager:SetParticleControl( effect_cast, 0, self.caster:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, point )
    ParticleManager:SetParticleControl( effect_cast, 2, Vector( self.radius, self.radius, self.radius ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOnLocationWithCaster( point, sound_cast, self.caster )
end

function modifier_dawnbreaker_solar_hammer_emitter:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    self:PlayEffects3(parent:GetAbsOrigin(), self.radius)

    local units = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if unit:GetTeamNumber() == parent:GetTeamNumber() then
            local amount = unit:GetMaxHealth() * (self.heal/100)
            unit:SetHealth(unit:GetHealth() + amount)
            SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, amount, nil)
        else
            if unit:IsMagicImmune() then break end
            ApplyDamage({
                victim = unit, 
                attacker = caster, 
                damage = self.damage + (self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("str_to_damage")/100)), 
                ability = self:GetAbility(),
                damage_type = DAMAGE_TYPE_MAGICAL
            })
        end
    end
end

function modifier_dawnbreaker_solar_hammer_emitter:OnDestroy()
    if not IsServer() then return end

    self:GetParent():ForceKill(false)
end

function modifier_dawnbreaker_solar_hammer_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true
    }   

    return state
end

function modifier_dawnbreaker_solar_hammer_emitter:IsAura()
  return true
end

function modifier_dawnbreaker_solar_hammer_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_dawnbreaker_solar_hammer_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_dawnbreaker_solar_hammer_emitter:GetAuraRadius()
  return self.radius
end

function modifier_dawnbreaker_solar_hammer_emitter:GetModifierAura()
    return self.aura_modifier_name
end

function modifier_dawnbreaker_solar_hammer_emitter:GetAuraEntityReject(target) 
    if target:GetTeamNumber() == self.caster:GetTeamNumber() and self.caster:HasModifier("modifier_dawnbreaker_daybreak_active_buff") then
        if not target:IsRealHero() then return true end
        self.aura_modifier_name = self.allyAura
        return false
    elseif target:GetTeamNumber() ~= self.caster:GetTeamNumber() then
        if target:IsMagicImmune() then return true end

        self.aura_modifier_name = self.enemyAura
        return false
    end
    
    return true
end
--------------
function modifier_dawnbreaker_solar_hammer_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE ,
        MODIFIER_PROPERTY_MISS_PERCENTAGE
    }

    return funcs
end

function modifier_dawnbreaker_solar_hammer_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("move_speed_slow_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_dawnbreaker_solar_hammer_emitter_aura:GetModifierMiss_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("miss_chance_pct", (self:GetAbility():GetLevel() - 1))
end
----
function modifier_dawnbreaker_solar_hammer_emitter_aura_ally:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local daybreak = caster:FindAbilityByName("dawnbreaker_daybreak")

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    self.reduction = 0

    if not daybreak or daybreak:GetLevel() < 1 then return end

    self.reduction = daybreak:GetSpecialValueFor("solar_hammer_damage_reduction")

    _G.PlayerDamageReduction[self.accountID][abilityName] = self.reduction
end

function modifier_dawnbreaker_solar_hammer_emitter_aura_ally:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end