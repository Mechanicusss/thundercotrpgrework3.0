-- WARNING: THE ANTI-HEAL IS DONE IN THE HEALING FILTER
LinkLuaModifier("modifier_player_buffs_mana_curse", "modifiers/player_buffs/modifier_player_buffs_mana_curse", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}


modifier_player_buffs_mana_curse = class(ItemBaseClass)

function modifier_player_buffs_mana_curse:GetIntrinsicModifierName()
    return "modifier_player_buffs_mana_curse"
end

function modifier_player_buffs_mana_curse:GetTexture() return "player_buffs/modifier_player_buffs_mana_curse" end
-------------
function modifier_player_buffs_mana_curse:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_MANA_PERCENTAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_player_buffs_mana_curse:GetModifierExtraManaPercentage()
    return -75
end

function modifier_player_buffs_mana_curse:GetModifierTotalDamageOutgoing_Percentage()
    return 80
end