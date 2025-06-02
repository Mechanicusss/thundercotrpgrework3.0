LinkLuaModifier("modifier_item_mark_of_shadow", "items/item_mark_of_shadow/item_mark_of_shadow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_mark_of_shadow_regen", "items/item_mark_of_shadow/item_mark_of_shadow", LUA_MODIFIER_MOTION_NONE)

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
}

item_mark_of_shadow = class(ItemBaseClass)
item_mark_of_shadow2 = item_mark_of_shadow
item_mark_of_shadow3 = item_mark_of_shadow
item_mark_of_shadow4 = item_mark_of_shadow
item_mark_of_shadow5 = item_mark_of_shadow
item_mark_of_shadow6 = item_mark_of_shadow
item_mark_of_shadow7 = item_mark_of_shadow
modifier_item_mark_of_shadow = class(item_mark_of_shadow)
modifier_item_mark_of_shadow_regen = class(ItemBaseClassBuff)
-------------
function item_mark_of_shadow:GetIntrinsicModifierName()
    return "modifier_item_mark_of_shadow"
end

function item_mark_of_shadow:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_item_mark_of_shadow_regen", {
        duration = self:GetSpecialValueFor("duration")
    })

    EmitSoundOn("Item.SeedsOfSerenity", caster)
end
-----------
function modifier_item_mark_of_shadow_regen:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT 
    }
    return funcs
end

function modifier_item_mark_of_shadow_regen:GetModifierConstantManaRegen()
    return self.fRegen
end

function modifier_item_mark_of_shadow_regen:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_item_mark_of_shadow_regen:OnIntervalThink()
    self:OnRefresh()

    ApplyDamage({
        victim = self:GetCaster(),
        attacker = self:GetCaster(),
        damage = self.regen*0.1,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
    })
end

function modifier_item_mark_of_shadow_regen:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.regen = parent:GetMaxHealth() * (ability:GetSpecialValueFor("hp_to_mana_convert")/100)

    self:InvokeBonus()
end

function modifier_item_mark_of_shadow_regen:AddCustomTransmitterData()
    return
    {
        regen = self.fRegen,
    }
end

function modifier_item_mark_of_shadow_regen:HandleCustomTransmitterData(data)
    if data.regen ~= nil then
        self.fRegen = tonumber(data.regen)
    end
end

function modifier_item_mark_of_shadow_regen:InvokeBonus()
    if IsServer() == true then
        self.fRegen = self.regen

        self:SendBuffRefreshToClients()
    end
end
-----------
function modifier_item_mark_of_shadow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_EXTRA_MANA_PERCENTAGE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
    return funcs
end

function modifier_item_mark_of_shadow:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_mark_of_shadow:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_mark_of_shadow:GetModifierExtraManaPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_pct")
end

function modifier_item_mark_of_shadow:GetModifierSpellAmplify_Percentage()
    return self.fSpell
end

function modifier_item_mark_of_shadow:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_item_mark_of_shadow:OnIntervalThink()
    self:OnRefresh()
end

function modifier_item_mark_of_shadow:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local maxSpellDamage = ability:GetSpecialValueFor("max_spell_amp")

    self.spell = parent:GetMaxMana() * (ability:GetSpecialValueFor("max_mana_to_spell_amp")/100)

    if self.spell > maxSpellDamage then
        self.spell = maxSpellDamage
    end

    self:InvokeBonus()
end

function modifier_item_mark_of_shadow:AddCustomTransmitterData()
    return
    {
        spell = self.fSpell,
    }
end

function modifier_item_mark_of_shadow:HandleCustomTransmitterData(data)
    if data.spell ~= nil then
        self.fSpell = tonumber(data.spell)
    end
end

function modifier_item_mark_of_shadow:InvokeBonus()
    if IsServer() == true then
        self.fSpell = self.spell

        self:SendBuffRefreshToClients()
    end
end