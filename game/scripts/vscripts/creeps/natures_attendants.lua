LinkLuaModifier("modifier_enchantress_natures_attendants_custom", "creeps/natures_attendants", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enchantress_natures_attendants_custom_aura", "creeps/natures_attendants", LUA_MODIFIER_MOTION_NONE)

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

enchantress_natures_attendants_custom = class(ItemBaseClass)
modifier_enchantress_natures_attendants_custom = class(enchantress_natures_attendants_custom)
modifier_enchantress_natures_attendants_custom_aura = class(ItemBaseClassAura)
-------------
function enchantress_natures_attendants_custom:GetIntrinsicModifierName()
    return "modifier_enchantress_natures_attendants_custom"
end

function modifier_enchantress_natures_attendants_custom:GetEffectName()
    return "particles/units/heroes/hero_enchantress/enchantress_natures_attendants_heal.vpcf"
end

function modifier_enchantress_natures_attendants_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_enchantress_natures_attendants_custom:IsAura()
  return true
end

function modifier_enchantress_natures_attendants_custom:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_enchantress_natures_attendants_custom:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_enchantress_natures_attendants_custom:GetAuraRadius()
  return 900
end

function modifier_enchantress_natures_attendants_custom:GetModifierAura()
    return "modifier_enchantress_natures_attendants_custom_aura"
end

function modifier_enchantress_natures_attendants_custom:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_enchantress_natures_attendants_custom:GetAuraEntityReject(target)
    return false
end

---
function modifier_enchantress_natures_attendants_custom_aura:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.5)
end

function modifier_enchantress_natures_attendants_custom_aura:OnIntervalThink()
    if not self:GetParent() then return end
    if not self:GetParent():IsAlive() then return end

    local hp = self:GetParent():GetMaxHealth()
    if not hp then return end

    local ability = self:GetAbility()
    if not ability then return end
    
    local amount = hp * (ability:GetSpecialValueFor("heal")/100)
    self:GetParent():Heal(amount, ability)
end

function modifier_enchantress_natures_attendants_custom_aura:IsDebuff()
    return false
end

function modifier_enchantress_natures_attendants_custom_aura:GetEffectName()
    return "particles/units/heroes/hero_enchantress/enchantress_natures_attendants_count14.vpcf"
end