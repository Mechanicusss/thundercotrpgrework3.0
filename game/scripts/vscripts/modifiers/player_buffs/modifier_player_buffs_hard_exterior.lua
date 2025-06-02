LinkLuaModifier("modifier_player_buffs_hard_exterior", "modifiers/player_buffs/modifier_player_buffs_hard_exterior", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_hard_exterior = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_hard_exterior = class(ItemBaseClass)

function modifier_player_buffs_hard_exterior:GetIntrinsicModifierName()
    return "modifier_player_buffs_hard_exterior"
end

function modifier_player_buffs_hard_exterior:GetTexture() return "player_buffs/modifier_player_buffs_hard_exterior" end
-------------
function modifier_player_buffs_hard_exterior:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function modifier_player_buffs_hard_exterior:GetModifierTotalDamageOutgoing_Percentage()
    return -50
end

function modifier_player_buffs_hard_exterior:GetModifierMoveSpeedBonus_Percentage()
    return -50
end

function modifier_player_buffs_hard_exterior:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.ability = ability

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = 50
end

function modifier_player_buffs_hard_exterior:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end