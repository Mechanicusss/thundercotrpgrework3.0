
local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

modifier_elemental_ailment_cold = class(BaseClass)
----------------------------------------------------------------
function modifier_elemental_ailment_cold:OnCreated()
    if not IsServer() then return end 
end

function modifier_elemental_ailment_cold:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }
end

function modifier_elemental_ailment_cold:GetModifierMoveSpeedBonus_Percentage()
    return -2 * self:GetStackCount()
end

function modifier_elemental_ailment_cold:GetModifierAttackSpeedBonus_Constant()
    return -1 * self:GetStackCount()
end

function modifier_elemental_ailment_cold:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end