LinkLuaModifier("modifier_oracle_false_promise_custom", "heroes/hero_oracle/oracle_false_promise_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_false_promise_custom_debuff_1", "heroes/hero_oracle/oracle_false_promise_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_false_promise_custom_debuff_2", "heroes/hero_oracle/oracle_false_promise_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_false_promise_custom_debuff_3", "heroes/hero_oracle/oracle_false_promise_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_false_promise_custom_buff_1", "heroes/hero_oracle/oracle_false_promise_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_false_promise_custom_buff_2", "heroes/hero_oracle/oracle_false_promise_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_false_promise_custom_buff_3", "heroes/hero_oracle/oracle_false_promise_custom", LUA_MODIFIER_MOTION_NONE)

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

oracle_false_promise_custom = class(ItemBaseClass)
modifier_oracle_false_promise_custom = class(oracle_false_promise_custom)
modifier_oracle_false_promise_custom_debuff_1 = class(ItemBaseClassDebuff)
modifier_oracle_false_promise_custom_debuff_2 = class(ItemBaseClassDebuff)
modifier_oracle_false_promise_custom_debuff_3 = class(ItemBaseClassDebuff)
modifier_oracle_false_promise_custom_buff_1 = class(ItemBaseClassBuff)
modifier_oracle_false_promise_custom_buff_2 = class(ItemBaseClassBuff)
modifier_oracle_false_promise_custom_buff_3 = class(ItemBaseClassBuff)
-------------
function oracle_false_promise_custom:GetIntrinsicModifierName()
    return "modifier_oracle_false_promise_custom"
end

function modifier_oracle_false_promise_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_oracle_false_promise_custom:TriggerHealingEvent(target)
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local parent = self:GetParent()

    local duration = ability:GetSpecialValueFor("duration")

    local mods = {
        "modifier_oracle_false_promise_custom_buff_1",
        "modifier_oracle_false_promise_custom_buff_2",
        "modifier_oracle_false_promise_custom_buff_3"
    }

    local randomMod = mods[RandomInt(1, #mods)]

    local buff = target:FindModifierByName(randomMod)
    if not buff then
        buff = target:AddNewModifier(parent, ability, randomMod, {
            duration = duration
        })
    end

    if buff then
        buff:ForceRefresh()
    end
end

function modifier_oracle_false_promise_custom:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.unit 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    local ability = self:GetAbility()

    if not ability or ability:IsNull() then return end 

    if ability:GetAbilityName() ~= "oracle_false_promise_custom" and ability:GetAbilityName() ~= "oracle_rain_of_destiny_custom" then return end 
    
    local chance = ability:GetSpecialValueFor("chance")
    local duration = ability:GetSpecialValueFor("duration")

    if not RollPercentage(chance) then return end

    local mods = {
        "modifier_oracle_false_promise_custom_debuff_1",
        "modifier_oracle_false_promise_custom_debuff_2",
        "modifier_oracle_false_promise_custom_debuff_3"
    }

    local randomMod = mods[RandomInt(1, #mods)]

    local debuff = target:FindModifierByName(randomMod)
    if not debuff then
        debuff = target:AddNewModifier(parent, ability, randomMod, {
            duration = duration
        })
    end

    if debuff then
        debuff:ForceRefresh()
    end
end
------------
function modifier_oracle_false_promise_custom_debuff_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_oracle_false_promise_custom_debuff_1:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("incoming_damage_pct")
end

function modifier_oracle_false_promise_custom_debuff_1:GetEffectName()
    return "particles/units/heroes/hero_oracle/oracle_fatesedict_disarm_debuff.vpcf"
end

function modifier_oracle_false_promise_custom_debuff_1:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
------------
function modifier_oracle_false_promise_custom_debuff_2:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE  
    }
end

function modifier_oracle_false_promise_custom_debuff_2:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("outgoing_damage_pct")
end

function modifier_oracle_false_promise_custom_debuff_2:GetEffectName()
    return "particles/units/heroes/hero_oracle/oracle_fatesedict_disarm_debuff.vpcf"
end

function modifier_oracle_false_promise_custom_debuff_2:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
------------
function modifier_oracle_false_promise_custom_debuff_3:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET  
    }
end

function modifier_oracle_false_promise_custom_debuff_3:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("reduced_healing_amp")
end

function modifier_oracle_false_promise_custom_debuff_3:GetEffectName()
    return "particles/units/heroes/hero_oracle/oracle_fatesedict_disarm_debuff.vpcf"
end

function modifier_oracle_false_promise_custom_debuff_3:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
------------
function modifier_oracle_false_promise_custom_buff_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
    }
end

function modifier_oracle_false_promise_custom_buff_1:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_health_pct")
end

function modifier_oracle_false_promise_custom_buff_1:GetEffectName()
    return "particles/units/heroes/hero_oracle/oracle_fatesedict_disarm_ovrhead_2.vpcf"
end

function modifier_oracle_false_promise_custom_buff_1:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
------------
function modifier_oracle_false_promise_custom_buff_2:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_oracle_false_promise_custom_buff_2:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_speed_pct")
end

function modifier_oracle_false_promise_custom_buff_2:GetEffectName()
    return "particles/units/heroes/hero_oracle/oracle_fatesedict_disarm_ovrhead_2.vpcf"
end

function modifier_oracle_false_promise_custom_buff_2:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
------------
function modifier_oracle_false_promise_custom_buff_3:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    }
end

function modifier_oracle_false_promise_custom_buff_3:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_outgoing_damage_pct")
end

function modifier_oracle_false_promise_custom_buff_3:GetEffectName()
    return "particles/units/heroes/hero_oracle/oracle_fatesedict_disarm_ovrhead_2.vpcf"
end

function modifier_oracle_false_promise_custom_buff_3:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end