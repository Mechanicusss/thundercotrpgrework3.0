LinkLuaModifier("modifier_item_ristul_dagger", "items/item_ristul_dagger/item_ristul_dagger", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ristul_dagger_buff", "items/item_ristul_dagger/item_ristul_dagger", LUA_MODIFIER_MOTION_NONE)

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

item_ristul_dagger = class(ItemBaseClass)
modifier_item_ristul_dagger = class(item_ristul_dagger)
modifier_item_ristul_dagger_buff = class(ItemBaseClassBuff)
-------------
function item_ristul_dagger:GetIntrinsicModifierName()
    return "modifier_item_ristul_dagger"
end

function item_ristul_dagger:GetHealthCost()
    return self:GetCaster():GetHealth() * (self:GetSpecialValueFor("health_conversion_pct")/100)
end

function item_ristul_dagger:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_item_ristul_dagger_buff") then
        caster:RemoveModifierByName("modifier_item_ristul_dagger_buff")
    end

    caster:AddNewModifier(caster, self, "modifier_item_ristul_dagger_buff", {
        duration = self:GetSpecialValueFor("duration"),
        damage = self:GetHealthCost(-1)
    })

    EmitSoundOn("DOTA_Item.SoulRing.Activate", caster)
end
-----------
function modifier_item_ristul_dagger:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE 
    }
end

function modifier_item_ristul_dagger:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed_pct")
end

function modifier_item_ristul_dagger:GetModifierExtraHealthPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_health_pct")
end
-----------
function modifier_item_ristul_dagger_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.damage = params.damage

    self:InvokeBonusDamage()
end

function modifier_item_ristul_dagger_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }
end

function modifier_item_ristul_dagger_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_item_ristul_dagger_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_item_ristul_dagger_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_item_ristul_dagger_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end