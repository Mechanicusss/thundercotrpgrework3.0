LinkLuaModifier("modifier_follower_spider_burrow", "heroes/bosses/spider/follower_spider_burrow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_generic_stunned_lua", "modifiers/modifier_generic_stunned_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_knockback_lua", "modifiers/modifier_generic_knockback_lua", LUA_MODIFIER_MOTION_BOTH )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

follower_spider_burrow = class(ItemBaseClass)
modifier_follower_spider_burrow = class(ItemBaseClass)
-------------
function follower_spider_burrow:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    local _t = nil
    for _,victim in ipairs(victims) do
        if victim:IsAlive() and not victim:IsMagicImmune() then
            _t = victim
            break
        end
    end

    if not _t then return end

    local origin = caster:GetAbsOrigin()
    local point = _t:GetAbsOrigin()

    caster:SetForwardVector(point)

    -- load data
    local anim_time = self:GetSpecialValueFor("burrow_anim_time")

    -- projectile data
    local projectile_name = "particles/units/heroes/hero_sandking/sandking_burrowstrike.vpcf"
    local projectile_start_radius = self:GetSpecialValueFor("burrow_width")
    local projectile_end_radius = projectile_start_radius
    local projectile_direction = (point-origin)
    projectile_direction.z = 0
    projectile_direction:Normalized()
    local projectile_speed = self:GetSpecialValueFor("burrow_speed")
    local projectile_distance = (point-origin):Length2D()

    -- create projectile
    local info = {
        Source = caster,
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin(),
        
        bDeleteOnHit = false,
        
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        
        EffectName = projectile_name,
        fDistance = projectile_distance,
        fStartRadius = projectile_start_radius,
        fEndRadius =projectile_end_radius,
        vVelocity = projectile_direction * projectile_speed,
    }

    ProjectileManager:CreateLinearProjectile(info)

    -- add modifier to caster
    caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_follower_spider_burrow", -- modifier name
        { 
            duration = anim_time,
            pos_x = point.x,
            pos_y = point.y,
            pos_z = point.z,
        } -- kv
    )

    self:PlayEffects( origin, point )
end

function follower_spider_burrow:OnProjectileHit( target, location )
    if not target then return end

    -- cancel if linken
    if target:TriggerSpellAbsorb( self ) then return end

    -- apply stun
    local duration = self:GetSpecialValueFor( "burrow_duration" )
    target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_generic_stunned_lua", -- modifier name
        { duration = duration } -- kv
    )

    -- apply knockback
    target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_generic_knockback_lua", -- modifier name
        {
            duration = 0.52,
            z = 350,
            IsStun = true,
        } -- kv
    )

    -- apply damage
    local damageTable = {
        victim = target,
        attacker = self:GetCaster(),
        damage = self:GetAbilityDamage(),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self, --Optional.
    }
    ApplyDamage(damageTable)
end

--------------------------------------------------------------------------------
function follower_spider_burrow:PlayEffects( origin, target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_sandking/sandking_burrowstrike.vpcf"
    local sound_cast = "Ability.SandKing_BurrowStrike"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, origin )
    ParticleManager:SetParticleControl( effect_cast, 1, target )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )
end

function modifier_follower_spider_burrow:OnCreated( kv )
    if IsServer() then
        -- references
        self.point = Vector( kv.pos_x, kv.pos_y, kv.pos_z )

        -- Start interval
        self:StartIntervalThink( self:GetDuration()/2 )

        self:GetParent():AddNoDraw()
    end
end

function modifier_follower_spider_burrow:OnDestroy( kv )
    if not IsServer() then return end
    self:GetParent():RemoveNoDraw()
end

function modifier_follower_spider_burrow:OnIntervalThink()
    FindClearSpaceForUnit( self:GetParent(), self.point, true )
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_follower_spider_burrow:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
    }

    return state
end