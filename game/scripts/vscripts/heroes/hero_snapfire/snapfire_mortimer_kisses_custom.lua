LinkLuaModifier("modifier_snapfire_mortimer_kisses_custom", "heroes/hero_snapfire/snapfire_mortimer_kisses_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_snapfire_mortimer_kisses_custom_thinker", "heroes/hero_snapfire/snapfire_mortimer_kisses_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_snapfire_mortimer_kisses_custom_debuff", "heroes/hero_snapfire/snapfire_mortimer_kisses_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStunDebuff = function(self) return false end,
}

snapfire_mortimer_kisses_custom = class(ItemBaseClass)
modifier_snapfire_mortimer_kisses_custom = class(snapfire_mortimer_kisses_custom)
modifier_snapfire_mortimer_kisses_custom_thinker = class(snapfire_mortimer_kisses_custom)
modifier_snapfire_mortimer_kisses_custom_debuff = class(ItemBaseDebuffClass)
-------------
function snapfire_mortimer_kisses_custom:GetIntrinsicModifierName()
    return "modifier_snapfire_mortimer_kisses_custom"
end

function snapfire_mortimer_kisses_custom:OnProjectileHit( target, location )
    if not target then return end

    -- load data
    local damage = self:GetSpecialValueFor( "damage_per_impact" )
    local damageFromAttack = self:GetSpecialValueFor( "damage_from_attack" )
    local duration = self:GetSpecialValueFor( "burn_ground_duration" )
    local impact_radius = self:GetSpecialValueFor( "impact_radius" )
    local vision = self:GetSpecialValueFor( "projectile_vision" )

    -- precache damage
    local damageTable = {
        -- victim = target,
        attacker = self:GetCaster(),
        damage = damage + (self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster()) * (damageFromAttack/100)),
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }

    local enemies = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(),   -- int, your team number
        location,   -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        impact_radius,  -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        damageTable.victim = enemy
        ApplyDamage(damageTable)
    end

    -- start aura on thinker
    target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_snapfire_mortimer_kisses_custom_thinker", -- modifier name
        {
            duration = duration,
            slow = 1,
        } -- kv
    )

    -- destroy trees
    GridNav:DestroyTreesAroundPoint( location, impact_radius, true )

    -- create Vision
    AddFOWViewer( self:GetCaster():GetTeamNumber(), location, vision, duration, false )

    -- play effects
    self:PlayEffects( target:GetOrigin() )
end

function snapfire_mortimer_kisses_custom:PlayEffects(loc)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_impact.vpcf"
    local particle_cast2 = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_linger.vpcf"
    local sound_cast = "Hero_Snapfire.MortimerBlob.Impact"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 3, loc )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    local effect_cast = ParticleManager:CreateParticle( particle_cast2, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, loc )
    ParticleManager:SetParticleControl( effect_cast, 1, loc )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    local sound_location = "Hero_Snapfire.MortimerBlob.Impact"
    EmitSoundOnLocationWithCaster( loc, sound_location, self:GetCaster() )
end
------------
function modifier_snapfire_mortimer_kisses_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_snapfire_mortimer_kisses_custom:OnAttack(event)
    if not IsServer() then return end

    local caster = self:GetCaster()

    if event.attacker ~= caster then return end

    local ability = self:GetAbility()
    local target = event.target

    if caster:PassivesDisabled() then return end
    if not ability or ability:IsNull() then return end
    if not target or target:IsNull() then return end
    if not target:IsBaseNPC() then return end
    if not target:IsAlive() or target:IsOther() or target:IsBuilding() or ability:GetLevel() < 1 or not ability:IsCooldownReady() then return end -- Can't target wards, buildings or dead units

    local chance = ability:GetSpecialValueFor("chance_pct")

    if RollPercentage(chance) then
        ability:UseResources(false, false, false, true)

        local projectile_name = "particles/units/heroes/hero_snapfire/snapfire_lizard_blobs_arced.vpcf"
        local projectile_start_radius = 0
        local projectile_end_radius = 0

        local vec = target:GetOrigin() - caster:GetOrigin()
        
        self.travel_time = (vec:Length2D()-self.min_range)/self.range * self.travel_range + self.min_travel

        -- precache projectile
        self.info = {
            Target = target,
            Source = caster,
            Ability = ability,    
            
            EffectName = projectile_name,
            iMoveSpeed = self.projectile_speed,
            bDodgeable = false,                           -- Optional
        
            vSourceLoc = caster:GetOrigin(),                -- Optional (HOW)
            
            bDrawsOnMinimap = false,                          -- Optional
            bVisibleToEnemies = true,                         -- Optional
            bProvidesVision = true,                           -- Optional
            iVisionRadius = self.projectile_vision,                              -- Optional
            iVisionTeamNumber = caster:GetTeamNumber()        -- Optional
        }

        local thinker = CreateModifierThinker(
            caster, -- player source
            ability, -- ability source
            "modifier_snapfire_mortimer_kisses_custom_thinker", -- modifier name
            { travel_time = self.travel_time, radius = self.radius, max_travel = self.max_travel, linger = self.linger }, -- kv
            target:GetAbsOrigin(),
            caster:GetTeamNumber(),
            false
        )

        -- set projectile
        self.info.iMoveSpeed = vec:Length2D()/self.travel_time
        self.info.Target = thinker

        -- launch projectile
        ProjectileManager:CreateTrackingProjectile(self.info)

        -- create FOW
        AddFOWViewer(target:GetTeamNumber(), target:GetOrigin(), 100, 1, false)

        local sound_cast = "Hero_Snapfire.MortimerBlob.Launch"
        EmitSoundOn(sound_cast, caster)
    end
