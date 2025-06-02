LinkLuaModifier("modifier_talent_primal_beast_1", "heroes/hero_primal_beast/talents/talent_primal_beast_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_primal_beast_1 = class(ItemBaseClass)
modifier_talent_primal_beast_1 = class(talent_primal_beast_1)
-------------
function talent_primal_beast_1:GetIntrinsicModifierName()
    return "modifier_talent_primal_beast_1"
end
-------------
function modifier_talent_primal_beast_1:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(FrameTime())
end

function modifier_talent_primal_beast_1:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())
    local abilityName = self:GetName()

    if ability:GetLevel() < 3 or not parent:HasModifier("modifier_primal_beast_onslaught_custom") then 
        _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
        _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

        _G.PlayerDamageReduction[self.accountID][abilityName] = nil
        return 
    end
    
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function modifier_talent_primal_beast_1:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end