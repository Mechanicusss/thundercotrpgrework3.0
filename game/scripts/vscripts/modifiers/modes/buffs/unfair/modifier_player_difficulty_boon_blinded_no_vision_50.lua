LinkLuaModifier("modifier_player_difficulty_boon_blinded_no_vision_50", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_blinded_no_vision_50", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_blinded_no_vision_50 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_blinded_no_vision_50 = class(ItemBaseClass)

function player_difficulty_boon_blinded_no_vision_50:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_blinded_no_vision_50"
end

function modifier_player_difficulty_boon_blinded_no_vision_50:GetTexture() return "blur" end
-------------
function modifier_player_difficulty_boon_blinded_no_vision_50:GetPriority()
    return 99
end

function modifier_player_difficulty_boon_blinded_no_vision_50:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MISS_PERCENTAGE,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
    }
    return funcs
end

function modifier_player_difficulty_boon_blinded_no_vision_50:CheckState()
    local state = {
        [MODIFIER_STATE_PROVIDES_VISION] = false,
        [MODIFIER_STATE_BLIND] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    }
    return state
end

function modifier_player_difficulty_boon_blinded_no_vision_50:GetModifierMiss_Percentage()
    return 30
end

function modifier_player_difficulty_boon_blinded_no_vision_50:GetModifierProvidesFOWVision()
    return 0
end