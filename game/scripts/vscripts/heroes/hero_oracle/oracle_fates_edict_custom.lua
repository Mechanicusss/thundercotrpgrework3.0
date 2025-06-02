LinkLuaModifier("modifier_oracle_fates_edict_custom", "heroes/hero_oracle/oracle_fates_edict_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_fates_edict_custom_aura", "heroes/hero_oracle/oracle_fates_edict_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_fates_edict_custom_aura_ally", "heroes/hero_oracle/oracle_fates_edict_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

oracle_fates_edict_custom = class(ItemBaseClass)
modifier_oracle_fates_edict_custom = class(oracle_fates_edict_custom)
modifier_oracle_fates_edict_custom_aura = class(ItemBaseClassDebuff)
modifier_oracle_fates_edict_custom_aura_ally = class(ItemBaseClassBuff)
-------------
function oracle_fates_edict_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function oracle_fates_edict_custom:GetIntrinsicModifierName()
    return "modifier_oracle_fates_edict_custom"
end

function oracle_fates_edict_custom:OnToggle()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    EmitSoundOn("Hero_Oracle.FatesEdict.Cast", caster)

    self:UseResources(false, false, false, true)
end
-----------
function modifier_oracle_fates_edict_custom:OnCreated()
    
end

function modifier_oracle_fates_edict_custom:IsAura()
    return true
end

function modifier_oracle_fates_edict_custom:GetAuraSearchType()
    return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_oracle_fates_edict_custom:GetAuraSearchTeam()
    if not self:GetAbility():GetToggleState() then
        return DOTA_UNIT_TARGET_TEAM_ENEMY
    else
        return DOTA_UNIT_TARGET_TEAM_FRIENDLY
    end
end

function modifier_oracle_fates_edict_custom:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_oracle_fates_edict_custom:GetModifierAura()
    if not self:GetAbility():GetToggleState() then
        return "modifier_oracle_fates_edict_custom_aura"
    else
        return "modifier_oracle_fates_edict_custom_aura_ally"
    end
end

function modifier_oracle_fates_edict_custom:GetAuraEntityReject(target)
    return false
end
------------------
function modifier_oracle_fates_edict_custom_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_oracle_fates_edict_custom_aura:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res_enemy")
end

function modifier_oracle_fates_edict_custom_aura:GetEffectName()
    return "particles/units/heroes/hero_oracle/oracle_fatesedict.vpcf"
end
------------------
function modifier_oracle_fates_edict_custom_aura_ally:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_oracle_fates_edict_custom_aura_ally:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res_ally")
end

function modifier_oracle_fates_edict_custom_aura_ally:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("outgoing_damage_ally")
end

function modifier_oracle_fates_edict_custom_aura_ally:GetEffectName()
    return "particles/units/heroes/hero_oracle/oracle_fatesedict.vpcf"
end