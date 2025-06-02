LinkLuaModifier("modifier_necronomicon_archer_ranged_aura", "creeps/necronomicon_archer/necronomicon_archer_ranged_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necronomicon_archer_ranged_aura_buff", "creeps/necronomicon_archer/necronomicon_archer_ranged_aura", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
}

necronomicon_archer_ranged_aura = class(ItemBaseClass)
modifier_necronomicon_archer_ranged_aura = class(necronomicon_archer_ranged_aura)
modifier_necronomicon_archer_ranged_aura_buff = class(ItemBaseClassAura)
-------------
function necronomicon_archer_ranged_aura:GetIntrinsicModifierName()
    return "modifier_necronomicon_archer_ranged_aura"
end

function necronomicon_archer_ranged_aura:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function modifier_necronomicon_archer_ranged_aura:IsAura()
  return true
end

function modifier_necronomicon_archer_ranged_aura:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_necronomicon_archer_ranged_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_necronomicon_archer_ranged_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_necronomicon_archer_ranged_aura:GetModifierAura()
    return "modifier_necronomicon_archer_ranged_aura_buff"
end

function modifier_necronomicon_archer_ranged_aura:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_necronomicon_archer_ranged_aura:GetAuraEntityReject(target)
    return not target:IsRangedAttacker()
end
-------------------
function modifier_necronomicon_archer_ranged_aura_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_necronomicon_archer_ranged_aura_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_bonus_pct")
end

function modifier_necronomicon_archer_ranged_aura_buff:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker

    if self:GetParent() ~= attacker then
        return
    end

    local lifestealAmount = self:GetAbility():GetSpecialValueFor("lifesteal")

    if lifestealAmount < 1 or not attacker:IsAlive() or attacker:GetHealth() < 1 or event.target:IsOther() or event.target:IsBuilding() then
        return
    end

    local heal = event.damage * (lifestealAmount/100)

    --local heal = attacker:GetLevel() + self.lifestealAmount

    if attacker:IsIllusion() then -- Illusions only heal for 10% of the value
        heal = heal * 0.1
    end
    
    --attacker:SetHealth(attacker:GetHealth() + heal) DO NOT USE! Ignores regen reduction
    if heal < 0 or heal > INT_MAX_LIMIT then
        heal = self:GetParent():GetMaxHealth()
    end

    attacker:Heal(heal, nil)

    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
end