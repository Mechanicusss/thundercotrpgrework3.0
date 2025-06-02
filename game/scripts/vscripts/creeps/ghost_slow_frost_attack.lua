LinkLuaModifier("modifier_ghost_slow_frost_attack", "creeps/ghost_slow_frost_attack", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ghost_slow_frost_attack_debuff", "creeps/ghost_slow_frost_attack", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

ghost_slow_frost_attack = class(ItemBaseClass)
modifier_ghost_slow_frost_attack = class(ghost_slow_frost_attack)
modifier_ghost_slow_frost_attack_debuff = class(ItemBaseClassDebuff)
-------------
function ghost_slow_frost_attack:GetIntrinsicModifierName()
    return "modifier_ghost_slow_frost_attack"
end
-------------
function modifier_ghost_slow_frost_attack:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_ghost_slow_frost_attack:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end

    local debuff = event.target:FindModifierByName("modifier_ghost_slow_frost_attack_debuff")
    
    if not debuff then
        debuff = event.target:AddNewModifier(parent, self:GetAbility(), "modifier_ghost_slow_frost_attack_debuff", {
            duration = self:GetAbility():GetSpecialValueFor("duration")
        })
    end

    if debuff then
        if debuff:GetStackCount() < 100 then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end
end
-------------
function modifier_ghost_slow_frost_attack_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }
end

function modifier_ghost_slow_frost_attack_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow") * self:GetStackCount()
end

function modifier_ghost_slow_frost_attack_debuff:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("degen") * self:GetStackCount()
end

function modifier_ghost_slow_frost_attack_debuff:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen") * self:GetStackCount()
end

function modifier_ghost_slow_frost_attack_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen") * self:GetStackCount()
end

function modifier_ghost_slow_frost_attack_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen") * self:GetStackCount()
end

function modifier_ghost_slow_frost_attack_debuff:GetEffectName()
    return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end