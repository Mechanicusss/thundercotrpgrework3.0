LinkLuaModifier("modifier_aeon_of_tarrasque", "items/aeon_of_tarrasque/item_aeon_of_tarrasque", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aeon_of_tarrasque_immunity", "items/aeon_of_tarrasque/item_aeon_of_tarrasque", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseBuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsPurgable = function(self) return false end,
    IsPurgeException = function(self) return true end,
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsPurgable = function(self) return false end,
    IsPurgeException = function(self) return true end,
}

item_aeon_of_tarrasque = class(ItemBaseClass)
item_aeon_of_tarrasque_2 = item_aeon_of_tarrasque
item_aeon_of_tarrasque_3 = item_aeon_of_tarrasque
item_aeon_of_tarrasque_4 = item_aeon_of_tarrasque
item_aeon_of_tarrasque_5 = item_aeon_of_tarrasque
item_aeon_of_tarrasque_6 = item_aeon_of_tarrasque
item_aeon_of_tarrasque_7 = item_aeon_of_tarrasque
modifier_aeon_of_tarrasque = class(item_aeon_of_tarrasque)
modifier_aeon_of_tarrasque_immunity = class(ItemBaseBuffClass)
-------------
function item_aeon_of_tarrasque:GetIntrinsicModifierName()
    return "modifier_aeon_of_tarrasque"
end
------------
function modifier_aeon_of_tarrasque:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_MANA_BONUS, --GetModifierManaBonus,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }

    return funcs
end

function modifier_aeon_of_tarrasque:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_aeon_of_tarrasque_immunity")
end

function modifier_aeon_of_tarrasque:OnTakeDamage(event)
     if not IsServer() then return end

     local attacker = event.attacker
     local victim = event.unit

     if victim ~= self:GetParent() then return end

     local ability = self:GetAbility()

     if not ability or ability:IsNull() then return end

     if not victim or not attacker or not UnitIsNotMonkeyClone(attacker) or attacker:IsIllusion() or attacker == victim or not victim:IsRealHero() or not ability:IsCooldownReady() then return end

     local damage = event.damage
     local remainingHealth = victim:GetHealth() - damage

     if (remainingHealth / victim:GetMaxHealth()) <= (self.threshold / 100) and not victim:HasModifier("modifier_aeon_of_tarrasque_immunity") then
        victim:AddNewModifier(victim, ability, "modifier_aeon_of_tarrasque_immunity", { duration = self.immunityDuration, immunityDuration = self.immunityDuration })
    end
end

function modifier_aeon_of_tarrasque:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local ability = self:GetAbility()

    if ability and not ability:IsNull() then
        self.threshold = self:GetAbility():GetLevelSpecialValueFor("health_threshold_pct", (self:GetAbility():GetLevel() - 1))
        self.immunityDuration = self:GetAbility():GetLevelSpecialValueFor("buff_duration", (self:GetAbility():GetLevel() - 1))
        self.immunityCooldown = self:GetAbility():GetLevelSpecialValueFor("cooldown_duration", (self:GetAbility():GetLevel() - 1))
        self.strength = self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
        self.health = self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
        self.regen = self:GetAbility():GetLevelSpecialValueFor("health_regen_pct", (self:GetAbility():GetLevel() - 1))
        self.mana = self:GetAbility():GetLevelSpecialValueFor("bonus_mana", (self:GetAbility():GetLevel() - 1))
    end

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_aeon_of_tarrasque:OnIntervalThink()
    local parent = self:GetParent()

    self.damage = parent:GetHealth() * (self:GetAbility():GetSpecialValueFor("damage_from_hp")/100)

    self:InvokeBonusDamage()
end

function modifier_aeon_of_tarrasque:GetModifierBonusStats_Strength()
    return self.strength or self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_aeon_of_tarrasque:GetModifierHealthBonus()
    return self.health or self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_aeon_of_tarrasque:GetModifierHealthRegenPercentage()
    return self.regen or self:GetAbility():GetLevelSpecialValueFor("health_regen_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_aeon_of_tarrasque:GetModifierManaBonus()
    return self.mana or self:GetAbility():GetLevelSpecialValueFor("bonus_mana", (self:GetAbility():GetLevel() - 1))
end

function modifier_aeon_of_tarrasque:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_aeon_of_tarrasque:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_aeon_of_tarrasque:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_aeon_of_tarrasque:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
-------------
function modifier_aeon_of_tarrasque_immunity:DeclareFunctions()
    local func = {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    }

    return func
end

function modifier_aeon_of_tarrasque_immunity:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()

    if not parent then return end
    if not parent:IsAlive() then return end

    local ability = self:GetAbility()

    parent:Purge(false, true, false, true, true) -- Hard Dispell

    if ability and not ability:IsNull() then
        self.immunityRegen = self:GetAbility():GetLevelSpecialValueFor("buff_health_regen_pct", (self:GetAbility():GetLevel() - 1))
        self.immunityStatusResistance = self:GetAbility():GetLevelSpecialValueFor("status_resistance", (self:GetAbility():GetLevel() - 1))
    end

    local particle = ParticleManager:CreateParticle("particles/items4_fx/combo_breaker_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetOrigin(), true)

    EmitSoundOnLocationWithCaster(parent:GetOrigin(), "DOTA_Item.ComboBreaker", parent)
end

function modifier_aeon_of_tarrasque_immunity:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not ability or ability:IsNull() then return end

    local cooldown = ability:GetCooldown(ability:GetLevel()) * parent:GetCooldownReduction()

    ability:StartCooldown(cooldown)
end

function modifier_aeon_of_tarrasque_immunity:GetModifierHealthRegenPercentage()
    return self.immunityRegen or self:GetAbility():GetLevelSpecialValueFor("buff_health_regen_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_aeon_of_tarrasque_immunity:GetModifierStatusResistance()
    return self.immunityStatusResistance or self:GetAbility():GetLevelSpecialValueFor("status_resistance", (self:GetAbility():GetLevel() - 1))
end

function modifier_aeon_of_tarrasque_immunity:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_aeon_of_tarrasque_immunity:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_aeon_of_tarrasque_immunity:GetAbsoluteNoDamagePure()
    return 1
end