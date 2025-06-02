LinkLuaModifier("modifier_gabriel_ascension", "heroes/hero_gabriel/gabriel_ascension", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gabriel_ascension_buff", "heroes/hero_gabriel/gabriel_ascension", LUA_MODIFIER_MOTION_NONE)

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

gabriel_ascension = class(ItemBaseClass)
modifier_gabriel_ascension = class(gabriel_ascension)
modifier_gabriel_ascension_buff = class(ItemBaseClassBuff)
-------------
function gabriel_ascension:GetIntrinsicModifierName()
    return "modifier_gabriel_ascension"
end

function gabriel_ascension:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local mod = "modifier_gabriel_ascension_buff"

    if not self:GetToggleState() then
        caster:RemoveModifierByName(mod)
    else
        caster:AddNewModifier(caster, self, mod, {})
        self:EndCooldown()
    end
end

function modifier_gabriel_ascension:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_MANA_PERCENTAGE,
    }
end

function modifier_gabriel_ascension:GetModifierExtraManaPercentage()
    return self:GetAbility():GetSpecialValueFor("max_mana_pct")
end
----------------
function modifier_gabriel_ascension_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
    }
end

function modifier_gabriel_ascension_buff:GetModifierAttackSpeedBonus_Constant()
    return self.fAspd
end

function modifier_gabriel_ascension_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_gabriel_ascension_buff:GetModifierConstantHealthRegen()
    return self.fRegen
end

function modifier_gabriel_ascension_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local parent = self:GetParent()

    self.vfx = ParticleManager:CreateParticle("particles/econ/items/omniknight/omni_2021_immortal/omni_2021_immortal_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(
        self.vfx,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", parent)
    EmitSoundOn("Hero_Omniknight.GuardianAngel", parent)

    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("drain_interval")

    self.drain = ability:GetSpecialValueFor("max_mana_drain_pct")
    self.drainIncreaseInterval = ability:GetSpecialValueFor("drain_increase_interval")

    self.aspdConversion = ability:GetSpecialValueFor("attack_speed_bonus_pct")
    self.damageConversion = ability:GetSpecialValueFor("attack_damage_bonus_pct")
    self.regenConversion = ability:GetSpecialValueFor("hp_regen_bonus_pct")

    self.totalDrained = 0

    self.counter = 0
    self.multiplier = 1

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_gabriel_ascension_buff:OnIntervalThink()
    local parent = self:GetParent()

    if self.counter >= self.drainIncreaseInterval then
        self.multiplier = self.multiplier * 2
        self.counter = 0
    end

    local mana = parent:GetMaxMana() * (self.drain/100) * self.multiplier

    if mana > parent:GetMana() then
        self:Destroy()
        return
    end

    parent:SpendMana(mana, self:GetAbility())

    self.counter = self.counter + 1

    self.totalDrained = self.totalDrained + mana

    self.aspd = self.totalDrained * (self.aspdConversion/100)
    self.damage = self.totalDrained * (self.damageConversion/100)
    self.regen = self.totalDrained * (self.regenConversion/100)

    self:InvokeBonus()
end

function modifier_gabriel_ascension_buff:OnDestroy()
    if not IsServer() then return end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    local ability = self:GetAbility()
    if ability:GetToggleState() then
        ability:ToggleAbility()
    end

    ability:UseResources(false, false, false, true)
end

function modifier_gabriel_ascension_buff:AddCustomTransmitterData()
    return
    {
        aspd = self.fAspd,
        damage = self.fDamage,
        regen = self.fRegen
    }
end

function modifier_gabriel_ascension_buff:HandleCustomTransmitterData(data)
    if data.aspd ~= nil and data.damage ~= nil and data.regen ~= nil then
        self.fAspd = tonumber(data.aspd)
        self.fDamage = tonumber(data.damage)
        self.fRegen = tonumber(data.regen)
    end
end

function modifier_gabriel_ascension_buff:InvokeBonus()
    if IsServer() == true then
        self.fAspd = self.aspd
        self.fDamage = self.damage
        self.fRegen = self.regen

        self:SendBuffRefreshToClients()
    end
end