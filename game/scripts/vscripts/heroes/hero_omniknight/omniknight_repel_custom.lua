LinkLuaModifier("modifier_omniknight_repel_custom", "heroes/hero_omniknight/omniknight_repel_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_omniknight_repel_custom_buff", "heroes/hero_omniknight/omniknight_repel_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAbsorb = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

omniknight_repel_custom = class(ItemBaseClass)
modifier_omniknight_repel_custom = class(omniknight_repel_custom)
modifier_omniknight_repel_custom_buff = class(ItemBaseClassAbsorb)
-------------
function omniknight_repel_custom:GetIntrinsicModifierName()
    return "modifier_omniknight_repel_custom"
end
---------------
function modifier_omniknight_repel_custom:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_omniknight_repel_custom:OnIntervalThink()
    if self:GetParent():IsChanneling() then return end
    
    if self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() and self:GetAbility():IsCooldownReady() then
        SpellCaster:Cast(self:GetAbility(), self:GetParent(), true)
    end
end
---------------
function omniknight_repel_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    local target = self:GetCursorTarget()
    
    target:AddNewModifier(caster, ability, "modifier_omniknight_repel_custom_buff", { duration = duration })

    target:Purge(false, true, false, true, true)

    EmitSoundOn("Hero_Omniknight.Repel", caster)
end
------------
function modifier_omniknight_repel_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.damage = self:GetParent():GetStrength() * (self:GetAbility():GetSpecialValueFor("bonus_str_pct")/100)

    self:InvokeBonusDamage()
end

function modifier_omniknight_repel_custom_buff:DeclareFunctions()
    local funcs = {
         MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
         MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
         MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
    }

    return funcs
end

function modifier_omniknight_repel_custom_buff:GetModifierStatusResistance()
    return self:GetAbility():GetSpecialValueFor("status_resistance")
end

function modifier_omniknight_repel_custom_buff:GetModifierBonusStats_Strength()
    return self.fDamage
end

function modifier_omniknight_repel_custom_buff:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("hp_regen_pct")
end

function modifier_omniknight_repel_custom_buff:GetEffectName()
    return "particles/units/heroes/hero_omniknight/omniknight_repel_buff.vpcf"
end

function modifier_omniknight_repel_custom_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_omniknight_repel_custom_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_omniknight_repel_custom_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end