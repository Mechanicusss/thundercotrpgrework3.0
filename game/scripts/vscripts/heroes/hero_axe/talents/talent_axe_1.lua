LinkLuaModifier("modifier_talent_axe_1", "heroes/hero_axe/talents/talent_axe_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_axe_1 = class(ItemBaseClass)
modifier_talent_axe_1 = class(talent_axe_1)
-------------
function talent_axe_1:GetIntrinsicModifierName()
    return "modifier_talent_axe_1"
end
-------------
function modifier_talent_axe_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_talent_axe_1:GetModifierMoveSpeedBonus_Percentage()
    if self:GetAbility():GetLevel() > 2 and self:GetCaster():HasModifier("modifier_axe_counter_helix_custom_toggle") then
        return self:GetAbility():GetSpecialValueFor("bonus_speed_pct")
    end
end

function modifier_talent_axe_1:GetModifierTotalDamageOutgoing_Percentage()
    if self:GetAbility():GetLevel() > 2 and self:GetCaster():HasModifier("modifier_axe_counter_helix_custom_toggle") then
        return self:GetCaster():GetMoveSpeedModifier(self:GetCaster():GetBaseMoveSpeed(), true) * (self:GetAbility():GetSpecialValueFor("damage_from_speed_pct")/100)
    end
end