LinkLuaModifier("modifier_enemy_difficulty_buff_hp_regen_pct_1_5", "modifiers/modes/buffs/hard/modifier_enemy_difficulty_buff_hp_regen_pct_1_5", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_hp_regen_pct_1_5 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_hp_regen_pct_1_5 = class(ItemBaseClass)

function enemy_difficulty_buff_hp_regen_pct_1_5:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_hp_regen_pct_1_5"
end

function modifier_enemy_difficulty_buff_hp_regen_pct_1_5:GetTexture() return "heart" end
-------------
function modifier_enemy_difficulty_buff_hp_regen_pct_1_5:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,  
    }

    return funcs
end

function modifier_enemy_difficulty_buff_hp_regen_pct_1_5:GetModifierHealthRegenPercentage()
    return 1.5
end