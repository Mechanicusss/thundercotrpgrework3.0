viper_viper_strike_custom = class({})
LinkLuaModifier( "modifier_viper_viper_strike_custom", "heroes/hero_viper/viper_viper_strike_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_viper_viper_strike_custom_debuff", "heroes/hero_viper/viper_viper_strike_custom.lua", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

modifier_viper_viper_strike_custom_debuff = class(ItemBaseClassDebuff)
--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function viper_viper_strike_custom:GetAOERadius()
    return self:GetSpecialValueFor( "radius" )
end

function viper_viper_strike_custom:GetCastRange( vLocation, hTarget )
    if self:GetCaster():HasScepter() then
        return self:GetSpecialValueFor( "cast_range_scepter" )
    end

    return self.BaseClass.GetCastRange( self, vLocation, hTarget )
end

function viper_viper_strike_custom:GetCooldown( level )
    if self:GetCaster():HasScepter() then
        return self:GetSpecialValueFor( "cooldown_scepter" )
    end

    return self.BaseClass.GetCooldown( self, level )
end

function viper_viper_strike_custom:GetManaCost( level )
    if self:GetCaster():HasScepter() then
        return self:GetSpecialValueFor( "mana_cost_scepter" )
    end

    return self.BaseClass.GetManaCost( self, level )
end

--------------------------------------------------------------------------------
-- Ability Start
function viper_viper_strike_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    -- load data
    -- local projectile_name = "particles/units/heroes/hero_viper/viper_viper_strike.vpcf"
    local projectile_name = ""
    local projectile_speed = self:GetSpecialValueFor( "projectile_speed" )

    -- Play Effects
    local effect = self:PlayEffects( target )

    -- create projectile
    local info = {
        Target = target,
        Source = caster,
        Ability = self, 
        
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bDodgeable = true,                           -- Optional

        ExtraData = {
            effect = effect,
        }
    }
    ProjectileManager:CreateTrackingProjectile(info)

end
--------------------------------------------------------------------------------
-- Projectile
function viper_viper_strike_custom:OnProjectileHit_ExtraData( target, location, ExtraData )
    -- stop effects
    self:StopEffects( ExtraData.effect )

    if not target then return end

    -- cancel if linken
    if target:TriggerSpellAbsorb( self ) then return end

    -- references
    local duration = self:GetSpecialValueFor( "duration" )

    -- add debuff
    target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_viper_viper_strike_custom", -- modifier name
        { duration = duration } -- kv
    )

    -- play sound
    local sound_cast = "hero_viper.viperStrikeImpact"
    EmitSoundOn( sound_cast, target )
end

--------------------------------------------------------------------------------
function viper_viper_strike_custom:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_viper/viper_viper_strike_beam.vpcf"
    local sound_cast = "hero_viper.viperStrike"

    -- Get Data
    local projectile_speed = self:GetSpecialValueFor( "projectile_speed" )

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 6, Vector( projectile_speed, 0, 0 ) )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    -- "attach_barb<1/2/3/4>" is unique to viper model, so use something else
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        2,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        3,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        4,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_attack2",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        5,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_attack3",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    -- ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )

    -- return the particle index
    return effect_cast
end

function viper_viper_strike_custom:StopEffects( effect_cast )
    ParticleManager:DestroyParticle( effect_cast, false )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

modifier_viper_viper_strike_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_viper_viper_strike_custom:IsHidden()
    return false
end

function modifier_viper_viper_strike_custom:IsDebuff()
    return true
end

function modifier_viper_viper_strike_custom:IsStunDebuff()
    return false
end

function modifier_viper_viper_strike_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_viper_viper_strike_custom:OnCreated( kv )
    -- references
    self.as_slow = self:GetAbility():GetSpecialValueFor( "bonus_attack_speed" )
    self.ms_slow = self:GetAbility():GetSpecialValueFor( "bonus_movement_speed" )
    local damage = self:GetAbility():GetSpecialValueFor( "damage" )

    self.start_time = GameRules:GetGameTime()
    self.duration = kv.duration

    if not IsServer() then return end
    -- precache damage
    self.damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = damage + (self:GetCaster():GetAgility() * (self:GetAbility():GetSpecialValueFor("agility_to_damage")/100)),
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(), --Optional.
    }
    -- ApplyDamage(damageTable)

    -- Start interval
    self:StartIntervalThink( 1 )
    self:OnIntervalThink()
end

function modifier_viper_viper_strike_custom:OnRefresh( kv )
    -- references
    self.as_slow = self:GetAbility():GetSpecialValueFor( "bonus_attack_speed" )
    self.ms_slow = self:GetAbility():GetSpecialValueFor( "bonus_movement_speed" )
    local damage = self:GetAbility():GetSpecialValueFor( "damage" )

    self.start_time = GameRules:GetGameTime()
    self.duration = kv.duration
    
    if not IsServer() then return end
    -- update damage
    self.damageTable.damage = damage

    -- restart interval tick
    self:StartIntervalThink( 1 )
    self:OnIntervalThink()
end

function modifier_viper_viper_strike_custom:OnRemoved()
end

function modifier_viper_viper_strike_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_viper_viper_strike_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }

    return funcs
end

function modifier_viper_viper_strike_custom:GetModifierMoveSpeedBonus_Percentage()
    return self.ms_slow * ( 1 - ( GameRules:GetGameTime()-self.start_time )/self.duration )
end
function modifier_viper_viper_strike_custom:GetModifierAttackSpeedBonus_Constant()
    return self.as_slow * ( 1 - ( GameRules:GetGameTime()-self.start_time )/self.duration )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_viper_viper_strike_custom:OnIntervalThink()
    ApplyDamage( self.damageTable )
    self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_viper_viper_strike_custom_debuff", {
        duration = self:GetAbility():GetSpecialValueFor("duration")
    })
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_viper_viper_strike_custom:GetEffectName()
    return "particles/units/heroes/hero_viper/viper_viper_strike_debuff.vpcf"
end

function modifier_viper_viper_strike_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_viper_viper_strike_custom:GetStatusEffectName()
    return "particles/status_fx/status_effect_poison_viper.vpcf"
end

function modifier_viper_viper_strike_custom:StatusEffectPriority()
    return MODIFIER_PRIORITY_HIGH
end