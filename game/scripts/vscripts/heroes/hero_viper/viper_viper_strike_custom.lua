viper_viper_strike_custom = class({})
LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_viper_viper_strike_custom", "heroes/hero_viper/viper_viper_strike_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_viper_viper_strike_custom_debuff", "heroes/hero_viper/viper_viper_strike_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_obsidian_essence_flux", "heroes/hero_viper/obsidian_essence_flux.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

modifier_viper_viper_strike_custom_debuff = class(ItemBaseClassDebuff)
--------------------------------------------------------------------------------
-- Passive Modifier
function viper_viper_strike_custom:GetIntrinsicModifierName()
    return "modifier_generic_orb_effect_lua"
end

--------------------------------------------------------------------------------
-- Ability Start
function viper_viper_strike_custom:OnSpellStart()
end
--------------------------------------------------------------------------------
-- Orb Effects
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

function viper_viper_strike_custom:OnOrbFire( params )
    -- play effects
    self.effect = self:PlayEffects(params.target)
end

function viper_viper_strike_custom:OnOrbImpact( params )
    local caster = self:GetCaster()

    local target = params.target 
    
    local debuff = target:FindModifierByName("modifier_viper_viper_strike_custom_debuff")
    if not debuff then
        debuff = target:AddNewModifier(caster, self, "modifier_viper_viper_strike_custom_debuff", { duration = self:GetSpecialValueFor("duration") })
    end

    if debuff then
        debuff:ForceRefresh()
    end

    -- play effects
    local sound_cast = "hero_viper.viperStrikeImpact"
    EmitSoundOn( sound_cast, params.target )

    ParticleManager:DestroyParticle( self.effect, false )
    ParticleManager:ReleaseParticleIndex( self.effect )
end
-------------------
function modifier_viper_viper_strike_custom_debuff:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(1)
end

function modifier_viper_viper_strike_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local damage = (ability:GetSpecialValueFor("damage") + (caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("damage_from_attack")/100)))

    if parent:IsMagicImmune() then return end

    if parent:HasModifier("modifier_viper_viper_strike_custom_debuff") and caster:HasScepter() then
        damage = damage * ability:GetSpecialValueFor("damage_multiplier")
    end
    
    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, parent, damage, nil)
end

function modifier_viper_viper_strike_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_DISABLE_HEALING,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_viper_viper_strike_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_viper_viper_strike_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_resistance_reduction")
end

function modifier_viper_viper_strike_custom_debuff:GetDisableHealing()
    return 1
end

function modifier_viper_viper_strike_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_viper/viper_viper_strike_debuff.vpcf"
end
