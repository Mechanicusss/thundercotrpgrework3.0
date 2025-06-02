LinkLuaModifier("modifier_chicken_ability_2", "heroes/chicken/chicken_ability_2.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chicken_ability_2_buff", "heroes/chicken/chicken_ability_2.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    IsPurgeException = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

chicken_ability_2 = class(ItemBaseClass)
modifier_chicken_ability_2 = class(chicken_ability_2)
modifier_chicken_ability_2_buff = class(ItemBaseClassBuff)
-------------
function chicken_ability_2:GetIntrinsicModifierName()
    return "modifier_chicken_ability_2"
end

function chicken_ability_2:GetManaCost()
    return self:GetCaster():GetMaxMana() * (self:GetSpecialValueFor("mana_drain_pct")/100)
end

function chicken_ability_2:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local mod = caster:FindModifierByName("modifier_chicken_ability_1_self_transmute")
    if mod == nil then return end

    local target = mod:GetCaster()
    if not target or target == nil then return end
    if not target:IsAlive() then return end

    if self:GetToggleState() and not target:HasModifier("modifier_chicken_ability_2_buff") then
        target:AddNewModifier(caster, self, "modifier_chicken_ability_2_buff", {})
        EmitSoundOn("DOTA_Item.MaskOfMadness.Activate", target)
    else
        target:RemoveModifierByNameAndCaster("modifier_chicken_ability_2_buff", caster)
    end
end

function modifier_chicken_ability_2_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE
    }
    return funcs
end

function modifier_chicken_ability_2_buff:GetModifierPercentageCasttime()
    if self:GetAbility():GetLevel() < 1  then return end
    return self:GetAbility():GetSpecialValueFor("cast_time_reduction")
end

function modifier_chicken_ability_2_buff:GetModifierBaseAttackTimeConstant()
    return self.bat
end

function modifier_chicken_ability_2_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self.bat = self:GetParent():GetBaseAttackTime() - self:GetAbility():GetSpecialValueFor("bat_decrease")

    self:OnRefresh()

    if not IsServer() then return end

    self:StartIntervalThink(1.0)
end

function modifier_chicken_ability_2_buff:OnIntervalThink()
    local host = self:GetCaster()
    local ability = self:GetAbility()
    local cost = host:GetMaxMana() * (ability:GetSpecialValueFor("mana_drain_pct")/100)
    if cost <= host:GetMana() then
        host:SpendMana(cost, ability)
    else
        self:GetAbility():ToggleAbility()
    end

    self:OnRefresh()
end

function modifier_chicken_ability_2_buff:OnRefresh()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.hpRegen = caster:GetHealthRegen() * (ability:GetSpecialValueFor("regen_inherit") / 100)
    self.manaRegen = caster:GetManaRegen() * (ability:GetSpecialValueFor("regen_inherit") / 100)

    self:InvokeBonusRegen()
end

function modifier_chicken_ability_2_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
        hpRegen = self.fHpRegen,
        manaRegen = self.fManaRegen,
        spellAmp = self.fSpellAmp
    }
end

function modifier_chicken_ability_2_buff:HandleCustomTransmitterData(data)
    if data.hpRegen ~= nil and data.manaRegen ~= nil then
        self.fHpRegen = tonumber(data.hpRegen)
        self.fManaRegen = tonumber(data.manaRegen)
    end
end

function modifier_chicken_ability_2_buff:InvokeBonusRegen()
    if IsServer() == true then
        self.fHpRegen = self.hpRegen
        self.fManaRegen = self.manaRegen

        self:SendBuffRefreshToClients()
    end
end

function modifier_chicken_ability_2_buff:OnRemoved()
    if not IsServer() then return end

    self:GetAbility():UseResources(false, false, false, true)
end

function modifier_chicken_ability_2_buff:GetEffectName()
    return "particles/econ/items/drow/drow_head_mania/mask_of_madness_active_mania.vpcf"
end

function modifier_chicken_ability_2_buff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW   
end


function modifier_chicken_ability_2_buff:GetModifierConstantHealthRegen()
    return self.fHpRegen
end

function modifier_chicken_ability_2_buff:GetModifierConstantManaRegen()
    return self.fManaRegen
end