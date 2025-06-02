huskar_berserkers_blood_custom = class({})
LinkLuaModifier( "modifier_huskar_berserkers_blood_custom", "heroes/hero_huskar/berserkers_blood_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function huskar_berserkers_blood_custom:GetIntrinsicModifierName()
    return "modifier_huskar_berserkers_blood_custom"
end

modifier_huskar_berserkers_blood_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_huskar_berserkers_blood_custom:IsHidden()
    return true
end

function modifier_huskar_berserkers_blood_custom:IsDebuff()
    return false
end

function modifier_huskar_berserkers_blood_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_huskar_berserkers_blood_custom:OnCreated( kv )
    -- references
    self.max_as = self:GetAbility():GetSpecialValueFor( "maximum_attack_speed" )
    self.max_mr = self:GetAbility():GetSpecialValueFor( "maximum_magic_res" )
    self.max_threshold = self:GetAbility():GetSpecialValueFor( "hp_threshold_max" )
    self.max_hp_regen = self:GetAbility():GetSpecialValueFor( "max_health_regen_pct" ) 
    self.range = 100-self.max_threshold
    self.max_size = 35

    -- effects
    self:PlayEffects()
end

function modifier_huskar_berserkers_blood_custom:OnRefresh( kv )
    -- references
    self.max_as = self:GetAbility():GetSpecialValueFor( "maximum_attack_speed" )
    self.max_mr = self:GetAbility():GetSpecialValueFor( "maximum_magic_res" )
    self.max_threshold = self:GetAbility():GetSpecialValueFor( "hp_threshold_max" ) 
    self.max_hp_regen = self:GetAbility():GetSpecialValueFor( "max_health_regen_pct" ) 
    self.range = 100-self.max_threshold
end

function modifier_huskar_berserkers_blood_custom:OnRemoved()
end

function modifier_huskar_berserkers_blood_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_huskar_berserkers_blood_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_PROPERTY_MODEL_SCALE,
    }

    return funcs
end

function modifier_huskar_berserkers_blood_custom:GetModifierHealthRegenPercentage()
    -- interpolate missing health
    local pct = math.max((self:GetParent():GetHealthPercent()-self.max_threshold)/self.range,0)
    return (1-pct)*self.max_hp_regen
end

function modifier_huskar_berserkers_blood_custom:GetModifierMagicalResistanceBonus()
    -- interpolate missing health
    local pct = math.max((self:GetParent():GetHealthPercent()-self.max_threshold)/self.range,0)
    return (1-pct)*self.max_mr
end

function modifier_huskar_berserkers_blood_custom:GetModifierAttackSpeedBonus_Constant()
    -- interpolate missing health
    local pct = math.max((self:GetParent():GetHealthPercent()-self.max_threshold)/self.range,0)
    return (1-pct)*self.max_as
end


function modifier_huskar_berserkers_blood_custom:GetModifierModelScale()
    if IsServer() then
        local pct = math.max((self:GetParent():GetHealthPercent()-self.max_threshold)/self.range,0)

        -- set dynamic effects
        ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( (1-pct)*100,0,0 ) )

        return (1-pct)*self.max_size
    end
end
--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_huskar_berserkers_blood_custom:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_huskar/huskar_berserkers_blood_glow.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )

    -- buff particle
    self:AddParticle(
        self.effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )
end