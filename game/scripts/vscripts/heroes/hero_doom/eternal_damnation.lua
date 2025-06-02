LinkLuaModifier("modifier_eternal_damnation", "heroes/hero_doom/eternal_damnation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eternal_damnation_aura", "heroes/hero_doom/eternal_damnation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eternal_damnation_self_buff", "heroes/hero_doom/eternal_damnation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eternal_damnation_activate", "heroes/hero_doom/eternal_damnation", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemSelfBuffBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return true end,
    IsPurgeException = function(self) return false end,
}

local ItemActivateBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

eternal_damnation_uba = class(ItemBaseClass)
modifier_eternal_damnation = class(eternal_damnation_uba)
modifier_eternal_damnation_self_buff = class(ItemSelfBuffBaseClass)
modifier_eternal_damnation_activate = class(ItemActivateBaseClass)
modifier_eternal_damnation_aura = class(ItemBaseClassAura)
-------------
function eternal_damnation_uba:GetIntrinsicModifierName()
    return "modifier_eternal_damnation"
end

--[[
function eternal_damnation_uba:OnSpellStart()
    if not IsServer() then return end
--
    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
    
    caster:AddNewModifier(caster, ability, "modifier_eternal_damnation_activate", { duration = duration })
end
--]]

function eternal_damnation_uba:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
------------
function modifier_eternal_damnation:DeclareFunctions()
    local funcs = {}

    return funcs
end

function modifier_eternal_damnation:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    caster:AddNewModifier(caster, ability, "modifier_eternal_damnation_activate", {})
end

function modifier_eternal_damnation:IsAura()
  return true
end

function modifier_eternal_damnation:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_CREEP)
end

function modifier_eternal_damnation:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_eternal_damnation:GetAuraRadius()
  return self:GetAbility():GetLevelSpecialValueFor("radius", (self:GetAbility():GetLevel() - 1))
end

function modifier_eternal_damnation:GetModifierAura()
    return "modifier_eternal_damnation_aura"
end

function modifier_eternal_damnation:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO)
end

function modifier_eternal_damnation:GetAuraEntityReject(target)
    if not self:GetCaster():HasModifier("modifier_eternal_damnation_activate") then
        return true
    end

    if IsBossTCOTRPG(target) then return true end
    if target:GetLevel() > self:GetCaster():GetLevel() then return true end

    return target:IsMagicImmune() -- Do not target magic immune units
end
-------------------
function modifier_eternal_damnation_self_buff:AddCustomTransmitterData()
    return
    {
        armor = self.fBonusArmor,
        damage = self.fBonusDamage
    }
end

function modifier_eternal_damnation_self_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil and data.armor ~= nil then
        self.fBonusDamage = tonumber(data.damage)
        self.fBonusArmor = tonumber(data.armor)
    end
end

function modifier_eternal_damnation_self_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    self.damage = params.damage
    self.armor = params.armor

    self:InvokeBonusDamage()
end

function modifier_eternal_damnation_self_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fBonusDamage = self.damage
        self.fBonusArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end

function modifier_eternal_damnation_self_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }

    return funcs
end

function modifier_eternal_damnation_self_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_eternal_damnation_self_buff:GetModifierPreAttack_BonusDamage()
    return self.fBonusDamage
end

function modifier_eternal_damnation_self_buff:GetModifierPhysicalArmorBonus()
    return self.fBonusArmor
end
-----------
function modifier_eternal_damnation_aura:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()
    
    if ability and not ability:IsNull() then
        self.damage = self:GetAbility():GetLevelSpecialValueFor("damage_reduction_pct", (self:GetAbility():GetLevel() - 1))
        self.armor = 100 - math.abs(self:GetAbility():GetLevelSpecialValueFor("armor_reduction_pct", (self:GetAbility():GetLevel() - 1)))

        local caster = self:GetCaster()
        local multiplier = self:GetAbility():GetLevelSpecialValueFor("stolen_amount_pct", (self:GetAbility():GetLevel() - 1)) / 100

        local stolenDamage = ((parent:GetBaseDamageMax()-parent:GetBaseDamageMin())*RandomFloat(0,1) + parent:GetBaseDamageMin()) * ((math.abs(self.damage) / 100)) * multiplier
        local stolenArmor = parent:GetPhysicalArmorBaseValue() * (1 - (self.armor / 100)) * multiplier

        -- We set the caster to the victim so it's easier to remove it properly
        caster:AddNewModifier(parent, ability, "modifier_eternal_damnation_self_buff", { damage = stolenDamage, armor = stolenArmor })
    end
end

function modifier_eternal_damnation_aura:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster() -- Doom
    local parent = self:GetParent() -- The victim
    caster:RemoveModifierByNameAndCaster("modifier_eternal_damnation_self_buff", parent)
end

function modifier_eternal_damnation_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE, --GetModifierPhysicalArmorBase_Percentage
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, --GetModifierBaseDamageOutgoing_Percentage
    }

    return funcs
end

function modifier_eternal_damnation_aura:GetModifierBaseDamageOutgoing_Percentage()
    return self.damage or self:GetAbility():GetLevelSpecialValueFor("damage_reduction_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_eternal_damnation_aura:GetModifierPhysicalArmorBase_Percentage()
    return self.armor or 100 - math.abs(self:GetAbility():GetLevelSpecialValueFor("armor_reduction_pct", (self:GetAbility():GetLevel() - 1)))
end