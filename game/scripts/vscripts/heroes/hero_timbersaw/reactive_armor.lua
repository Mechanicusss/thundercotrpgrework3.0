timbersaw_reactive_armor_custom = class({})
LinkLuaModifier( "modifier_timbersaw_reactive_armor_custom", "heroes/hero_timbersaw/reactive_armor", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_timbersaw_reactive_armor_custom_stack", "heroes/hero_timbersaw/reactive_armor", LUA_MODIFIER_MOTION_NONE )

function timbersaw_reactive_armor_custom:GetBehavior()
    local caster = self:GetCaster()

    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function timbersaw_reactive_armor_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    if not caster:HasScepter() then return end

    local modParent = caster:FindModifierByNameAndCaster("modifier_timbersaw_reactive_armor_custom", caster)
    modParent.actual_stack = self:GetSpecialValueFor("stack_limit")
    modParent:SetStackCount(self:GetSpecialValueFor("stack_limit"))
    modParent:ForceRefresh()
    modParent:SetDuration(self:GetSpecialValueFor("stack_duration"), true)

    --
    local mod = caster:FindModifierByNameAndCaster("modifier_timbersaw_reactive_armor_custom_stack", caster)
    if mod == nil then
        mod = caster:AddNewModifier(caster, self, "modifier_timbersaw_reactive_armor_custom_stack", {
            duration = self:GetSpecialValueFor("stack_duration")
        })
    end
    mod.parent = modParent
end
--------------------------------------------------------------------------------
-- Passive Modifier
function timbersaw_reactive_armor_custom:GetIntrinsicModifierName()
    return "modifier_timbersaw_reactive_armor_custom"
end
modifier_timbersaw_reactive_armor_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_timbersaw_reactive_armor_custom:IsHidden()
    return self:GetStackCount()==0
end

function modifier_timbersaw_reactive_armor_custom:IsDebuff()
    return false
end

function modifier_timbersaw_reactive_armor_custom:IsStunDebuff()
    return false
end

function modifier_timbersaw_reactive_armor_custom:IsPurgable()
    return false
end

function modifier_timbersaw_reactive_armor_custom:DestroyOnExpire()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_timbersaw_reactive_armor_custom:OnCreated( kv )
    -- references
    self.stack_duration = self:GetAbility():GetSpecialValueFor( "stack_duration" )
    self.stack_limit = self:GetAbility():GetSpecialValueFor( "stack_limit" )

    self.stack_regen = self:GetAbility():GetSpecialValueFor( "bonus_hp_regen" )
    self.stack_mr = self:GetAbility():GetSpecialValueFor( "magic_resistance" )
    self.stack_armor = self:GetAbility():GetSpecialValueFor( "bonus_armor" )

    self.actual_stack = 0
end

function modifier_timbersaw_reactive_armor_custom:OnRefresh( kv )
    -- references
    self.stack_duration = self:GetAbility():GetSpecialValueFor( "stack_duration" )
    self.stack_limit = self:GetAbility():GetSpecialValueFor( "stack_limit" )

    self.stack_regen = self:GetAbility():GetSpecialValueFor( "bonus_hp_regen" )
    self.stack_mr = self:GetAbility():GetSpecialValueFor( "magic_resistance" )
    self.stack_armor = self:GetAbility():GetSpecialValueFor( "bonus_armor" )
end

function modifier_timbersaw_reactive_armor_custom:OnRemoved()
end

function modifier_timbersaw_reactive_armor_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_timbersaw_reactive_armor_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,

        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function modifier_timbersaw_reactive_armor_custom:OnAttackLanded( params )
    if not IsServer() then return end
    if params.target~=self:GetParent() then return end

    -- cancel if break
    if self:GetParent():PassivesDisabled() then return end

    -- add stack
    self.actual_stack = self.actual_stack + 1
    if self:GetStackCount()<self.stack_limit then
        self:IncrementStackCount()
    end

    -- add stack modifier
    local modifier = self:GetParent():AddNewModifier(
        self:GetParent(), -- player source
        self:GetAbility(), -- ability source
        "modifier_timbersaw_reactive_armor_custom_stack", -- modifier name
        { duration = self.stack_duration } -- kv
    )
    if modifier ~= nil then
        modifier.parent = self
    end

    -- set duration
    self:SetDuration( self.stack_duration, true )
end

function modifier_timbersaw_reactive_armor_custom:GetModifierPhysicalArmorBonus()
    if self:GetParent():HasScepter() then
        return (self:GetStackCount() * self.stack_armor) + (self:GetStackCount() * (self:GetParent():GetPhysicalArmorBaseValue() * (self:GetAbility():GetSpecialValueFor("base_armor_pct")/100)))
    else
        return self:GetStackCount() * self.stack_armor
    end
end
function modifier_timbersaw_reactive_armor_custom:GetModifierConstantHealthRegen()
    return self:GetStackCount() * self.stack_regen
end
function modifier_timbersaw_reactive_armor_custom:GetModifierMagicalResistanceBonus()
    return self:GetStackCount() * self.stack_mr
end

function modifier_timbersaw_reactive_armor_custom:RemoveStack()
    self.actual_stack = self.actual_stack - 1
    if self.actual_stack<=self.stack_limit then
        self:SetStackCount( self.actual_stack )
    end
end

modifier_timbersaw_reactive_armor_custom_stack = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_timbersaw_reactive_armor_custom_stack:IsHidden()
    return true
end

function modifier_timbersaw_reactive_armor_custom_stack:IsPurgable()
    return false
end

function modifier_timbersaw_reactive_armor_custom_stack:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_timbersaw_reactive_armor_custom_stack:OnDestroy()
    if not IsServer() then return end
    self.parent:RemoveStack()
end

