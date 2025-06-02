phantom_assassin_daggers = class({})
LinkLuaModifier( "modifier_phantom_assassin_daggers", "heroes/hero_phantom_assassin/phantom_assassin_daggers", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_phantom_assassin_daggers_attack", "heroes/hero_phantom_assassin/phantom_assassin_daggers", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_phantom_assassin_daggers_intrin", "heroes/hero_phantom_assassin/phantom_assassin_daggers", LUA_MODIFIER_MOTION_NONE )

modifier_phantom_assassin_daggers_intrin = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

--------------------------------------------------------------------------------
-- Ability Start
function modifier_phantom_assassin_daggers_intrin:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(0.1)
end

function modifier_phantom_assassin_daggers_intrin:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not parent:HasModifier("modifier_item_aghanims_shard") then return end
    if not ability:GetAutoCastState() then return end

    if not parent:IsStunned() and not parent:IsSilenced() and not parent:IsHexed() and parent:GetMana() >= ability:GetManaCost(-1) and ability:IsCooldownReady() and ability:IsFullyCastable() then
        SpellCaster:Cast(ability, parent, true)
    end
end

function phantom_assassin_daggers:GetIntrinsicModifierName()
    return "modifier_phantom_assassin_daggers_intrin"
end

function phantom_assassin_daggers:GetBehavior()
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_item_aghanims_shard") then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_AUTOCAST
    else
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET
    end
end

function phantom_assassin_daggers:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        -- get projectile_data
        local projectile_name = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf"
        local projectile_speed = self:GetSpecialValueFor("dagger_speed")
        local projectile_vision = 450

        -- Create Projectile
        local info = {
            Target = victim,
            Source = caster,
            Ability = self, 
            EffectName = projectile_name,
            iMoveSpeed = projectile_speed,
            bReplaceExisting = false,                         -- Optional
            bProvidesVision = true,                           -- Optional
            iVisionRadius = projectile_vision,              -- Optional
            iVisionTeamNumber = caster:GetTeamNumber()        -- Optional
        }
        ProjectileManager:CreateTrackingProjectile(info)

        self:PlayEffects1()
    end
end

function phantom_assassin_daggers:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function phantom_assassin_daggers:OnProjectileHit( hTarget, vLocation )
    local target = hTarget
    if target==nil then return end
    if target:IsInvulnerable() or target:IsMagicImmune() then return end
    if target:TriggerSpellAbsorb( self ) then return end
    
    local modifier = self:GetCaster():AddNewModifier(
        self:GetCaster(),
        self,
        "modifier_phantom_assassin_daggers_attack",
        {}
    )
    self:GetCaster():PerformAttack (
        hTarget,
        true,
        true,
        true,
        false,
        false,
        false,
        true
    )
    modifier:Destroy()

    hTarget:AddNewModifier(
        self:GetCaster(),
        self,
        "modifier_phantom_assassin_daggers",
        {duration = self:GetDuration()}
    )

    self:PlayEffects2( hTarget )
end

--------------------------------------------------------------------------------
function phantom_assassin_daggers:PlayEffects1()
    -- Get Resources
    local sound_cast = "Hero_PhantomAssassin.Dagger.Cast"

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )
end

function phantom_assassin_daggers:PlayEffects2( target )
    -- Get Resources
    local sound_target = "Hero_PhantomAssassin.Dagger.Target"

    -- Create Sound
    EmitSoundOn( sound_target, target )
end

modifier_phantom_assassin_daggers = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_phantom_assassin_daggers:IsHidden()
    return false
end

function modifier_phantom_assassin_daggers:IsDebuff()
    return true
end

function modifier_phantom_assassin_daggers:IsStunDebuff()
    return false
end

function modifier_phantom_assassin_daggers:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_phantom_assassin_daggers:OnCreated( kv )
    -- references
    self.move_slow = self:GetAbility():GetSpecialValueFor( "move_slow" )
end

function modifier_phantom_assassin_daggers:OnRefresh( kv )
    -- references
    self.move_slow = self:GetAbility():GetSpecialValueFor( "move_slow" )    
end

function modifier_phantom_assassin_daggers:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_phantom_assassin_daggers:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_phantom_assassin_daggers:GetModifierMoveSpeedBonus_Percentage()
    return self.move_slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_phantom_assassin_daggers:GetEffectName()
    return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger_debuff.vpcf"
end

function modifier_phantom_assassin_daggers:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

modifier_phantom_assassin_daggers_attack = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_phantom_assassin_daggers_attack:IsHidden()
    return true
end
function modifier_phantom_assassin_daggers_attack:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_phantom_assassin_daggers_attack:OnCreated( kv )
    -- references
    self.base_damage = self:GetAbility():GetSpecialValueFor( "base_damage" )    
    self.attack_factor = self:GetAbility():GetSpecialValueFor( "attack_factor" )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_phantom_assassin_daggers_attack:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,

    }

    return funcs
end

function modifier_phantom_assassin_daggers_attack:GetModifierDamageOutgoing_Percentage( params )
    if IsServer() then
        return self.attack_factor
    end
end
function modifier_phantom_assassin_daggers_attack:GetModifierPreAttack_BonusDamage( params )
    if IsServer() then
        -- base damage will get reduced, so multiply it by its inverse
        return self.base_damage * 100/(100+self.attack_factor)
    end
end