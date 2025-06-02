-- WARNING: THE ANTI-HEAL IS DONE IN THE HEALING FILTER
LinkLuaModifier("modifier_player_buffs_vulnerable", "modifiers/player_buffs/modifier_player_buffs_vulnerable", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_vulnerable = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_vulnerable = class(ItemBaseClass)

function modifier_player_buffs_vulnerable:GetIntrinsicModifierName()
    return "modifier_player_buffs_vulnerable"
end

function modifier_player_buffs_vulnerable:GetTexture() return "player_buffs/modifier_player_buffs_vulnerable" end
-------------
function modifier_player_buffs_vulnerable:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }
end

function modifier_player_buffs_vulnerable:GetModifierExtraHealthPercentage()
    return 25
end

function modifier_player_buffs_vulnerable:GetModifierMagicalResistanceBonus()
    return 50
end

function modifier_player_buffs_vulnerable:GetModifierPhysicalArmorBonus()
    return self:GetParent():GetStrength() * 0.5
end

function modifier_player_buffs_vulnerable:GetModifierHPRegenAmplify_Percentage()
    return -999
end

function modifier_player_buffs_vulnerable:GetModifierLifestealRegenAmplify_Percentage()
    return -999
end

function modifier_player_buffs_vulnerable:GetModifierSpellLifestealRegenAmplify_Percentage()
    return -999
end