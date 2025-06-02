LinkLuaModifier("modifier_player_difficulty_boon_blinded_30", "modifiers/modes/buffs/hard/modifier_player_difficulty_boon_blinded_30", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_blinded_30 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_blinded_30 = class(ItemBaseClass)

function player_difficulty_boon_blinded_30:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_blinded_30"
end

function modifier_player_difficulty_boon_blinded_30:GetTexture() return "blur" end
-------------

function modifier_player_difficulty_boon_blinded_30:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MISS_PERCENTAGE,
        MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
        MODIFIER_PROPERTY_BONUS_DAY_VISION,
    }
    return funcs
end

function modifier_player_difficulty_boon_blinded_30:GetModifierMiss_Percentage()
    return 30
end

function modifier_player_difficulty_boon_blinded_30:GetBonusNightVision()
    return -500
end

function modifier_player_difficulty_boon_blinded_30:GetBonusDayVision()
    return -500
end