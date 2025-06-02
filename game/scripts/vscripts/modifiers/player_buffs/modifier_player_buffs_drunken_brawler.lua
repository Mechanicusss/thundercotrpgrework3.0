-- WARNING: THE ANTI-HEAL IS DONE IN THE HEALING FILTER
LinkLuaModifier("modifier_player_buffs_drunken_brawler", "modifiers/player_buffs/modifier_player_buffs_drunken_brawler", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_buffs_drunken_brawler_buff", "modifiers/player_buffs/modifier_player_buffs_drunken_brawler", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_drunken_brawler_buff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_drunken_brawler = class(ItemBaseClass)

function modifier_player_buffs_drunken_brawler:GetIntrinsicModifierName()
    return "modifier_player_buffs_drunken_brawler"
end

function modifier_player_buffs_drunken_brawler:GetTexture() return "player_buffs/modifier_player_buffs_drunken_brawler" end
-------------
function modifier_player_buffs_drunken_brawler:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(3)
end

function modifier_player_buffs_drunken_brawler:OnIntervalThink()
    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_player_buffs_drunken_brawler_buff")

    parent:AddNewModifier(parent, self:GetAbility(), "modifier_player_buffs_drunken_brawler_buff", {
        duration = 3
    })
end
--------------------
function modifier_player_buffs_drunken_brawler_buff:OnCreated()
    self.amount = RandomInt(-50, 200)
end

function modifier_player_buffs_drunken_brawler_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_player_buffs_drunken_brawler_buff:GetModifierDamageOutgoing_Percentage()
    return self.amount
end