LinkLuaModifier("modifier_player_buffs_status_boost", "modifiers/player_buffs/modifier_player_buffs_status_boost", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_status_boost = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_status_boost = class(ItemBaseClass)

function modifier_player_buffs_status_boost:GetIntrinsicModifierName()
    return "modifier_player_buffs_status_boost"
end

function modifier_player_buffs_status_boost:GetTexture() return "player_buffs/modifier_player_buffs_status_boost" end
-------------
function modifier_player_buffs_status_boost:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function modifier_player_buffs_status_boost:GetModifierStatusResistance()
    return 95
end

function modifier_player_buffs_status_boost:GetModifierIncomingDamage_Percentage()
    return 40
end
