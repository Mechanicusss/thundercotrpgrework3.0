LinkLuaModifier("modifier_gabriel_heavenly_balance", "heroes/hero_gabriel/gabriel_heavenly_balance", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

gabriel_heavenly_balance = class(ItemBaseClass)
modifier_gabriel_heavenly_balance = class(gabriel_heavenly_balance)
-------------
function gabriel_heavenly_balance:GetIntrinsicModifierName()
    return "modifier_gabriel_heavenly_balance"
end

function modifier_gabriel_heavenly_balance:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }
end

function modifier_gabriel_heavenly_balance:GetEffectName()
    return "particles/econ/items/omniknight/omniknight_fall20_immortal/omniknight_fall20_immortal_degen_aura_debuff_2.vpcf"
end

function modifier_gabriel_heavenly_balance:GetModifierMoveSpeedBonus_Percentage()
    local threshold = self:GetAbility():GetSpecialValueFor("threshold_min")/100
    local parent = self:GetParent()
    local manaRemaining = 1-((parent:GetMaxMana() - parent:GetMana())/parent:GetMaxMana())
    if manaRemaining > threshold then
        return self:GetAbility():GetSpecialValueFor("movespeed_bonus_pct")
    end
end

function modifier_gabriel_heavenly_balance:GetModifierMagicalResistanceBonus()
    local threshold = self:GetAbility():GetSpecialValueFor("threshold_min")/100
    local parent = self:GetParent()
    local manaRemaining = 1-((parent:GetMaxMana() - parent:GetMana())/parent:GetMaxMana())
    if manaRemaining > threshold then
        return self:GetAbility():GetSpecialValueFor("magic_resistance")
    end
end

function modifier_gabriel_heavenly_balance:GetModifierTotalPercentageManaRegen()
    local threshold = self:GetAbility():GetSpecialValueFor("threshold_max")/100
    local parent = self:GetParent()
    local manaRemaining = 1-((parent:GetMaxMana() - parent:GetMana())/parent:GetMaxMana())
    if manaRemaining < threshold then
        return self:GetAbility():GetSpecialValueFor("mana_regen_rate")
    end
end

function modifier_gabriel_heavenly_balance:GetModifierPreAttack_CriticalStrike(params)
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        local threshold = self:GetAbility():GetSpecialValueFor("threshold_max")/100
        local parent = self:GetParent()
        local manaRemaining = 1-((parent:GetMaxMana() - parent:GetMana())/parent:GetMaxMana())

        if manaRemaining < threshold then
            local chance = self:GetAbility():GetSpecialValueFor("crit_chance")
            local crit = self:GetAbility():GetSpecialValueFor("crit_damage")

            local missingMana = self:GetParent():GetMaxMana() - self:GetParent():GetMana()
            local critPerMana = self:GetAbility():GetSpecialValueFor("crit_per_missing_mana")
            local critPerBase = self:GetAbility():GetSpecialValueFor("crit_base_per_missing_mana")

            crit = crit + ((missingMana/critPerMana)*critPerBase)

            if RollPercentage(chance) then
                self.record = params.record

                return crit
            end
        end
    end
end

function modifier_gabriel_heavenly_balance:GetModifierProcAttack_Feedback(params)
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end
end