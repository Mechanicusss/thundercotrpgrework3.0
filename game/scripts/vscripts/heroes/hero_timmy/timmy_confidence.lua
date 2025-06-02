LinkLuaModifier("modifier_timmy_confidence", "heroes/hero_timmy/timmy_confidence", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

timmy_confidence = class(ItemBaseClass)
modifier_timmy_confidence = class(timmy_confidence)
-------------
function timmy_confidence:GetIntrinsicModifierName()
    return "modifier_timmy_confidence"
end
------------
function modifier_timmy_confidence:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_STATUS_RESISTANCE  
    }
end

function modifier_timmy_confidence:GetModifierModelChange()
    if self:GetAbility():GetLevel() < 2 then return "models/creeps/lane_creeps/creep_radiant_melee/radiant_flagbearer.vmdl" end
    return "models/creeps/lane_creeps/creep_radiant_melee/radiant_melee_mega_crystal_flagbearer.vmdl"
end

function modifier_timmy_confidence:GetModifierModelScale()
    if self:GetAbility():GetLevel() < 2 then return end
    return 10
end

function modifier_timmy_confidence:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_resistance")
end

function modifier_timmy_confidence:GetModifierStatusResistance()
    return self:GetAbility():GetSpecialValueFor("status_resistance")
end

function modifier_timmy_confidence:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if self:GetAbility():GetLevel() < 2 then return end

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function modifier_timmy_confidence:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end