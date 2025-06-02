ogre_magi_bloodlust_custom = class({})
LinkLuaModifier( "modifier_ogre_magi_bloodlust_custom", "heroes/hero_ogre_magi/ogre_magi_bloodlust_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ogre_magi_bloodlust_custom_buff", "heroes/hero_ogre_magi/ogre_magi_bloodlust_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function ogre_magi_bloodlust_custom:GetIntrinsicModifierName()
    return "modifier_ogre_magi_bloodlust_custom"
end

--------------------------------------------------------------------------------
-- Ability Start
function ogre_magi_bloodlust_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    -- load data
    local duration = self:GetSpecialValueFor( "duration" )

    -- add buff
    target:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_ogre_magi_bloodlust_custom_buff", -- modifier name
        { duration = duration } -- kv
    )

    -- play effects
    self:PlayEffects( target )
end

--------------------------------------------------------------------------------
function ogre_magi_bloodlust_custom:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_cast.vpcf"
    local sound_cast = "Hero_OgreMagi.Bloodlust.Cast"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        2,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        3,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )
end

modifier_ogre_magi_bloodlust_custom_buff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ogre_magi_bloodlust_custom_buff:IsHidden()
    return false
end

function modifier_ogre_magi_bloodlust_custom_buff:IsDebuff()
    return false
end

function modifier_ogre_magi_bloodlust_custom_buff:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ogre_magi_bloodlust_custom_buff:OnCreated( kv )
    -- references
    self.model_scale = self:GetAbility():GetSpecialValueFor( "modelscale" )
    self.ms_bonus = self:GetAbility():GetSpecialValueFor( "bonus_movement_speed" )
    self.as_bonus = self:GetAbility():GetSpecialValueFor( "bonus_attack_speed" )
    self.cdr = self:GetAbility():GetSpecialValueFor( "bonus_cdr" )
    local as_self = self:GetAbility():GetSpecialValueFor( "self_bonus" )
    local cdr_self = self:GetAbility():GetSpecialValueFor( "self_cdr" )

    if self:GetParent()==self:GetCaster() then
        self.as_bonus = as_self
        self.cdr = cdr_self
    end

    if not IsServer() then return end

    -- play effects
    local sound_cast = "Hero_OgreMagi.Bloodlust.Target"
    EmitSoundOn( sound_cast, self:GetParent() )

    local sound_player = "Hero_OgreMagi.Bloodlust.Target.FP"
    EmitSoundOnClient( sound_player, self:GetParent():GetPlayerOwner() )
end

function modifier_ogre_magi_bloodlust_custom_buff:OnRefresh( kv )
    -- do what oncreated do
    self:OnCreated( kv )
end

function modifier_ogre_magi_bloodlust_custom_buff:OnRemoved()
end

function modifier_ogre_magi_bloodlust_custom_buff:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ogre_magi_bloodlust_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
    }

    return funcs
end

function modifier_ogre_magi_bloodlust_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self.ms_bonus
end
function modifier_ogre_magi_bloodlust_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self.as_bonus
end

function modifier_ogre_magi_bloodlust_custom_buff:GetModifierModelScale()
    return self.model_scale
end

function modifier_ogre_magi_bloodlust_custom_buff:GetModifierPercentageCooldown()
    return self.cdr
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ogre_magi_bloodlust_custom_buff:GetEffectName()
    return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end

function modifier_ogre_magi_bloodlust_custom_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ogre_magi_bloodlust_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ogre_magi_bloodlust_custom:IsHidden()
    return true
end

function modifier_ogre_magi_bloodlust_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ogre_magi_bloodlust_custom:OnCreated( kv )
    if not IsServer() then return end

    -- references
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.radius = self.ability:GetCastRange( self.caster:GetOrigin(), self.caster )
    local interval = 1

    if not IsServer() then return end

    -- Start interval
    self:StartIntervalThink( interval )
end

function modifier_ogre_magi_bloodlust_custom:OnRefresh( kv )
    
end

function modifier_ogre_magi_bloodlust_custom:OnRemoved()
end

function modifier_ogre_magi_bloodlust_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ogre_magi_bloodlust_custom:OnIntervalThink()
    -- check autocast state
    if not self.ability:GetAutoCastState() then return end

    -- check castability
    if not self.ability:IsFullyCastable() then return end

    -- somehow silenced is not included in castability
    if self.caster:IsSilenced() then return end

    -- find allied hero in radius
    local allies = FindUnitsInRadius(
        self.caster:GetTeamNumber(),    -- int, your team number
        self.caster:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_FRIENDLY, -- int, team filter
        DOTA_UNIT_TARGET_HERO,  -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,ally in pairs(allies) do
        -- check if ally doesn't have buff yet
        if not ally:HasModifier( "modifier_ogre_magi_bloodlust_custom_buff" ) then
            -- cast ability
            -- self.caster:CastAbilityOnTarget( ally, self.ability, self.caster:GetPlayerOwnerID() )
            SpellCaster:Cast(self.ability, ally, true)
            break
        end
    end
end