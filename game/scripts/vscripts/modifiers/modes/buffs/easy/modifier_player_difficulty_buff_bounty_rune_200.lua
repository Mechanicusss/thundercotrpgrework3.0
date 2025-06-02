LinkLuaModifier("modifier_player_difficulty_buff_bounty_rune_200", "modifiers/modes/buffs/easy/modifier_player_difficulty_buff_bounty_rune_200", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

player_difficulty_buff_bounty_rune_200 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_buff_bounty_rune_200 = class(ItemBaseClass)

function player_difficulty_buff_bounty_rune_200:GetIntrinsicModifierName()
    return "modifier_player_difficulty_buff_bounty_rune_200"
end

function modifier_player_difficulty_buff_bounty_rune_200:GetTexture() return "bounty" end
-------------