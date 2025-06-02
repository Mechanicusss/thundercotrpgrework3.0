LinkLuaModifier("modifier_timmy_inspiration_aura", "heroes/hero_timmy/timmy_inspiration_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_timmy_inspiration_aura_buff", "heroes/hero_timmy/timmy_inspiration_aura", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

timmy_inspiration_aura = class(ItemBaseClass)
modifier_timmy_inspiration_aura = class(timmy_inspiration_aura)
modifier_timmy_inspiration_aura_buff = class(ItemBaseClassBuff)
-------------
function timmy_inspiration_aura:GetIntrinsicModifierName()
    return "modifier_timmy_inspiration_aura"
end

function timmy_inspiration_aura:GetAOERadius()
  return self:GetSpecialValueFor("aura_radius")
end

------------
function modifier_timmy_inspiration_aura:IsAura()
  return true
end

function modifier_timmy_inspiration_aura:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_timmy_inspiration_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_timmy_inspiration_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_timmy_inspiration_aura:GetModifierAura()
    return "modifier_timmy_inspiration_aura_buff"
end

function modifier_timmy_inspiration_aura:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE 
end

function modifier_timmy_inspiration_aura:GetAuraEntityReject(target)
    return false
end
-----------------
function modifier_timmy_inspiration_aura_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_PROPERTY_GOLD_RATE_BOOST 
    }
end

function modifier_timmy_inspiration_aura_buff:GetModifierBaseDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end

function modifier_timmy_inspiration_aura_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movement_speed_pct")
end

function modifier_timmy_inspiration_aura_buff:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_health_regen_pct")
end

function modifier_timmy_inspiration_aura_buff:GetModifierPercentageGoldRateBoost()
    return self:GetAbility():GetSpecialValueFor("bonus_gold_rate_pct")
end