modifier_aghanim_mystic_flare_debuff = class({})
----------------------------------------------------------
function modifier_aghanim_mystic_flare_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_aghanim_mystic_flare_debuff:GetModifierMagicalResistanceBonus()
    return -100
end

function modifier_aghanim_mystic_flare_debuff:IsDebuff() return true end
function modifier_aghanim_mystic_flare_debuff:RemoveOnDeath() return true end