LinkLuaModifier("modifier_pudge_flesh_heap_custom", "heroes/hero_pudge/heap", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_flesh_heap_custom_buff_permanent", "heroes/hero_pudge/heap", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

pudge_flesh_heap_custom = class(ItemBaseClass)
modifier_pudge_flesh_heap_custom = class(pudge_flesh_heap_custom)
modifier_pudge_flesh_heap_custom_buff_permanent = class(ItemBaseClassBuff)
-------------
function modifier_pudge_flesh_heap_custom_buff_permanent:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
    }

    return funcs
end

function modifier_pudge_flesh_heap_custom_buff_permanent:GetModifierBonusStats_Strength()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("str_gain")
end

function modifier_pudge_flesh_heap_custom_buff_permanent:GetStatusEffectName()
    return "particles/units/heroes/hero_pudge/pudge_fleshheap_status_effect.vpcf"
end
-------------
function pudge_flesh_heap_custom:GetIntrinsicModifierName()
    return "modifier_pudge_flesh_heap_custom"
end

function pudge_flesh_heap_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    local mod = caster:FindModifierByName("modifier_pudge_flesh_heap_custom")
    local stacks = mod:GetStackCount()

    local buff = caster:AddNewModifier(caster, self, "modifier_pudge_flesh_heap_custom_buff_permanent", {
        duration = self:GetSpecialValueFor("duration")
    })

    if buff then
        buff:SetStackCount(stacks)
    end

    caster:CalculateStatBonus(true)
end
---------------
function modifier_pudge_flesh_heap_custom:IsHidden() return false end 

function modifier_pudge_flesh_heap_custom:OnCreated()
    if not IsServer() then return end 

    self:SetStackCount(0)
end

function modifier_pudge_flesh_heap_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
    }
    return funcs
end

function modifier_pudge_flesh_heap_custom:GetModifierPhysical_ConstantBlock(event)
    local block = event.damage * (self:GetAbility():GetSpecialValueFor("damage_block")/100)

    return block
end

function modifier_pudge_flesh_heap_custom:OnDeath(event)
    local attacker = event.attacker
    local parent = self:GetParent()
    local victim = event.unit

    if attacker ~= parent then
        return
    end

    if victim:GetTeam() == parent:GetTeam() then return end

    local ability = self:GetAbility()

    self:IncrementStackCount()
end