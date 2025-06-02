LinkLuaModifier("modifier_xp_all_talent_4", "abilities/talents/all/xp_all_talent_4", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_all_talent_4 = class(ItemBaseClass)
modifier_xp_all_talent_4 = class(xp_all_talent_4)
-------------
function xp_all_talent_4:GetIntrinsicModifierName()
    return "modifier_xp_all_talent_4"
end
-------------
function modifier_xp_all_talent_4:OnCreated()
    self.maxThreshold = 50
    self.range = 100 - self.maxThreshold
    self.maxValuePctHpRegen = (0.5 * self:GetStackCount())

    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.ability = ability

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_xp_all_talent_4:OnIntervalThink()
    local abilityName = self:GetName()

    if _G.FinalGameWavesEnabled then
        _G.PlayerDamageReduction[self.accountID][abilityName] = 1 * self:GetStackCount()
    else 
        _G.PlayerDamageReduction[self.accountID][abilityName] = nil
    end
end

function modifier_xp_all_talent_4:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end