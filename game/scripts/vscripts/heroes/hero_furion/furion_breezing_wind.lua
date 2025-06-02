LinkLuaModifier("modifier_furion_breezing_wind_custom", "heroes/hero_furion/furion_breezing_wind", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_furion_breezing_wind_custom_buff", "heroes/hero_furion/furion_breezing_wind", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_furion_breezing_wind_custom_buff_shard", "heroes/hero_furion/furion_breezing_wind", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT

local AbilityClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local AbilityClassBuff = {
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return false end,
}

furion_breezing_wind_custom = class(AbilityClass)
modifier_furion_breezing_wind_custom_buff = class(AbilityClassBuff)
modifier_furion_breezing_wind_custom_buff_shard = class(AbilityClass)

function furion_breezing_wind_custom:GetIntrinsicModifierName()
  return "modifier_furion_breezing_wind_custom"
end

function furion_breezing_wind_custom:OnSpellStart()
    if not IsServer() then return end

    local duration = self:GetSpecialValueFor("duration")
    local caster = self:GetCaster()
    local ability = self

    caster:EmitSound("Ability.Windrun")

    caster:AddNewModifier(caster, ability, "modifier_furion_breezing_wind_custom_buff", { duration = duration })

    if caster:HasModifier("modifier_item_aghanims_shard") then
        caster:AddNewModifier(caster, ability, "modifier_furion_breezing_wind_custom_buff_shard", { duration = duration })
    end
end
---------------------
function modifier_furion_breezing_wind_custom_buff:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.boost = self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_furion_breezing_wind_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
    }   

    return funcs
end

function modifier_furion_breezing_wind_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self.boost or self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_furion_breezing_wind_custom_buff:GetEffectName()
    return "particles/econ/items/windrunner/windranger_arcana/windranger_arcana_windrun.vpcf"
end
------------
function modifier_furion_breezing_wind_custom_buff_shard:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }   

    return funcs
end

function modifier_furion_breezing_wind_custom_buff_shard:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("shard_bonus_damage_pct")
end