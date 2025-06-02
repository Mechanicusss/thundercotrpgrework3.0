LinkLuaModifier("modifier_xp_strength_talent_7", "abilities/talents/strength/xp_strength_talent_7", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_strength_talent_7 = class(ItemBaseClass)
modifier_xp_strength_talent_7 = class(xp_strength_talent_7)
-------------
function xp_strength_talent_7:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_7"
end
-------------
function modifier_xp_strength_talent_7:OnCreated()
    self.maxThreshold = 50
    self.range = 100 - self.maxThreshold
    self.maxValuePctHpRegen = (0.25 * self:GetStackCount())

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

function modifier_xp_strength_talent_7:OnIntervalThink()
    local abilityName = self:GetName()

    local pct = math.max((self:GetParent():GetHealthPercent()-self.maxThreshold)/self.range,0)
    local dr = (1-pct)*(1.5 * self:GetStackCount())

    _G.PlayerDamageReduction[self.accountID][abilityName] = dr
end

function modifier_xp_strength_talent_7:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_xp_strength_talent_7:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE   
    }
end

function modifier_xp_strength_talent_7:GetModifierHealthRegenPercentage()
    local pct = math.max((self:GetParent():GetHealthPercent()-self.maxThreshold)/self.range,0)
    local regen = (1-pct)*self.maxValuePctHpRegen

    return regen
end

