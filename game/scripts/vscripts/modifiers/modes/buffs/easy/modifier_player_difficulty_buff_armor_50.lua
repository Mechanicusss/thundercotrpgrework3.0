LinkLuaModifier("modifier_player_difficulty_buff_armor_50", "modifiers/modes/buffs/easy/modifier_player_difficulty_buff_armor_50", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

player_difficulty_buff_armor_50 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_buff_armor_50 = class(ItemBaseClass)

function player_difficulty_buff_armor_50:GetIntrinsicModifierName()
    return "modifier_player_difficulty_buff_armor_50"
end

function modifier_player_difficulty_buff_armor_50:GetTexture() return "shield" end
-------------
function modifier_player_difficulty_buff_armor_50:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,  
    }

    return funcs
end

function modifier_player_difficulty_buff_armor_50:GetModifierPhysicalArmorBonus()
    return 50
end