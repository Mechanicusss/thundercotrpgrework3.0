LinkLuaModifier("modifier_underlord_atrophy_aura_custom", "heroes/hero_underlord/underlord_atrophy_aura_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_underlord_atrophy_aura_custom_aura", "heroes/hero_underlord/underlord_atrophy_aura_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_underlord_atrophy_aura_custom_buff_permanent", "heroes/hero_underlord/underlord_atrophy_aura_custom", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

underlord_atrophy_aura_custom = class(ItemBaseClass)
modifier_underlord_atrophy_aura_custom = class(underlord_atrophy_aura_custom)
modifier_underlord_atrophy_aura_custom_buff_permanent = class(ItemBaseClassBuff)
modifier_underlord_atrophy_aura_custom_aura = class(ItemBaseClassAura)
-------------
function modifier_underlord_atrophy_aura_custom_buff_permanent:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_underlord_atrophy_aura_custom_buff_permanent:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
    }

    return funcs
end

function modifier_underlord_atrophy_aura_custom_buff_permanent:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("damage_gain") * self:GetStackCount()
end
-------------
function underlord_atrophy_aura_custom:GetIntrinsicModifierName()
    return "modifier_underlord_atrophy_aura_custom"
end

function underlord_atrophy_aura_custom:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end
-------------------
function modifier_underlord_atrophy_aura_custom:IsAura()
  return true
end

function modifier_underlord_atrophy_aura_custom:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_HERO)
end

function modifier_underlord_atrophy_aura_custom:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_underlord_atrophy_aura_custom:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_underlord_atrophy_aura_custom:GetModifierAura()
    return "modifier_underlord_atrophy_aura_custom_aura"
end

function modifier_underlord_atrophy_aura_custom:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_underlord_atrophy_aura_custom:GetAuraEntityReject(target)
    return false
end
--------------------
function modifier_underlord_atrophy_aura_custom_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE 
    }

    return funcs
end

function modifier_underlord_atrophy_aura_custom_aura:OnCreated()
    self.parent = self:GetParent()
end

function modifier_underlord_atrophy_aura_custom_aura:GetModifierBaseDamageOutgoing_Percentage()
    if self:GetCaster():HasScepter() and self:GetCaster():HasModifier("modifier_underlord_pit_of_abyss_custom_buff") and self:GetParent():HasModifier("modifier_underlord_pit_of_abyss_custom_aura") then
        return self:GetAbility():GetSpecialValueFor("damage_reduction_pct") * 2
    else
        return self:GetAbility():GetSpecialValueFor("damage_reduction_pct")
    end
end

function modifier_underlord_atrophy_aura_custom_aura:OnDeath(event)
    if not IsServer() then return end
    
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if victim ~= parent then return end

    local ability = self:GetAbility()

    local buff = caster:FindModifierByNameAndCaster("modifier_underlord_atrophy_aura_custom_buff_permanent", caster)
    local stacks = caster:GetModifierStackCount("modifier_underlord_atrophy_aura_custom_buff_permanent", caster)
    
    if not buff then
        caster:AddNewModifier(caster, ability, "modifier_underlord_atrophy_aura_custom_buff_permanent", {})
    else
        buff:ForceRefresh()
    end

    caster:SetModifierStackCount("modifier_underlord_atrophy_aura_custom_buff_permanent", caster, (stacks + 1))
end