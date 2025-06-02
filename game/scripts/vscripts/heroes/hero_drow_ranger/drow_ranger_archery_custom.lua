LinkLuaModifier("modifier_drow_ranger_archery_custom", "heroes/hero_drow_ranger/drow_ranger_archery_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_archery_custom_aura", "heroes/hero_drow_ranger/drow_ranger_archery_custom", LUA_MODIFIER_MOTION_NONE)

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

drow_ranger_archery_custom = class(ItemBaseClass)
modifier_drow_ranger_archery_custom = class(drow_ranger_archery_custom)
modifier_drow_ranger_archery_custom_aura = class(ItemBaseClassAura)
-------------
function drow_ranger_archery_custom:GetIntrinsicModifierName()
    return "modifier_drow_ranger_archery_custom"
end

function drow_ranger_archery_custom:GetAOERadius()
    return self:GetSpecialValueFor("aura_radius")
end
-------------
function modifier_drow_ranger_archery_custom:IsAura()
    return true
end

function modifier_drow_ranger_archery_custom:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_drow_ranger_archery_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_drow_ranger_archery_custom:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_drow_ranger_archery_custom:GetModifierAura()
    return "modifier_drow_ranger_archery_custom_aura"
end

function modifier_drow_ranger_archery_custom:GetAuraEntityReject(target)
    return not target:IsRangedAttacker()
end
-------------
function modifier_drow_ranger_archery_custom_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT 
    }
end

function modifier_drow_ranger_archery_custom_aura:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed_pct")
end

function modifier_drow_ranger_archery_custom_aura:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_evasion")
end