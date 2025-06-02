LinkLuaModifier("modifier_tiny_unleashed_fury_custom", "heroes/hero_tiny/tiny_unleashed_fury_custom", LUA_MODIFIER_MOTION_NONE)

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

tiny_unleashed_fury_custom = class(ItemBaseClass)
modifier_tiny_unleashed_fury_custom = class(ItemBaseClassBuff)
-------------
function tiny_unleashed_fury_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_tiny_unleashed_fury_custom") then
        caster:RemoveModifierByName("modifier_tiny_unleashed_fury_custom")
    end

    caster:AddNewModifier(caster, self, "modifier_tiny_unleashed_fury_custom", {
        duration = self:GetDuration()
    })
end

function tiny_unleashed_fury_custom:GetDuration()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_tiny_2")
    if talent ~= nil and talent:GetLevel() > 0 then
        return talent:GetSpecialValueFor("duration")
    end
end
------------
function modifier_tiny_unleashed_fury_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_tiny_unleashed_fury_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    
    if parent ~= event.attacker then return end

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("stun_chance")

    if not RollPercentage(chance) then return end

    event.target:AddNewModifier(parent, nil, "modifier_stunned", {
        duration = ability:GetSpecialValueFor("stun_duration")
    })
end

function modifier_tiny_unleashed_fury_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.crit_chance = 0
    self.damage = 0

    self:StartIntervalThink(0.1)
end

function modifier_tiny_unleashed_fury_custom:OnIntervalThink()
    local parent = self:GetParent()
    
    local ability = self:GetAbility()

    local missingHealth = 100 - parent:GetHealthPercent()

    local perMissingHp = ability:GetSpecialValueFor("missing_hp_pct")
    
    local crit = missingHealth * perMissingHp * ability:GetSpecialValueFor("bonus_crit_chance_per_missing_crit")
    local damage = missingHealth * perMissingHp * ability:GetSpecialValueFor("bonus_damage_pct_per_missing_damage")

    self.crit_chance = crit + ability:GetSpecialValueFor("base_crit_chance")
    self.damage = damage + ability:GetSpecialValueFor("base_bonus_damage_pct")

    self:InvokeBonusDamage()
end

function modifier_tiny_unleashed_fury_custom:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed_pct")
end

function modifier_tiny_unleashed_fury_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movement_speed_pct")
end

function modifier_tiny_unleashed_fury_custom:GetModifierDamageOutgoing_Percentage()
    return self.fDamage
end

function modifier_tiny_unleashed_fury_custom:GetModifierPreAttack_CriticalStrike(params)
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        if RollPercentage(self.crit_chance) then
            self.record = params.record

            return self:GetAbility():GetSpecialValueFor("bonus_crit_damage")
        end
    end
end

function modifier_tiny_unleashed_fury_custom:GetModifierProcAttack_Feedback(params)
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end
end

function modifier_tiny_unleashed_fury_custom:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_tiny_unleashed_fury_custom:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_tiny_unleashed_fury_custom:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end