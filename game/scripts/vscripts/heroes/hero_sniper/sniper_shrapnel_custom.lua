sniper_shrapnel_custom = class({})
LinkLuaModifier( "modifier_sniper_shrapnel_custom", "heroes/hero_sniper/sniper_shrapnel_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sniper_shrapnel_custom_debuff", "heroes/hero_sniper/sniper_shrapnel_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sniper_shrapnel_custom_thinker", "heroes/hero_sniper/sniper_shrapnel_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sniper_shrapnel_custom_def", "heroes/hero_sniper/sniper_shrapnel_custom", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClassDeBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_sniper_shrapnel_custom_debuff = class(ItemBaseClassDeBuff)
modifier_sniper_shrapnel_custom_def = class(ItemBaseClass)

--------------------------------------------------------------------------------
-- Passive Modifier
--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function sniper_shrapnel_custom:GetAOERadius()
    return self:GetSpecialValueFor( "radius" )
end

function sniper_shrapnel_custom:GetIntrinsicModifierName()
    return "modifier_sniper_shrapnel_custom_def"
end
----------------
function modifier_sniper_shrapnel_custom_def:OnCreated()
    if IsServer() then
        self:StartIntervalThink(0.1)
    end
end

function modifier_sniper_shrapnel_custom_def:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if not caster:HasModifier("modifier_gun_joe_machine_gun") and ability:IsActivated() then
        ability:SetActivated(false)
    elseif caster:HasModifier("modifier_gun_joe_machine_gun") and not ability:IsActivated() then
        ability:SetActivated(true)
    end
end
--------------------------------------------------------------------------------
-- Ability Start
function sniper_shrapnel_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- logic
    CreateModifierThinker(
        caster,
        self,
        "modifier_sniper_shrapnel_custom_thinker",
        {},
        point,
        caster:GetTeamNumber(),
        false
    )

    -- effects
    self:PlayEffects( point )
end

--------------------------------------------------------------------------------
function sniper_shrapnel_custom:PlayEffects( point )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_sniper/sniper_shrapnel_launch.vpcf"
    local sound_cast = "Hero_Sniper.MKG_ShrapnelShoot"

    -- Get Data
    local height = 2000

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        self:GetCaster():GetOrigin(), -- unknown
        false -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 1, point + Vector( 0, 0, height ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )
end

modifier_sniper_shrapnel_custom_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_sniper_shrapnel_custom_thinker:IsHidden()
    return true
end

function modifier_sniper_shrapnel_custom_thinker:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Aura
function modifier_sniper_shrapnel_custom_thinker:IsAura()
    return self.start
end
function modifier_sniper_shrapnel_custom_thinker:GetModifierAura()
    return "modifier_sniper_shrapnel_custom"
end
function modifier_sniper_shrapnel_custom_thinker:GetAuraRadius()
    return self.radius
end
function modifier_sniper_shrapnel_custom_thinker:GetAuraDuration()
    return 0.5
end
function modifier_sniper_shrapnel_custom_thinker:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end
function modifier_sniper_shrapnel_custom_thinker:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_sniper_shrapnel_custom_thinker:OnCreated( kv )
    -- references
    self.delay = self:GetAbility():GetSpecialValueFor( "damage_delay" ) -- special value
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" ) -- special value
    self.damage = self:GetAbility():GetSpecialValueFor( "damage_from_attack" ) -- special value
    self.aura_stick = self:GetAbility():GetSpecialValueFor( "slow_duration" ) -- special value
    self.duration = self:GetAbility():GetSpecialValueFor( "duration" ) -- special value

    self.start = false

    if IsServer() then
        self.direction = (self:GetParent():GetOrigin()-self:GetCaster():GetOrigin()):Normalized()

        -- Start interval
        self:StartIntervalThink( self.delay )

        -- effects
        self.sound_cast = "Hero_Sniper.MKG_ShrapnelShatter"
        EmitSoundOn( self.sound_cast, self:GetParent() )        
    end
end

function modifier_sniper_shrapnel_custom_thinker:OnDestroy( kv )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_sniper_shrapnel_custom_thinker:OnIntervalThink()
    if not self.start then
        self.start = true
        self:StartIntervalThink( self.duration )
        AddFOWViewer( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), self.radius, self.duration, false )

        -- effects
        self:PlayEffects()
    else
        self:StopEffects()
        UTIL_Remove( self:GetParent() )
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_sniper_shrapnel_custom_thinker:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/econ/items/sniper/sniper_charlie/sniper_shrapnel_charlie.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( self.radius, 1, 1 ) )
    ParticleManager:SetParticleControlForward( self.effect_cast, 2, self.direction + Vector(0, 0, 0.1) )
end

function modifier_sniper_shrapnel_custom_thinker:StopEffects()
    ParticleManager:DestroyParticle( self.effect_cast, false )
    ParticleManager:ReleaseParticleIndex( self.effect_cast )

    StopSoundOn( self.sound_cast, self:GetParent() )
end

modifier_sniper_shrapnel_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_sniper_shrapnel_custom:IsHidden()
    return false
end

function modifier_sniper_shrapnel_custom:IsDebuff()
    return true
end

function modifier_sniper_shrapnel_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_sniper_shrapnel_custom:OnCreated( kv )
    -- references
    self.damage = self:GetAbility():GetSpecialValueFor( "damage_from_attack" ) -- special value
    self.ms_slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" ) -- special value

    local interval = 1
    self.caster = self:GetAbility():GetCaster()

    if IsServer() then
        -- precache damage
        self.damageTable = {
            victim = self:GetParent(),
            attacker = self.caster,
            damage = self.caster:GetAverageTrueAttackDamage(self.caster) * (self.damage/100),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility(), --Optional.
        }

        -- start interval
        self:StartIntervalThink( interval )
        self:OnIntervalThink()
    end
end

function modifier_sniper_shrapnel_custom:OnRefresh( kv )
    
end

function modifier_sniper_shrapnel_custom:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_sniper_shrapnel_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end
function modifier_sniper_shrapnel_custom:GetModifierMoveSpeedBonus_Percentage()
    return self.ms_slow
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_sniper_shrapnel_custom:OnIntervalThink()
    ApplyDamage(self.damageTable)

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local mod = parent:FindModifierByName("modifier_sniper_shrapnel_custom_debuff")
    if not mod then
        mod = parent:AddNewModifier(parent, ability, "modifier_sniper_shrapnel_custom_debuff", {
            duration = ability:GetSpecialValueFor("debuff_duration")
        })
    end

    if mod then
        mod:ForceRefresh()
    end
end
-------------------
function modifier_sniper_shrapnel_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_sniper_shrapnel_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_resistance")
end