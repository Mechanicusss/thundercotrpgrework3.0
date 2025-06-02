LinkLuaModifier("modifier_lycan_feral_impulse_custom", "heroes/hero_lycan/impulse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lycan_feral_impulse_custom_buff", "heroes/hero_lycan/impulse", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

lycan_feral_impulse_custom = class(ItemBaseClass)
modifier_lycan_feral_impulse_custom = class(lycan_feral_impulse_custom)
modifier_lycan_feral_impulse_custom_buff = class(ItemBaseClassBuff)
-------------
function lycan_feral_impulse_custom:GetIntrinsicModifierName()
    return "modifier_lycan_feral_impulse_custom"
end

function lycan_feral_impulse_custom:OnHeroCalculateStatBonus()
 if not IsServer() then return end

 local modif = self:GetCaster():FindModifierByName("modifier_lycan_feral_impulse_custom_buff")

 if modif ~= nil then
    modif:ForceRefresh()
 end
 -- should fix the skill not updating unless you die
end

function modifier_lycan_feral_impulse_custom:OnCreated()
    if not IsServer() then return end

    self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_lycan_feral_impulse_custom_buff", {})
end
---

function modifier_lycan_feral_impulse_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE  
    }

    return funcs
end

function modifier_lycan_feral_impulse_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    self:StartIntervalThink(0.1)
end

function modifier_lycan_feral_impulse_custom_buff:OnIntervalThink()
    self:OnRefresh()
end

function modifier_lycan_feral_impulse_custom_buff:OnRefresh()
    if not IsServer() then return end

    self.damage = ((self:GetParent():GetBaseDamageMax() + self:GetParent():GetBaseDamageMin())/2) * (self:GetAbility():GetSpecialValueFor("bonus_damage")/100)

    self:InvokeBonusDamage()
end

function modifier_lycan_feral_impulse_custom_buff:AddCustomTransmitterData()
    return
    {
        speed = self.fSpeed,
        damage = self.fDamage,
        armor = self.fArmor,
        hp = self.fHp
    }
end

function modifier_lycan_feral_impulse_custom_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_lycan_feral_impulse_custom_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_lycan_feral_impulse_custom_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_lycan_feral_impulse_custom_buff:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end