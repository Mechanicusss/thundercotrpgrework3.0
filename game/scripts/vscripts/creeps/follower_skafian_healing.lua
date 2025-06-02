LinkLuaModifier("modifier_follower_skafian_healing", "creeps/follower_skafian_healing", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_follower_skafian_healing_aura", "creeps/follower_skafian_healing", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

follower_skafian_healing = class(ItemBaseClass)
modifier_follower_skafian_healing = class(follower_skafian_healing)
modifier_follower_skafian_healing_aura = class(ItemBaseClassAura)
-------------
function follower_skafian_healing:GetIntrinsicModifierName()
    return "modifier_follower_skafian_healing"
end

function modifier_follower_skafian_healing:IsAura()
  return true
end

function modifier_follower_skafian_healing:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_follower_skafian_healing:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_follower_skafian_healing:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_follower_skafian_healing:GetModifierAura()
    return "modifier_follower_skafian_healing_aura"
end

function modifier_follower_skafian_healing:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_follower_skafian_healing:GetAuraEntityReject(target)
    return false
end

function modifier_follower_skafian_healing:GetEffectName()
    return "particles/dazzle/wd_ti10_immortal_voodoo.vpcf"
end
--------------------------------
function modifier_follower_skafian_healing_aura:OnCreated()
    if not IsServer() then return end

    self.interval = self:GetAbility():GetSpecialValueFor("heal_interval")

    self:StartIntervalThink(self.interval)
end

function modifier_follower_skafian_healing_aura:OnIntervalThink()
    local target = self:GetParent()

    local heal = self:GetAbility():GetSpecialValueFor("heal")
    local healpct = target:GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("heal_pct")/100)

    target:Heal(heal+healpct, self:GetAbility())
end