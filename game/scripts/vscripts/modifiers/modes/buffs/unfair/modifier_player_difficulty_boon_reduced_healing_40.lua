LinkLuaModifier("modifier_player_difficulty_boon_reduced_healing_40", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_reduced_healing_40", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_reduced_healing_40 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_reduced_healing_40 = class(ItemBaseClass)

function player_difficulty_boon_reduced_healing_40:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_reduced_healing_40"
end

function modifier_player_difficulty_boon_reduced_healing_40:GetTexture() return "anti_heal" end

function modifier_player_difficulty_boon_reduced_healing_40:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }

    return funcs
end

function modifier_player_difficulty_boon_reduced_healing_40:GetModifierHealAmplify_PercentageTarget()
    return -40
end

function modifier_player_difficulty_boon_reduced_healing_40:GetModifierHPRegenAmplify_Percentage()
    return -40
end

function modifier_player_difficulty_boon_reduced_healing_40:GetModifierLifestealRegenAmplify_Percentage()
    return -40
end

function modifier_player_difficulty_boon_reduced_healing_40:GetModifierSpellLifestealRegenAmplify_Percentage()
    return -40
end
-------------