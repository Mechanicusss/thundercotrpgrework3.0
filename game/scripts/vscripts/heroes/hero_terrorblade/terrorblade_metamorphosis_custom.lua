terrorblade_metamorphosis_custom = class({})
LinkLuaModifier( "modifier_terrorblade_metamorphosis_custom", "heroes/hero_terrorblade/terrorblade_metamorphosis_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_terrorblade_metamorphosis_custom_aura", "heroes/hero_terrorblade/terrorblade_metamorphosis_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Init Abilities
function terrorblade_metamorphosis_custom:Precache( context )
    PrecacheModel( "models/heroes/terrorblade/demon.vmdl", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_terrorblade.vsndevts", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_transform.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf", context )
end

--------------------------------------------------------------------------------
-- Ability Start
function terrorblade_metamorphosis_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()

    -- load data
    local duration = self:GetSpecialValueFor( "duration" )

    -- add modifier
    caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_terrorblade_metamorphosis_custom_aura", -- modifier name
        { duration = duration } -- kv
    )
end

modifier_terrorblade_metamorphosis_custom_aura = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_terrorblade_metamorphosis_custom_aura:IsHidden()
    return false
end

function modifier_terrorblade_metamorphosis_custom_aura:IsDebuff()
    return false
end

function modifier_terrorblade_metamorphosis_custom_aura:IsStunDebuff()
    return false
end

function modifier_terrorblade_metamorphosis_custom_aura:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_terrorblade_metamorphosis_custom_aura:OnCreated( kv )
    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "metamorph_aura_tooltip" )

    if not IsServer() then return end
end

function modifier_terrorblade_metamorphosis_custom_aura:OnRefresh( kv )
    self:OnCreated( kv )
end

function modifier_terrorblade_metamorphosis_custom_aura:OnRemoved()
    if not IsServer() then return end
end

function modifier_terrorblade_metamorphosis_custom_aura:OnDestroy()
end

--------------------------------------------------------------------------------
-- Aura Effects
function modifier_terrorblade_metamorphosis_custom_aura:IsAura()
    return true
end

function modifier_terrorblade_metamorphosis_custom_aura:GetModifierAura()
    return "modifier_terrorblade_metamorphosis_custom"
end

function modifier_terrorblade_metamorphosis_custom_aura:GetAuraRadius()
    return self.radius
end

function modifier_terrorblade_metamorphosis_custom_aura:GetAuraDuration()
    return 1
end

function modifier_terrorblade_metamorphosis_custom_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_terrorblade_metamorphosis_custom_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_terrorblade_metamorphosis_custom_aura:GetAuraSearchFlags()
    return 0
end

function modifier_terrorblade_metamorphosis_custom_aura:GetAuraEntityReject( hEntity )
    if IsServer() then
        if hEntity:GetPlayerOwnerID()~=self:GetParent():GetPlayerOwnerID() then
            return true
        end
    end

    return false
end

modifier_terrorblade_metamorphosis_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_terrorblade_metamorphosis_custom:IsHidden()
    return false
end

function modifier_terrorblade_metamorphosis_custom:IsDebuff()
    return false
end

function modifier_terrorblade_metamorphosis_custom:IsStunDebuff()
    return false
end

function modifier_terrorblade_metamorphosis_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_terrorblade_metamorphosis_custom:OnCreated( kv )
    -- references
    self.bat = self:GetAbility():GetSpecialValueFor( "base_attack_time" )
    self.range = self:GetAbility():GetSpecialValueFor( "bonus_range" )
    self.damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
    self.slow = self:GetAbility():GetSpecialValueFor( "speed_loss" )
    local delay = self:GetAbility():GetSpecialValueFor( "transformation_time" )

    self.projectile = 900

    if not IsServer() then return end

    -- melee/ranged
    self.attack = self:GetParent():GetAttackCapability()
    if self.attack == DOTA_UNIT_CAP_RANGED_ATTACK then
        -- no bonus for originally ranged enemies
        self.range = 0
        self.projectile = 0
    end
    self:GetParent():SetAttackCapability( DOTA_UNIT_CAP_RANGED_ATTACK )

    -- gesture
    self:GetAbility():SetContextThink(DoUniqueString( "terrorblade_metamorphosis_custom" ), function()
        self:GetParent():StartGesture( ACT_DOTA_CAST_ABILITY_3 )
    end, FrameTime())

    -- transform time
    self.stun = true
    self:StartIntervalThink( delay )

    -- play effects
    self:PlayEffects()
end

function modifier_terrorblade_metamorphosis_custom:OnRefresh( kv )
    self:OnCreated( kv )
end

function modifier_terrorblade_metamorphosis_custom:OnRemoved()
end

function modifier_terrorblade_metamorphosis_custom:OnDestroy()
    if not IsServer() then return end

    -- return attack cap
    self:GetParent():SetAttackCapability( self.attack )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_terrorblade_metamorphosis_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,

        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,

        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,

        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE
    }

    return funcs
end

function modifier_terrorblade_metamorphosis_custom:GetModifierProcAttack_BonusDamage_Pure(params)
    if IsServer() then
        -- get target
        local target = params.target if target==nil then target = params.unit end
        if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
            return 0
        end

        if not self:GetParent():HasScepter() then return 0 end

        local ability = self:GetAbility()

        local damageConversion = ability:GetLevelSpecialValueFor("damage_to_pure", (ability:GetLevel() - 1))

        local total = params.original_damage * (damageConversion / 100)
        
        return total
    end
end

function modifier_terrorblade_metamorphosis_custom:GetModifierBaseAttack_BonusDamage()
    return self.damage
end

function modifier_terrorblade_metamorphosis_custom:GetModifierBaseAttackTimeConstant()
    return self.bat
end

function modifier_terrorblade_metamorphosis_custom:GetModifierMoveSpeedBonus_Constant()
    return self.slow
end

function modifier_terrorblade_metamorphosis_custom:GetModifierProjectileSpeedBonus()
    return self.projectile
end

function modifier_terrorblade_metamorphosis_custom:GetModifierAttackRangeBonus()
    return self.range
end

function modifier_terrorblade_metamorphosis_custom:GetModifierModelChange()
    return "models/heroes/terrorblade/demon.vmdl"
end

function modifier_terrorblade_metamorphosis_custom:GetModifierModelScale()
    return 25
end

function modifier_terrorblade_metamorphosis_custom:GetModifierProjectileName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf"
end

function modifier_terrorblade_metamorphosis_custom:GetAttackSound()
    return "Hero_Terrorblade_Morphed.Attack"
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_terrorblade_metamorphosis_custom:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = self.stun,
    }

    return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_terrorblade_metamorphosis_custom:OnIntervalThink()
    self.stun = false
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_terrorblade_metamorphosis_custom:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf"
end

function modifier_terrorblade_metamorphosis_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_terrorblade_metamorphosis_custom:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_transform.vpcf"
    local sound_cast = "Hero_Terrorblade.Metamorphosis"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
end