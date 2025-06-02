LinkLuaModifier("modifier_player_buffs_glasscannon", "modifiers/player_buffs/modifier_player_buffs_glasscannon", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_glasscannon = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_glasscannon = class(ItemBaseClass)

function modifier_player_buffs_glasscannon:GetIntrinsicModifierName()
    return "modifier_player_buffs_glasscannon"
end

function modifier_player_buffs_glasscannon:GetTexture() return "player_buffs/modifier_player_buffs_glasscannon" end
-------------
function modifier_player_buffs_glasscannon:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function modifier_player_buffs_glasscannon:GetModifierTotalDamageOutgoing_Percentage()
    return 100
end

function modifier_player_buffs_glasscannon:GetModifierIncomingDamage_Percentage(event)
    if event.attacker:GetTeam() ~= self:GetParent():GetTeam() then
        return 100
    end
end
