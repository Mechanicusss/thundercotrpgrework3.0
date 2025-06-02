LinkLuaModifier("modifier_item_pendant_of_chronos", "items/chronos/item_pendant_of_chronos", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_pendant_of_chronos_active", "items/chronos/item_pendant_of_chronos", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_pendant_of_chronos_active_counter", "items/chronos/item_pendant_of_chronos", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassCounter = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

item_pendant_of_chronos = class(ItemBaseClass)
item_pendant_of_chronos_2 = item_pendant_of_chronos
item_pendant_of_chronos_3 = item_pendant_of_chronos
item_pendant_of_chronos_4 = item_pendant_of_chronos
item_pendant_of_chronos_5 = item_pendant_of_chronos
item_pendant_of_chronos_6 = item_pendant_of_chronos
modifier_item_pendant_of_chronos = class(ItemBaseClass)
modifier_item_pendant_of_chronos_active = class(ItemBaseClassActive)
modifier_item_pendant_of_chronos_active_counter = class(ItemBaseClassCounter)
-------------
function item_pendant_of_chronos:GetIntrinsicModifierName()
    return "modifier_item_pendant_of_chronos"
end

function item_pendant_of_chronos:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    
    caster:AddNewModifier(caster, ability, "modifier_item_pendant_of_chronos_active", { duration = duration })
end
---
function modifier_item_pendant_of_chronos:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS , --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_MANA_BONUS , --GetModifierManaBonus
    }

    return funcs
end

function modifier_item_pendant_of_chronos:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("spell_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_pendant_of_chronos:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("int", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_pendant_of_chronos:GetModifierManaBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_pendant_of_chronos:OnCreated()
    if not IsServer() then return end

    --self:StartIntervalThink(0.1)
end

function modifier_item_pendant_of_chronos:OnIntervalThink()
    local caster = self:GetCaster()

    if caster:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_INTELLECT then
        caster:DropItemAtPositionImmediate(self:GetAbility(), caster:GetAbsOrigin())
        DisplayError(caster:GetPlayerID(), "#primary_intellect_item")
    end

    self:StartIntervalThink(-1)
end
---
function modifier_item_pendant_of_chronos_active:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST, --OnAbilityFullyCast
    }

    return funcs
end

function modifier_item_pendant_of_chronos_active:OnAbilityFullyCast(event)
    local caster = self:GetCaster()

    if caster ~= event.unit then return end
    if event.ability:IsItem() then return end
    if event.ability:GetAbilityType() == ABILITY_TYPE_ULTIMATE or event.ability:GetBehaviorInt() == DOTA_ABILITY_BEHAVIOR_PASSIVE then return end

    if not caster:HasModifier("modifier_item_pendant_of_chronos_active_counter") then
        caster:AddNewModifier(caster, self:GetAbility(), "modifier_item_pendant_of_chronos_active_counter", { duration = self.duration })
    end

    if caster:HasModifier("modifier_item_pendant_of_chronos_active_counter") then
        local mod = caster:FindModifierByNameAndCaster("modifier_item_pendant_of_chronos_active_counter", caster)
        mod:SetStackCount(mod:GetStackCount() + event.ability:GetManaCost(event.ability:GetLevel()))
    end

    event.ability:StartCooldown(0.5)
end

function modifier_item_pendant_of_chronos_active:OnCreated(params)
    self.mana = 0

    self.duration = params.duration

    if IsServer() then self:StartIntervalThink(0.1) return end
end

function modifier_item_pendant_of_chronos_active:OnIntervalThink()
    local burn = (self:GetCaster():GetMaxMana() * (self:GetAbility():GetSpecialValueFor("mana_per_sec_pct")/100))/10

    if burn > self:GetCaster():GetMana() then  
        self:GetCaster():RemoveModifierByNameAndCaster("modifier_item_pendant_of_chronos_active", self:GetCaster())
        self:GetCaster():RemoveModifierByNameAndCaster("modifier_item_pendant_of_chronos_active_counter", self:GetCaster()) 
        return 
    end

    self:GetCaster():SpendMana(burn, self:GetAbility())
end
---
function modifier_item_pendant_of_chronos_active_counter:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_pendant_of_chronos_active_counter:OnDestroy()
    if not IsServer() then return end

    local damage = self:GetStackCount()

    ApplyDamage({
        victim = self:GetCaster(), 
        attacker = self:GetCaster(), 
        damage = damage, 
        damage_type = DAMAGE_TYPE_MAGICAL
    })
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, self:GetCaster(), damage, nil)
end