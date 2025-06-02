huskar_mana_spear_custom = class({})
LinkLuaModifier( "modifier_huskar_mana_spear_custom", "heroes/hero_huskar/mana_spear_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_huskar_mana_spear_custom_stack", "heroes/hero_huskar/mana_spear_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function huskar_mana_spear_custom:GetIntrinsicModifierName()
    return "modifier_generic_orb_effect_lua"
end

--------------------------------------------------------------------------------
-- Orb Effects
function huskar_mana_spear_custom:GetProjectileName()
    return "particles/units/heroes/hero_huskar/huskar_burning_spear.vpcf"
end

function huskar_mana_spear_custom:OnOrbFire( params )
    -- mana cost
    self:GetCaster():SpendMana(self:GetCaster():GetMaxMana() * (self:GetSpecialValueFor("mana_cost")/100), self)    
end

function huskar_mana_spear_custom:OnOrbImpact( params )
    local duration = self:GetDuration()

    params.target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_huskar_mana_spear_custom", -- modifier name
        { duration = duration } -- kv
    )

    -- play effects
    local sound_cast = "Hero_Huskar.burning_spear.Cast"
    EmitSoundOn( sound_cast, self:GetCaster() )
end

--------------------------------------------------------------------------------
-- Ability Start
function huskar_mana_spear_custom:OnSpellStart()
end

modifier_huskar_mana_spear_custom = class({})
local tempTable = require("libraries/tempTable")

--------------------------------------------------------------------------------
-- Classifications
function modifier_huskar_mana_spear_custom:IsHidden()
    return false
end

function modifier_huskar_mana_spear_custom:IsDebuff()
    return true
end

function modifier_huskar_mana_spear_custom:IsStunDebuff()
    return false
end

function modifier_huskar_mana_spear_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_huskar_mana_spear_custom:OnCreated( kv )
    -- reference
    if IsServer() then
        local duration = self:GetAbility():GetDuration()
        
        -- add stack modifier
        local this = tempTable:AddATValue( self )
        self:GetParent():AddNewModifier(
            self:GetCaster(), -- player source
            self, -- ability source
            "modifier_huskar_mana_spear_custom_stack", -- modifier name
            {
                duration = duration,
                modifier = this,
            } -- kv
        )

        -- increment stack
        if self:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            self:IncrementStackCount()
        end
    end
end

function modifier_huskar_mana_spear_custom:OnRefresh( kv )
    -- references
    if IsServer() then
        local duration = self:GetAbility():GetDuration()

        -- add stack
        local this = tempTable:AddATValue( self )
        self:GetParent():AddNewModifier(
            self:GetCaster(), -- player source
            self, -- ability source
            "modifier_huskar_mana_spear_custom_stack", -- modifier name
            {
                duration = duration,
                modifier = this,
            } -- kv
        )
        
        -- increment stack
        if self:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            self:IncrementStackCount()
        end
    end
end

function modifier_huskar_mana_spear_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
    return funcs
end

function modifier_huskar_mana_spear_custom:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_reduction_per_stack_pct") * self:GetStackCount()
end

function modifier_huskar_mana_spear_custom:OnRemoved()
    -- stop effects
    local sound_cast = "Hero_Huskar.burning_spear"
    StopSoundOn( sound_cast, self:GetParent() )
end

function modifier_huskar_mana_spear_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Interval Effects

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_huskar_mana_spear_custom:GetEffectName()
    return "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf"
end

function modifier_huskar_mana_spear_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

modifier_huskar_mana_spear_custom_stack = class({})
local tempTable = require("libraries/tempTable")

--------------------------------------------------------------------------------
-- Classifications
function modifier_huskar_mana_spear_custom_stack:IsHidden()
    return true
end

function modifier_huskar_mana_spear_custom_stack:IsPurgable()
    return false
end

function modifier_huskar_mana_spear_custom_stack:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_huskar_mana_spear_custom_stack:OnCreated( kv )
    if IsServer() then
        -- get references
        self.modifier = tempTable:RetATValue( kv.modifier )
    end

    -- play effects
    local sound_cast = "Hero_Huskar.burning_spear"
    EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_huskar_mana_spear_custom_stack:OnRemoved()
    if IsServer() then
        -- decrement stack
        if not self.modifier:IsNull() then
            self.modifier:DecrementStackCount()
        end
    end
end

function modifier_huskar_mana_spear_custom_stack:OnDestroy()
end