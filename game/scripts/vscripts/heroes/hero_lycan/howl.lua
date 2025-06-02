LinkLuaModifier("modifier_lycan_howl_custom", "heroes/hero_lycan/howl", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lycan_howl_custom_buff", "heroes/hero_lycan/howl", LUA_MODIFIER_MOTION_NONE)

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

lycan_howl_custom = class(ItemBaseClass)
modifier_lycan_howl_custom = class(lycan_howl_custom)
modifier_lycan_howl_custom_buff = class(ItemBaseClassBuff)
-------------
function lycan_howl_custom:GetIntrinsicModifierName()
    return "modifier_lycan_howl_custom"
end

function lycan_howl_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function lycan_howl_custom:OnSpellStart()
    if not IsServer() then return end
--
    local caster = self:GetCaster()
    local ability = self
    local radius = ability:GetSpecialValueFor("radius")
    local duration = ability:GetSpecialValueFor("howl_duration")

    -- set their duration: how?

    EmitSoundOn("Hero_Lycan.Howl", caster)

    caster:AddNewModifier(caster, ability, "modifier_lycan_howl_custom_buff", { duration = duration })

    local wolves = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_CREEP), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,wolf in ipairs(wolves) do
        if wolf:GetUnitName() ~= "npc_dota_lycan_wolf_custom1" then break end
        if not wolf:IsAlive() then break end
        
        wolf:AddNewModifier(caster, ability, "modifier_lycan_howl_custom_buff", { duration = duration })
    end
end
---
function modifier_lycan_howl_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }

    return funcs
end

function modifier_lycan_howl_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.damage = self:GetParent():GetAverageTrueAttackDamage(self:GetParent()) * (self:GetAbility():GetSpecialValueFor("damage_increase")/100)

    self:InvokeBonusDamage()
end

function modifier_lycan_howl_custom_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_lycan_howl_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed_increase")
end

function modifier_lycan_howl_custom_buff:AddCustomTransmitterData()
    return
    {
        speed = self.fSpeed,
        damage = self.fDamage,
        armor = self.fArmor,
        hp = self.fHp
    }
end

function modifier_lycan_howl_custom_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_lycan_howl_custom_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_lycan_howl_custom_buff:GetEffectName()
    return "particles/econ/items/lycan/ti9_immortal/lycan_ti9_immortal_howl_buff.vpcf"
end