LinkLuaModifier("modifier_zuus_static_field_custom", "heroes/hero_zeus/zuus_static_field_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zuus_static_field_custom_stacks", "heroes/hero_zeus/zuus_static_field_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zuus_static_field_custom_active", "heroes/hero_zeus/zuus_static_field_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

zuus_static_field_custom = class(ItemBaseClass)
modifier_zuus_static_field_custom = class(zuus_static_field_custom)
modifier_zuus_static_field_custom_stacks = class(ItemBaseClassStacks)
modifier_zuus_static_field_custom_active = class(ItemBaseClassActive)
-------------
function zuus_static_field_custom:GetIntrinsicModifierName()
    return "modifier_zuus_static_field_custom"
end

function zuus_static_field_custom:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_zuus_transcendence_custom_transport") then
        return
    end

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_zuus_static_field_custom_active", {})
    else
        caster:RemoveModifierByName("modifier_zuus_static_field_custom_active")
    end
end
-------------
function modifier_zuus_static_field_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    local ability = self:GetAbility()
end

function modifier_zuus_static_field_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }

    return funcs
end

function modifier_zuus_static_field_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local attacker = event.attacker

    if parent ~= attacker then return end
    if event.inflictor == nil then return end

    if not string.find(event.inflictor:GetAbilityName(), "zuus") then return end

    local ability = self:GetAbility()
    if ability:GetToggleState() then return end

    local static = parent:FindModifierByNameAndCaster("modifier_zuus_static_field_custom_stacks", parent)
    if static == nil then
        static = parent:AddNewModifier(parent, ability, "modifier_zuus_static_field_custom_stacks", {})
    end

    local increase = ability:GetSpecialValueFor("stacks")
    local maxStacks = ability:GetSpecialValueFor("max_stacks")

    if static:GetStackCount() < maxStacks then
        static:SetStackCount(static:GetStackCount() + increase)
    end
end
-----------
function modifier_zuus_static_field_custom_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_zuus_static_field_custom_stacks:IsHidden()
    return self:GetStackCount() < 1
end

function modifier_zuus_static_field_custom_active:IsHidden()
    return true
end