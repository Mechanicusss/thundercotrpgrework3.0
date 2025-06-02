lion_earth_spike_custom = class({})
LinkLuaModifier( "modifier_generic_stunned_lua", "modifiers/modifier_generic_stunned_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_knockback_lua", "modifiers/modifier_generic_knockback_lua", LUA_MODIFIER_MOTION_BOTH )

--------------------------------------------------------------------------------
-- Ability Start
function lion_earth_spike_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local point = self:GetCursorPosition()

    -- load data
    if target then
        point = target:GetOrigin()
    end

    function CreateSpike(loc)
        local projectile_name = "particles/units/heroes/hero_lion/lion_spell_impale.vpcf"
        local projectile_distance = self:GetCastRange( loc, caster )
        local projectile_radius = self:GetSpecialValueFor( "width" )
        local projectile_speed = self:GetSpecialValueFor( "speed" )
        local projectile_direction = (loc-caster:GetOrigin()):Normalized()
        local info = {
            Source = caster,
            Ability = self,
            vSpawnOrigin = caster:GetAbsOrigin(),
            
            bDeleteOnHit = false,
            
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_CREEP),
            
            EffectName = projectile_name,
            fDistance = projectile_distance,
            fStartRadius = projectile_radius,
            fEndRadius = projectile_radius,
            vVelocity = projectile_direction * projectile_speed,
        }
        ProjectileManager:CreateLinearProjectile(info)
    end

    CreateSpike(Vector(point.x-200, point.y-200, point.z))
    CreateSpike(Vector(point.x-100, point.y-100, point.z))
    CreateSpike(point)
    CreateSpike(Vector(point.x+100, point.y+100, point.z))
    CreateSpike(Vector(point.x+200, point.y+200, point.z))

    -- play effects
    local sound_cast = "Hero_Lion.Impale"
    EmitSoundOn( sound_cast, caster )
end

--------------------------------------------------------------------------------
-- Projectile
function lion_earth_spike_custom:OnProjectileHit( target, location )
    if not target then return end
    if target:TriggerSpellAbsorb( self ) then return end

    local stun = self:GetSpecialValueFor( "duration" )
    local damage = self:GetAbilityDamage()

    damage = damage + (self:GetCaster():GetBaseIntellect() * (self:GetSpecialValueFor("int_damage")/100))

    local damageTable = {
        victim = target,
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }

    -- stun
    target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_generic_stunned_lua", -- modifier name
        { duration = stun } -- kv
    )

    -- knockback
    local knockback = target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_generic_knockback_lua", -- modifier name
        {
            duration = 0.5,
            height = 350,
        } -- kv
    )
    local callback = function()
        -- damage on landed
        local damageTable = {
            victim = target,
            attacker = self:GetCaster(),
            damage = damage,
            damage_type = self:GetAbilityDamageType(),
            ability = self, --Optional.
        }
        ApplyDamage(damageTable)

        -- play effects
        local sound_cast = "Hero_Lion.ImpaleTargetLand"
        EmitSoundOn( sound_cast, target )
    end
    knockback:SetEndCallback( callback )

    -- play effects
    self:PlayEffects( target )
end

--------------------------------------------------------------------------------
function lion_earth_spike_custom:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_lion/lion_spell_impale_hit_spikes.vpcf"
    local sound_cast = "Hero_Lion.ImpaleHitTarget"

    -- Get Data

    -- -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end