LinkLuaModifier("modifier_spectre_phase_custom", "spectre_phase_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_phase_custom_phasing_state", "spectre_phase_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAbsorb = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

spectre_phase_custom = class(ItemBaseClass)
modifier_spectre_phase_custom = class(spectre_phase_custom)
modifier_spectre_phase_custom_phasing_state = class(ItemBaseClassAbsorb)
-------------
function spectre_phase_custom:GetIntrinsicModifierName()
    return "modifier_spectre_phase_custom_phasing_state"
end
------------
function modifier_spectre_phase_custom_phasing_state:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  
    }

    return funcs
end

function modifier_spectre_phase_custom_phasing_state:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }

    return state
end

function modifier_spectre_phase_custom_phasing_state:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_speed", (self:GetAbility():GetLevel() - 1))
end