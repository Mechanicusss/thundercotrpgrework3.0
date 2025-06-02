LinkLuaModifier("modifier_lich_ice_spire_custom_icy_aura", "heroes/hero_lich/ice_spire/lich_ice_spire_custom_icy_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lich_ice_spire_custom_icy_aura_aura", "heroes/hero_lich/ice_spire/lich_ice_spire_custom_icy_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lich_ice_spire_custom_icy_aura_aura_enemy", "heroes/hero_lich/ice_spire/lich_ice_spire_custom_icy_aura", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

lich_ice_spire_custom_icy_aura = class(ItemBaseClass)
modifier_lich_ice_spire_custom_icy_aura = class(lich_ice_spire_custom_icy_aura)
modifier_lich_ice_spire_custom_icy_aura_aura = class(ItemBaseClassAura)
modifier_lich_ice_spire_custom_icy_aura_aura_enemy = class(ItemBaseClassAura)
-------------
function lich_ice_spire_custom_icy_aura:GetIntrinsicModifierName()
    return "modifier_lich_ice_spire_custom_icy_aura"
end
---------
function modifier_lich_ice_spire_custom_icy_aura:OnCreated()
    if not IsServer() then return end

    self.aura = "modifier_lich_ice_spire_custom_icy_aura_aura"
end

function modifier_lich_ice_spire_custom_icy_aura:OnRemoved()
    if not IsServer() then return end
end

function modifier_lich_ice_spire_custom_icy_aura:IsAura()
  return true
end

function modifier_lich_ice_spire_custom_icy_aura:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_lich_ice_spire_custom_icy_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_lich_ice_spire_custom_icy_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_lich_ice_spire_custom_icy_aura:GetModifierAura()
    return self.aura
end

function modifier_lich_ice_spire_custom_icy_aura:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_lich_ice_spire_custom_icy_aura:GetAuraEntityReject(target)
    if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
        self.aura = "modifier_lich_ice_spire_custom_icy_aura_aura_enemy"
    else
        self.aura = "modifier_lich_ice_spire_custom_icy_aura_aura"
    end

    return false
end
---------------
function modifier_lich_ice_spire_custom_icy_aura_aura:IsDebuff()
    return false
end

function modifier_lich_ice_spire_custom_icy_aura_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
end

function modifier_lich_ice_spire_custom_icy_aura_aura:GetModifierSpellAmplify_Percentage()
    if self:GetAbility() == nil then return end
    return self:GetAbility():GetSpecialValueFor("spell_amp")
end

function modifier_lich_ice_spire_custom_icy_aura_aura:OnCreated()
    if not IsServer() then return end
end
-----------------
function modifier_lich_ice_spire_custom_icy_aura_aura_enemy:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
end

function modifier_lich_ice_spire_custom_icy_aura_aura_enemy:GetModifierMagicalResistanceBonus()
    if self:GetAbility() == nil then return end
    return self:GetAbility():GetSpecialValueFor("magic_res")
end

function modifier_lich_ice_spire_custom_icy_aura_aura_enemy:IsDebuff()
    return true
end