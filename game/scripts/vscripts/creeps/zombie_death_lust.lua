LinkLuaModifier("modifier_zombie_death_lust", "creeps/zombie_death_lust", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zombie_death_lust_debuff", "creeps/zombie_death_lust", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zombie_death_lust_buff", "creeps/zombie_death_lust", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    Isdebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    Isdebuff = function(self) return false end,
}

zombie_death_lust = class(ItemBaseClass)
modifier_zombie_death_lust = class(zombie_death_lust)
modifier_zombie_death_lust_debuff = class(ItemBaseClassDebuff)
modifier_zombie_death_lust_buff = class(ItemBaseClassDebuff)
-------------
function zombie_death_lust:GetIntrinsicModifierName()
    return "modifier_zombie_death_lust"
end

function modifier_zombie_death_lust:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_zombie_death_lust:OnAttackLanded(event)
    if not IsServer() then return end 
    
    local parent = self:GetParent()
    local target = event.target 

    if parent ~= event.attacker then return end 

    local ability = self:GetAbility()
    local duration = ability:GetSpecialValueFor("duration")
    local healthPct = ability:GetSpecialValueFor("health_threshold_pct")

    if not target:IsMagicImmune() then
        local debuff = target:FindModifierByName("modifier_zombie_death_lust_debuff")
        if not debuff then
            debuff = target:AddNewModifier(parent, ability, "modifier_zombie_death_lust_debuff", {
                duration = duration
            })
        end

        if debuff then
            debuff:IncrementStackCount()
            debuff:ForceRefresh()
        end
    end

    if target:GetHealthPercent() <= healthPct then
        if not parent:HasModifier("modifier_zombie_death_lust_buff") then
            parent:AddNewModifier(parent, ability, "modifier_zombie_death_lust_buff", {})
        end
    else
        if parent:HasModifier("modifier_zombie_death_lust_buff") then
            parent:RemoveModifierByName("modifier_zombie_death_lust_buff")
        end
    end
end
------------
function modifier_zombie_death_lust_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_zombie_death_lust_debuff:GetModifierMoveSpeedBonus_Percentage()
    if not self:IsNull() and not self:GetAbility():IsNull() then
        return self:GetAbility():GetSpecialValueFor("slow") * self:GetStackCount()
    end
end
------------
function modifier_zombie_death_lust_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }
end

function modifier_zombie_death_lust_buff:GetModifierMoveSpeedBonus_Percentage()
    if not self:IsNull() and not self:GetAbility():IsNull() then
        return self:GetAbility():GetSpecialValueFor("bonus_move_speed")
    end
end

function modifier_zombie_death_lust_buff:GetModifierAttackSpeedBonus_Constant()
    if not self:IsNull() and not self:GetAbility():IsNull() then
        return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
    end
end