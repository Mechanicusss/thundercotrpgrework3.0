LinkLuaModifier("modifier_viper_nethertoxin_custom", "heroes/hero_viper/viper_nethertoxin_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

viper_nethertoxin_custom = class(ItemBaseClass)
modifier_viper_nethertoxin_custom = class(viper_nethertoxin_custom)
-------------
function viper_nethertoxin_custom:GetIntrinsicModifierName()
    return "modifier_viper_nethertoxin_custom"
end
------------
function modifier_viper_nethertoxin_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_viper_nethertoxin_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    local parent = self:GetParent()
    local target = event.target

    local hpMissing = target:GetMaxHealth() - target:GetHealth()
    local pct = (hpMissing / target:GetMaxHealth()) * 100 
    local multiplier = pct  / self:GetAbility():GetSpecialValueFor("damage_pct_per_missing")

    local bonus = self:GetAbility():GetSpecialValueFor("bonus_damage_pct") * multiplier

    return bonus
end