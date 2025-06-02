LinkLuaModifier("modifier_hero_akasha_sadist", "heroes/hero_akasha/sadist", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hero_akasha_sadist_stacks", "heroes/hero_akasha/sadist", LUA_MODIFIER_MOTION_NONE)

local ItemBaseStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

hero_akasha_sadist = class(ItemBaseClass)
modifier_hero_akasha_sadist = class(hero_akasha_sadist)
modifier_hero_akasha_sadist_stacks = class(ItemBaseStacks)

function modifier_hero_akasha_sadist_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_hero_akasha_sadist_stacks:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE , --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_TOOLTIP
    }
    return funcs
end

function modifier_hero_akasha_sadist_stacks:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("lifesteal_per_stack") * self:GetStackCount()
end

function modifier_hero_akasha_sadist_stacks:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("lifesteal_per_stack") * self:GetStackCount()
end
-------------
function hero_akasha_sadist:GetIntrinsicModifierName()
    return "modifier_hero_akasha_sadist"
end

function modifier_hero_akasha_sadist:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
    return funcs
end

function modifier_hero_akasha_sadist:OnCreated()
    self.parent = self:GetParent()
end

function modifier_hero_akasha_sadist:OnTakeDamage(event)
    local attacker = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if attacker ~= parent then
        return
    end

    if attacker == victim then return end

    if event.damage_type ~= DAMAGE_TYPE_MAGICAL or event.inflictor == nil or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if parent:HasModifier("modifier_hero_akasha_sadist_stacks") then
        local mod = parent:FindModifierByName("modifier_hero_akasha_sadist_stacks")
        if mod:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            mod:IncrementStackCount()
        end

        mod:ForceRefresh()
    else
        local mod = parent:AddNewModifier(parent, self:GetAbility(), "modifier_hero_akasha_sadist_stacks", {
            duration = self:GetAbility():GetSpecialValueFor("duration")
        })
        mod:IncrementStackCount()
        mod:ForceRefresh()
    end
end
