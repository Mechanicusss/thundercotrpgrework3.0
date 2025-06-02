LinkLuaModifier("modifier_item_eloshar_bracelet", "items/item_eloshar_bracelet/item_eloshar_bracelet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_eloshar_bracelet_stacks", "items/item_eloshar_bracelet/item_eloshar_bracelet", LUA_MODIFIER_MOTION_NONE)

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

item_eloshar_bracelet = class(ItemBaseClass)
modifier_item_eloshar_bracelet = class(item_eloshar_bracelet)
modifier_item_eloshar_bracelet_stacks = class(ItemBaseClassBuff)
-------------
function item_eloshar_bracelet:GetIntrinsicModifierName()
    return "modifier_item_eloshar_bracelet"
end

function modifier_item_eloshar_bracelet:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_eloshar_bracelet:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_eloshar_bracelet:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_eloshar_bracelet:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_eloshar_bracelet:GetModifierHealthRegenPercentage()
    return self.fRegen
end

function modifier_item_eloshar_bracelet:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    local ability = self:GetAbility()
    local interval = ability:GetSpecialValueFor("grace_timer")

    self.regen = ability:GetSpecialValueFor("hp_regen_pct")

    self:InvokeBonusRegen()

    self:StartIntervalThink(interval)
end

function modifier_item_eloshar_bracelet:OnIntervalThink()    
    local ability = self:GetAbility()
    local interval = ability:GetSpecialValueFor("grace_timer")

    self.regen = ability:GetSpecialValueFor("hp_regen_pct")

    self:InvokeBonusRegen()
end

function modifier_item_eloshar_bracelet:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end

    local ability = self:GetAbility()
    local interval = ability:GetSpecialValueFor("grace_timer")

    local stacks = parent:FindModifierByName("modifier_item_eloshar_bracelet_stacks")
    if not stacks then
        stacks = parent:AddNewModifier(parent, ability, "modifier_item_eloshar_bracelet_stacks", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if stacks then
        if stacks:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            stacks:IncrementStackCount()
        end

        stacks:ForceRefresh()
    end

    self.regen = 0
    self:InvokeBonusRegen()

    self:StartIntervalThink(-1)
    self:StartIntervalThink(interval)
end

function modifier_item_eloshar_bracelet:AddCustomTransmitterData()
    return
    {
        regen = self.fRegen,
    }
end

function modifier_item_eloshar_bracelet:HandleCustomTransmitterData(data)
    if data.regen ~= nil then
        self.fRegen = tonumber(data.regen)
    end
end

function modifier_item_eloshar_bracelet:InvokeBonusRegen()
    if IsServer() == true then
        self.fRegen = self.regen

        self:SendBuffRefreshToClients()
    end
end
--------------------------
function modifier_item_eloshar_bracelet_stacks:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT 
    }
end

function modifier_item_eloshar_bracelet_stacks:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("mana_regen_per_stack") * self:GetStackCount()
end

function modifier_item_eloshar_bracelet_stacks:GetTexture() return "elosharbracelet" end