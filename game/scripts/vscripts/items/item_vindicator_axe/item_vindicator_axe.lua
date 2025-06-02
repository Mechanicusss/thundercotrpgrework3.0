LinkLuaModifier("modifier_item_vindicator_axe", "items/item_vindicator_axe/item_vindicator_axe", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_vindicator_axe = class(ItemBaseClass)
modifier_item_vindicator_axe = class(item_vindicator_axe)
-------------
function item_vindicator_axe:GetIntrinsicModifierName()
    return "modifier_item_vindicator_axe"
end

function modifier_item_vindicator_axe:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_vindicator_axe:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_vindicator_axe:GetModifierDamageOutgoing_Percentage()
    local parent = self:GetParent()
    local healthPercent = (parent:GetHealth() / parent:GetMaxHealth()) * 100

    if healthPercent >= self:GetAbility():GetSpecialValueFor("bonus_damage_hp_threshold") then
        return healthPercent - self:GetAbility():GetSpecialValueFor("bonus_damage_per_pct_hp")
    end
end

function modifier_item_vindicator_axe:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_item_vindicator_axe:OnIntervalThink()
    local abilityName = self:GetName()
    
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    if self:GetParent():GetHealthPercent() < self:GetAbility():GetSpecialValueFor("bonus_damage_hp_threshold") then
        _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("bonus_damage_reduction")
    end
end

function modifier_item_vindicator_axe:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end