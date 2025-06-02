LinkLuaModifier("modifier_omniknight_degen_aura_custom", "heroes/hero_omniknight/omniknight_degen_aura_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_omniknight_degen_aura_custom_debuff", "heroes/hero_omniknight/omniknight_degen_aura_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}


omniknight_degen_aura_custom = class(ItemBaseClass)
modifier_omniknight_degen_aura_custom = class(omniknight_degen_aura_custom)
modifier_omniknight_degen_aura_custom_debuff = class(ItemBaseClassAura)
-------------
function omniknight_degen_aura_custom:GetIntrinsicModifierName()
    return "modifier_omniknight_degen_aura_custom"
end

function omniknight_degen_aura_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
----------
function modifier_omniknight_degen_aura_custom:IsAura()
  return true
end

function modifier_omniknight_degen_aura_custom:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_omniknight_degen_aura_custom:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_omniknight_degen_aura_custom:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_omniknight_degen_aura_custom:GetModifierAura()
    return "modifier_omniknight_degen_aura_custom_debuff"
end

function modifier_omniknight_degen_aura_custom:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_omniknight_degen_aura_custom:GetAuraEntityReject(target)
    return false
end
----------
function modifier_omniknight_degen_aura_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE, --GetModifierAttackSpeedPercentage
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_omniknight_degen_aura_custom_debuff:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    local caster = self:GetCaster()

    if event.unit ~= parent then return end
    if event.attacker == parent then return end
    if event.attacker:GetTeamNumber() ~= caster:GetTeamNumber() then return end

    local ability = self:GetAbility()
    local attacker = event.attacker
    local healAmount = event.damage * (ability:GetSpecialValueFor("lifesteal")/100)

    attacker:Heal(healAmount, ability)

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_HEAL,
        attacker,
        healAmount,
        nil
    )

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_shard_hammer_of_purity_heal_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_omniknight_degen_aura_custom_debuff:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function modifier_omniknight_degen_aura_custom_debuff:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function modifier_omniknight_degen_aura_custom_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function modifier_omniknight_degen_aura_custom_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function modifier_omniknight_degen_aura_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movespeed")
end

function modifier_omniknight_degen_aura_custom_debuff:GetModifierAttackSpeedReductionPercentage()
    return self:GetAbility():GetSpecialValueFor("attackspeed")
end

function modifier_omniknight_degen_aura_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_omniknight/omniknight_degeneration_debuff.vpcf"
end