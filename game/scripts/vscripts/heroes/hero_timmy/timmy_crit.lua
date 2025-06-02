LinkLuaModifier("modifier_timmy_crit", "heroes/hero_timmy/timmy_crit", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_timmy_crit_buff", "heroes/hero_timmy/timmy_crit", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_timmy_crit_debuff", "heroes/hero_timmy/timmy_crit", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
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

timmy_crit = class(ItemBaseClass)
modifier_timmy_crit = class(timmy_crit)
modifier_timmy_crit_buff = class(ItemBaseClassBuff)
modifier_timmy_crit_debuff = class(ItemBaseClassDebuff)
-------------
function timmy_crit:GetIntrinsicModifierName()
    return "modifier_timmy_crit"
end
------------
function modifier_timmy_crit:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_timmy_crit:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end

    local victim = event.unit 

    if not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim) then return end

    local buff = parent:FindModifierByName("modifier_timmy_crit_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_timmy_crit_buff", {})
    end

    if buff then
        buff:IncrementStackCount()
        buff:ForceRefresh()
    end
end
-------------
function modifier_timmy_crit_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }
end

function modifier_timmy_crit_buff:GetModifierPreAttack_CriticalStrike(params)
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        if RollPercentage(self:GetAbility():GetSpecialValueFor("crit_chance")) then
            self.record = params.record

            local critDamage = self:GetAbility():GetSpecialValueFor("crit_damage") + (self:GetAbility():GetSpecialValueFor("crit_damage_per_kill")*self:GetStackCount())

            local debuff = params.target:FindModifierByName("modifier_timmy_crit_debuff")
            if not debuff then
                debuff = params.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_timmy_crit_debuff", {
                    duration = self:GetAbility():GetSpecialValueFor("duration")
                })
            end

            if debuff then
                debuff:ForceRefresh()
            end

            return critDamage
        end
    end
end

function modifier_timmy_crit_buff:GetModifierProcAttack_Feedback(params)
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end
end
---------
function modifier_timmy_crit_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_timmy_crit_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_loss")
end