end

function modifier_snapfire_mortimer_kisses_custom:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if not ability or ability:IsNull() then return end

    if not ability or ability:IsNull() then return end

    self.min_range = ability:GetSpecialValueFor( "min_range" )
    self.max_range = ability:GetCastRange( Vector(0,0,0), nil )
    self.range = self.max_range - self.min_range
    
    self.min_travel = ability:GetSpecialValueFor( "min_lob_travel_time" )
    self.max_travel = ability:GetSpecialValueFor( "max_lob_travel_time" )
    self.travel_range = self.max_travel - self.min_travel
    
    self.projectile_speed = ability:GetSpecialValueFor( "projectile_speed" )
    self.projectile_vision = ability:GetSpecialValueFor( "projectile_vision" )
    self.burn_ground_duration = ability:GetSpecialValueFor("burn_ground_duration")

    self.radius = ability:GetSpecialValueFor( "impact_radius" )
    self.linger = ability:GetSpecialValueFor( "burn_linger_duration" )
    
    self.turn_rate = ability:GetSpecialValueFor("turn_rate")
end
---------
function modifier_snapfire_mortimer_kisses_custom_thinker:IsAura()
    return self.start
end

function modifier_snapfire_mortimer_kisses_custom_thinker:GetModifierAura()
    return "modifier_snapfire_mortimer_kisses_custom_debuff"
end

function modifier_snapfire_mortimer_kisses_custom_thinker:GetAuraRadius()
    return self.radius
end

function modifier_snapfire_mortimer_kisses_custom_thinker:GetAuraDuration()
    return self.linger
end

function modifier_snapfire_mortimer_kisses_custom_thinker:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_snapfire_mortimer_kisses_custom_thinker:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_snapfire_mortimer_kisses_custom_thinker:OnCreated(params)
    if not IsServer() then return end

    self.radius = params.radius
    self.max_travel = params.max_travel
    self.travel_time = params.travel_time
    self.linger = params.linger

    local particle_cast = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_calldown.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticleForTeam(particle_cast, PATTACH_CUSTOMORIGIN, self:GetParent(), self:GetCaster():GetTeamNumber())
    ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin())
    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( self.radius, 0, -self.radius*(self.max_travel/self.travel_time) ) )
    ParticleManager:SetParticleControl( self.effect_cast, 2, Vector( self.travel_time, 0, 0 ) )

    self.start = false

    Timers:CreateTimer(self.travel_time, function()
        self.start = true
        ParticleManager:DestroyParticle( self.effect_cast, true )
        ParticleManager:ReleaseParticleIndex( self.effect_cast )
    end)
end

function modifier_snapfire_mortimer_kisses_custom_thinker:OnRemoved()
end

function modifier_snapfire_mortimer_kisses_custom_thinker:OnDestroy()
    if not IsServer() then return end

    UTIL_Remove(self:GetParent())
end
---------
function modifier_snapfire_mortimer_kisses_custom_debuff:OnCreated()
    -- references
    self.slow = -self:GetAbility():GetSpecialValueFor( "move_slow_pct" )

    local interval = self:GetAbility():GetSpecialValueFor( "burn_interval" )
    
    if not IsServer() then return end

    self.dps = self:GetAbility():GetSpecialValueFor( "burn_damage" ) + (self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster()) * (self:GetAbility():GetSpecialValueFor( "damage_from_attack" )/100))

    -- precache damage
    self.damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.dps*interval,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(), --Optional.
    }

    -- Start interval
    self:StartIntervalThink( interval )
    self:OnIntervalThink()
end

function modifier_snapfire_mortimer_kisses_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_snapfire_mortimer_kisses_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

function modifier_snapfire_mortimer_kisses_custom_debuff:OnIntervalThink()
    -- apply damage
    ApplyDamage( self.damageTable )

    -- play overhead
end

function modifier_snapfire_mortimer_kisses_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_snapfire/hero_snapfire_burn_debuff.vpcf"
end

function modifier_snapfire_mortimer_kisses_custom_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_snapfire_mortimer_kisses_custom_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_snapfire_magma.vpcf"
end

function modifier_snapfire_mortimer_kisses_custom_debuff:StatusEffectPriority()
    return MODIFIER_PRIORITY_NORMAL
end