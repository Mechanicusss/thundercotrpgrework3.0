LinkLuaModifier("modifier_sven_greatsword_technique", "heroes/hero_sven/sven_greatsword_technique", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

sven_greatsword_technique = class(ItemBaseClass)
modifier_sven_greatsword_technique = class(sven_greatsword_technique)
-------------
function sven_greatsword_technique:GetIntrinsicModifierName()
    return "modifier_sven_greatsword_technique"
end

function sven_greatsword_technique:GetAbilityTextureName()
    local texture = "greatswordtechnique"

    if self:GetCaster():HasModifier("modifier_sven_gods_strength_custom") and self:GetCaster():HasScepter() then
        texture = "greatswordtechnique_godsstrength"
    end

    return texture
end

function modifier_sven_greatsword_technique:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE     
    }
    return funcs
end

function modifier_sven_greatsword_technique:GetModifierDamageOutgoing_Percentage()
    local mult = 1

    if self:GetCaster():HasModifier("modifier_sven_gods_strength_custom") and self:GetCaster():HasScepter() then
        mult = self:GetAbility():GetSpecialValueFor("gods_strength_multiplier")
    end

    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct") * mult
end

function modifier_sven_greatsword_technique:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("attack_speed_penalty")
end