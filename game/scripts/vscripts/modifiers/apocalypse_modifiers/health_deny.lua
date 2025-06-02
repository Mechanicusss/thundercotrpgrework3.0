LinkLuaModifier("modifier_apocalypse_health_deny", "modifiers/apocalypse_modifiers/health_deny", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_apocalypse_health_deny_debuff", "modifiers/apocalypse_modifiers/health_deny", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_health_deny = class(ItemBaseClass)

modifier_apocalypse_health_deny_debuff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

function modifier_apocalypse_health_deny:GetIntrinsicModifierName()
    return "modifier_apocalypse_health_deny"
end

function modifier_apocalypse_health_deny:GetTexture() return "healthdeny" end
-------------
function modifier_apocalypse_health_deny:OnCreated()
    if not IsServer() then return end
end

function modifier_apocalypse_health_deny:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_apocalypse_health_deny:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.target:IsMagicImmune() or event.target:IsInvulnerable() then return end

    local target = event.target
    local parent = self:GetParent()

    local debuff = target:FindModifierByName("modifier_apocalypse_health_deny_debuff")

    if not debuff then
        debuff = target:AddNewModifier(parent, self:GetAbility(), "modifier_apocalypse_health_deny_debuff", {
            duration = 5
        })
    end

    if debuff then
        debuff:IncrementStackCount()
        debuff:ForceRefresh()
    end
end
----------
function modifier_apocalypse_health_deny_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }

    return funcs
end

function modifier_apocalypse_health_deny_debuff:GetModifierHealAmplify_PercentageTarget()
    return -1.5 * self:GetStackCount()
end

function modifier_apocalypse_health_deny_debuff:GetModifierHPRegenAmplify_Percentage()
    return -1.5 * self:GetStackCount()
end

function modifier_apocalypse_health_deny_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return -1.5 * self:GetStackCount()
end

function modifier_apocalypse_health_deny_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    return -1.5 * self:GetStackCount()
end

function modifier_apocalypse_health_deny_debuff:GetTexture() return "healthdeny" end