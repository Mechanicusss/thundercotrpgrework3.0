LinkLuaModifier("modifier_player_difficulty_buff_damage_reduction_50", "modifiers/modes/buffs/easy/modifier_player_difficulty_buff_damage_reduction_50", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

player_difficulty_buff_damage_reduction_50 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_buff_damage_reduction_50 = class(ItemBaseClass)

function player_difficulty_buff_damage_reduction_50:GetIntrinsicModifierName()
    return "modifier_player_difficulty_buff_damage_reduction_50"
end

function modifier_player_difficulty_buff_damage_reduction_50:GetTexture() return "shield" end
-------------
function modifier_player_difficulty_buff_damage_reduction_50:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,  
    }

    return funcs
end

function modifier_player_difficulty_buff_damage_reduction_50:GetModifierIncomingDamage_Percentage(event)
    if event.attacker ~= self:GetParent() then return end

    local attacker = event.attacker
    local victim = event.target

    if attacker == victim then return end

    return 50
end