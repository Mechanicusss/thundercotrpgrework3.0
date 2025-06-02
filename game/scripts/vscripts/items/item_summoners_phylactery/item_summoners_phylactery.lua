LinkLuaModifier("modifier_item_summoners_phylactery", "items/item_summoners_phylactery/item_summoners_phylactery", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_summoners_phylactery_aura", "items/item_summoners_phylactery/item_summoners_phylactery", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_summoners_phylactery = class(ItemBaseClass)
item_summoners_phylactery2 = item_summoners_phylactery
item_summoners_phylactery3 = item_summoners_phylactery
item_summoners_phylactery4 = item_summoners_phylactery
item_summoners_phylactery5 = item_summoners_phylactery
item_summoners_phylactery6 = item_summoners_phylactery
item_summoners_phylactery7 = item_summoners_phylactery
item_summoners_phylactery8 = item_summoners_phylactery
item_summoners_phylactery9 = item_summoners_phylactery
modifier_item_summoners_phylactery = class(item_summoners_phylactery)
modifier_item_summoners_phylactery_aura = class(ItemBaseClassBuff)
-------------
function item_summoners_phylactery:GetIntrinsicModifierName()
    return "modifier_item_summoners_phylactery"
end
-------------
function modifier_item_summoners_phylactery:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.ability = ability

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    self.summons = 0

    self:OnIntervalThink()
    self:StartIntervalThink(FrameTime())
end

function modifier_item_summoners_phylactery:OnIntervalThink()
    local abilityName = self:GetName()

    local reduction = self:GetAbility():GetSpecialValueFor("damage_reduction_per_unit") * self.summons

    local maxReduction = self:GetAbility():GetSpecialValueFor("max_damage_reduction")

    if reduction < maxReduction then
        reduction = maxReduction 
    end

    _G.PlayerDamageReduction[self.accountID][abilityName] = reduction
end

function modifier_item_summoners_phylactery:OnRemoved()
    if not IsServer() then return end 

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil

    self.summons = 0
end

function modifier_item_summoners_phylactery:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT 
    }
end

function modifier_item_summoners_phylactery:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_summoners_phylactery:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_summoners_phylactery:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_summoners_phylactery:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_summoners_phylactery:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_summoners_phylactery:GetModifierTotalDamageOutgoing_Percentage()
    if IsServer() then
        local outgoing = self:GetAbility():GetSpecialValueFor("outgoing_damage_per_unit") * self.summons

        return outgoing
    end
end

function modifier_item_summoners_phylactery:IsAura()
    return true
end

function modifier_item_summoners_phylactery:GetAuraSearchType()
    return DOTA_UNIT_TARGET_BASIC
end

function modifier_item_summoners_phylactery:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_summoners_phylactery:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_summoners_phylactery:GetModifierAura()
    return "modifier_item_summoners_phylactery_aura"
end

function modifier_item_summoners_phylactery:GetAuraEntityReject(target)
    -- Reject non-summons
    if not IsSummonTCOTRPG(target) then return true end 

    -- Reject summons that don't belong to the wearer
    if target:GetOwner() ~= self:GetCaster() then return true end 
    
    return false
end
----------
function modifier_item_summoners_phylactery_aura:OnCreated()
    if not IsServer() then return end 

    local mod = self:GetCaster():FindModifierByName("modifier_item_summoners_phylactery")
    if not mod or mod == nil then return end
    if not mod.summons then return end 

    mod.summons = mod.summons + 1
end

function modifier_item_summoners_phylactery_aura:OnRemoved()
    if not IsServer() then return end 

    local mod = self:GetCaster():FindModifierByName("modifier_item_summoners_phylactery")
    if not mod or mod == nil then return end
    if not mod.summons then return end 

    mod.summons = mod.summons - 1

    if mod.summons < 0 then
        mod.summons = 0
    end
end

function modifier_item_summoners_phylactery_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_item_summoners_phylactery_aura:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_reduction_summons")
end

function modifier_item_summoners_phylactery_aura:GetModifierTotalDamageOutgoing_Percentage()
    if IsServer() then
        local mod = self:GetCaster():FindModifierByName("modifier_item_summoners_phylactery")
        if not mod or mod == nil then return end
        if not mod.summons then return end 

        local outgoing = self:GetAbility():GetSpecialValueFor("outgoing_damage_per_unit") * mod.summons

        return outgoing
    end
end