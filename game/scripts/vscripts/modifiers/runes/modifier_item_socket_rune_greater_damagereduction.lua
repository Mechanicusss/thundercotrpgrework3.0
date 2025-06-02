LinkLuaModifier("modifier_item_socket_rune_greater_damagereduction", "modifiers/runes/modifier_item_socket_rune_greater_damagereduction", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_greater_damagereduction = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_greater_damagereduction:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_item_socket_rune_greater_damagereduction:OnIntervalThink()
    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID][abilityName] = 2.5 * self:GetStackCount()
end

function modifier_item_socket_rune_greater_damagereduction:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end