LinkLuaModifier("modifier_item_helm_of_the_gladiator", "items/item_helm_of_the_gladiator/item_helm_of_the_gladiator", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_helm_of_the_gladiator_stacks", "items/item_helm_of_the_gladiator/item_helm_of_the_gladiator", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_helm_of_the_gladiator = class(ItemBaseClass)
modifier_item_helm_of_the_gladiator = class(item_helm_of_the_gladiator)
modifier_item_helm_of_the_gladiator_stacks = class(ItemBaseClassBuff)
-------------
function item_helm_of_the_gladiator:GetIntrinsicModifierName()
    return "modifier_item_helm_of_the_gladiator"
end
-------------
function modifier_item_helm_of_the_gladiator:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_helm_of_the_gladiator:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end

    local ability = self:GetAbility()

    local stacks = parent:FindModifierByName("modifier_item_helm_of_the_gladiator_stacks")
    if not stacks then
        stacks = parent:AddNewModifier(parent, ability, "modifier_item_helm_of_the_gladiator_stacks", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if stacks then
        if stacks:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            stacks:IncrementStackCount()
        end

        stacks:ForceRefresh()
    end
end
-------------
function modifier_item_helm_of_the_gladiator_stacks:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_item_helm_of_the_gladiator_stacks:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_per_stack") * self:GetStackCount()
end

function modifier_item_helm_of_the_gladiator_stacks:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.ability = ability

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("damage_reduction_per_stack") * self:GetStackCount()

    self:StartIntervalThink(0.1)
end

function modifier_item_helm_of_the_gladiator_stacks:OnIntervalThink()
    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("damage_reduction_per_stack") * self:GetStackCount()
end

function modifier_item_helm_of_the_gladiator_stacks:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end