LinkLuaModifier("modifier_crystal_maiden_arcane_aura_custom", "heroes/hero_crystal_maiden/crystal_maiden_arcane_aura_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_arcane_aura_custom_aura", "heroes/hero_crystal_maiden/crystal_maiden_arcane_aura_custom", LUA_MODIFIER_MOTION_NONE)

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

crystal_maiden_arcane_aura_custom = class(ItemBaseClass)
modifier_crystal_maiden_arcane_aura_custom = class(crystal_maiden_arcane_aura_custom)
modifier_crystal_maiden_arcane_aura_custom_aura = class(ItemBaseClassAura)
-------------
function crystal_maiden_arcane_aura_custom:GetIntrinsicModifierName()
    return "modifier_crystal_maiden_arcane_aura_custom"
end

function modifier_crystal_maiden_arcane_aura_custom:IsAura()
  return true
end

function modifier_crystal_maiden_arcane_aura_custom:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_crystal_maiden_arcane_aura_custom:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_crystal_maiden_arcane_aura_custom:GetAuraRadius()
  return 99999
end

function modifier_crystal_maiden_arcane_aura_custom:GetModifierAura()
    return "modifier_crystal_maiden_arcane_aura_custom_aura"
end

function modifier_crystal_maiden_arcane_aura_custom:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_crystal_maiden_arcane_aura_custom:GetAuraEntityReject(target)
    return false
end
-----------
function modifier_crystal_maiden_arcane_aura_custom_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }

    return funcs
end

function modifier_crystal_maiden_arcane_aura_custom_aura:OnCreated()
    self:OnRefresh()
end

function modifier_crystal_maiden_arcane_aura_custom_aura:OnRefresh()
    self.amp = self:GetAbility():GetSpecialValueFor("spell_amp")
    self.CMamp = self.amp * self:GetAbility():GetSpecialValueFor("self_factor")
end

function modifier_crystal_maiden_arcane_aura_custom_aura:GetModifierSpellAmplify_Percentage()
    if self:GetParent() == self:GetCaster() then
        return self.CMamp
    else
        return self.amp
    end
end