LinkLuaModifier("modifier_item_aghanims_robe", "items/aghanims_robe/item_aghanims_robe", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_aghanims_robe_active", "items/aghanims_robe/item_aghanims_robe", LUA_MODIFIER_MOTION_NONE)

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

item_aghanims_robe = class(ItemBaseClass)
item_aghanims_robe_2 = item_aghanims_robe
item_aghanims_robe_3 = item_aghanims_robe
item_aghanims_robe_4 = item_aghanims_robe
item_aghanims_robe_5 = item_aghanims_robe
item_aghanims_robe_6 = item_aghanims_robe
modifier_item_aghanims_robe = class(item_aghanims_robe)
modifier_item_aghanims_robe_active = class(ItemBaseClassActive)

function modifier_item_aghanims_robe_active:GetTexture() return "aghanims_robe" end
-------------
function item_aghanims_robe:GetIntrinsicModifierName()
    return "modifier_item_aghanims_robe"
end

function item_aghanims_robe:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_item_aghanims_robe_active", {
        duration = self:GetSpecialValueFor("duration")
    })
end

function modifier_item_aghanims_robe:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    if not IsServer() then return end

    self:StartIntervalThink(0.5)
end

function modifier_item_aghanims_robe:OnIntervalThink()
    self:OnRefresh()
end

function modifier_item_aghanims_robe:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()
    local flowHp = self:GetAbility():GetSpecialValueFor("mana_flow_hp")
    local flowMana = self:GetAbility():GetSpecialValueFor("mana_flow_mana")
    local maxSpellDamage = self:GetAbility():GetSpecialValueFor("max_spell_amp")

    self.manaRegen = (parent:GetMaxHealth()) * (flowMana/100)
    self.hpRegen = (parent:GetMaxMana()) * (flowHp/100)

    self.spellAmp = self:GetAbility():GetSpecialValueFor("spell_amp") + (parent:GetManaRegen() * (self:GetAbility():GetSpecialValueFor("mana_regen_spell_amp")/100))

    if self.spellAmp > maxSpellDamage then
        self.spellAmp = maxSpellDamage
    end
    
    if parent:HasModifier("modifier_item_aghanims_robe_active") then
        self.manaRegen = self.manaRegen * 2
        self.hpRegen = self.hpRegen * 2
    end

    if not parent:HasModifier("modifier_fountain_aura_buff") and not parent:HasModifier("modifier_fountain_invulnerability") then
        self:InvokeFlow()
    end
end

function modifier_item_aghanims_robe:AddCustomTransmitterData()
    return
    {
        manaRegen = self.fManaRegen,
        hpRegen = self.fHpRegen,
        spellAmp = self.fSpellAmp
    }
end

function modifier_item_aghanims_robe:HandleCustomTransmitterData(data)
    if data.manaRegen ~= nil and data.hpRegen ~= nil and data.spellAmp ~= nil then
        self.fManaRegen = tonumber(data.manaRegen)
        self.fHpRegen = tonumber(data.hpRegen)
        self.fSpellAmp = tonumber(data.spellAmp)
    end
end

function modifier_item_aghanims_robe:InvokeFlow()
    if IsServer() == true then
        self.fManaRegen = self.manaRegen
        self.fHpRegen = self.hpRegen
        self.fSpellAmp = self.spellAmp

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_aghanims_robe:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage 
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE, --GetModifierPercentageCasttime
        MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierMPRegenAmplify_Percentage
    }
    return funcs
end

function modifier_item_aghanims_robe:GetModifierMPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen_amp")
end

function modifier_item_aghanims_robe:GetModifierConstantManaRegen()
    return self.fManaRegen
end

function modifier_item_aghanims_robe:GetModifierConstantHealthRegen()
    return self.fHpRegen
end

function modifier_item_aghanims_robe:GetModifierPercentageCasttime()
    if self:GetParent():GetHealthPercent() < self:GetAbility():GetSpecialValueFor("cast_time_threshold") then return end

    return 50
end

function modifier_item_aghanims_robe:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_aghanims_robe:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_aghanims_robe:GetModifierSpellAmplify_Percentage()
    return self.fSpellAmp
end