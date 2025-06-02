LinkLuaModifier("modifier_boss_skafian_howl", "heroes/bosses/forest/boss_skafian_howl", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_skafian_howl_buff", "heroes/bosses/forest/boss_skafian_howl", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_skafian_howl_stunned", "heroes/bosses/forest/boss_skafian_howl", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

boss_skafian_howl = class(ItemBaseClass)
modifier_boss_skafian_howl = class(boss_skafian_howl)
modifier_boss_skafian_howl_buff = class(ItemBaseClassBuff)
modifier_boss_skafian_howl_stunned = class(ItemBaseClassDebuff)
-------------
function boss_skafian_howl:GetIntrinsicModifierName()
    return "modifier_boss_skafian_howl"
end

function boss_skafian_howl:OnSpellStart()
    if not IsServer() then return end
--
    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetSpecialValueFor("howl_duration")

    EmitSoundOn("Hero_Lycan.Howl", caster)

    caster:AddNewModifier(caster, ability, "modifier_boss_skafian_howl_buff", { duration = duration })

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_terrorblade/terrorblade_scepter_ring_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            self:GetSpecialValueFor("stun_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        victim:AddNewModifier(caster, self, "modifier_boss_skafian_howl_stunned", {
            duration = self:GetSpecialValueFor("stun_duration")
        })
    end
end
---
function modifier_boss_skafian_howl_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }

    return funcs
end

function modifier_boss_skafian_howl_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.damage = self:GetParent():GetAverageTrueAttackDamage(self:GetParent()) * (self:GetAbility():GetSpecialValueFor("damage_increase")/100)

    self:InvokeBonusDamage()
end

function modifier_boss_skafian_howl_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_boss_skafian_howl_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed_increase")
end

function modifier_boss_skafian_howl_buff:AddCustomTransmitterData()
    return
    {
        speed = self.fSpeed,
        damage = self.fDamage,
    }
end

function modifier_boss_skafian_howl_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_boss_skafian_howl_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_boss_skafian_howl_buff:GetEffectName()
    return "particles/econ/items/lycan/ti9_immortal/lycan_ti9_immortal_howl_buff.vpcf"
end
------------------------------
function modifier_boss_skafian_howl_stunned:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_boss_skafian_howl_stunned:GetEffectName()
    return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_boss_skafian_howl_stunned:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end