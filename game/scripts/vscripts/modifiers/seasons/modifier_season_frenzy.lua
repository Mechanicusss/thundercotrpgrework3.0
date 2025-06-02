LinkLuaModifier("modifier_season_frenzy", "modifiers/seasons/modifier_season_frenzy", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

modifier_season_frenzy = class(ItemBaseClass)

function modifier_season_frenzy:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE --GetModifierTotalDamageOutgoing_Percentage
    }
end

function modifier_season_frenzy:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.target:IsRangedAttacker() then
        return 100
    end
end

function modifier_season_frenzy:GetModifierMoveSpeedBonus_Percentage()
    return 25
end

function modifier_season_frenzy:GetModifierStatusResistance()
    return 25
end

function modifier_season_frenzy:GetModifierMagicalResistanceBonus()
    return 25
end

function modifier_season_frenzy:GetTexture() return "furbolg_enrage_damage" end
function modifier_season_frenzy:GetPriority() return 9999 end