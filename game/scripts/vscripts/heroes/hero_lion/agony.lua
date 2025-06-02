LinkLuaModifier("modifier_lion_agony", "heroes/hero_lion/agony", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lion_agony_stacks", "heroes/hero_lion/agony", LUA_MODIFIER_MOTION_NONE)

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

lion_agony = class(ItemBaseClass)
modifier_lion_agony = class(lion_agony)
modifier_lion_agony_stacks = class(ItemBaseStacks)

function modifier_lion_agony_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_lion_agony_stacks:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE , --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_TOOLTIP
    }
    return funcs
end

function modifier_lion_agony_stacks:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("outgoing_dmg_bonus_pct") * self:GetStackCount()
end

function modifier_lion_agony_stacks:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("outgoing_dmg_bonus_pct") * self:GetStackCount()
end

function modifier_lion_agony_stacks:GetModifierModelScale()
    return self:GetAbility():GetSpecialValueFor("model_scale")*self:GetStackCount()
end


-------------
function lion_agony:GetIntrinsicModifierName()
    return "modifier_lion_agony"
end


function modifier_lion_agony:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }
    return funcs
end

function modifier_lion_agony:OnCreated()
    self.parent = self:GetParent()
end

function modifier_lion_agony:OnTakeDamage(event)
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

    if parent:HasModifier("modifier_lion_agony_stacks") then
        local mod = parent:FindModifierByName("modifier_lion_agony_stacks")
        if mod:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            mod:IncrementStackCount()
        end

        mod:ForceRefresh()
    else
        local mod = parent:AddNewModifier(parent, self:GetAbility(), "modifier_lion_agony_stacks", {
            duration = self:GetAbility():GetSpecialValueFor("duration")
        })
        mod:IncrementStackCount()
        mod:ForceRefresh()
    end
end
