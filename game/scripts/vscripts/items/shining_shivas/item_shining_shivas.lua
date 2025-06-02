LinkLuaModifier("modifier_shining_shivas", "items/shining_shivas/item_shining_shivas", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shining_shivas_aura", "items/shining_shivas/item_shining_shivas", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shining_shivas_aura_allies", "items/shining_shivas/item_shining_shivas", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shining_shivas_antiregen", "items/shining_shivas/item_shining_shivas", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

item_shining_shivas = class(ItemBaseClass)
item_shining_shivas_2 = item_shining_shivas
item_shining_shivas_3 = item_shining_shivas
item_shining_shivas_4 = item_shining_shivas
item_shining_shivas_5 = item_shining_shivas
item_shining_shivas_6 = item_shining_shivas
item_shining_shivas_7 = item_shining_shivas
modifier_shining_shivas = class(item_shining_shivas)
modifier_shining_shivas_aura = class(ItemBaseClassAura)
modifier_shining_shivas_aura_allies = class(ItemBaseClassAura)
modifier_shining_shivas_antiregen = class(ItemBaseClassDebuff)
-------------
function item_shining_shivas:GetIntrinsicModifierName()
    return "modifier_shining_shivas"
end

function item_shining_shivas:GetAOERadius()
    return self:GetSpecialValueFor("aura_radius")
end

function item_shining_shivas:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local duration = self:GetLevelSpecialValueFor("blast_debuff_duration", (self:GetLevel() - 1))
    local blastRadius = self:GetLevelSpecialValueFor("blast_radius", (self:GetLevel() - 1))
    local blastRegenDebuffDuration = self:GetLevelSpecialValueFor("blast_regen_debuff_duration", (self:GetLevel() - 1))

    CreateModifierThinker(
        caster,
        self,
        "modifier_item_shivas_guard_thinker",
        { duration = duration },
        caster:GetAbsOrigin(),
        caster:GetTeamNumber(),
        false
    )

    local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        blastRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if unit:IsMagicImmune() then break end

        unit:AddNewModifier(caster, self, "modifier_shining_shivas_antiregen", { duration = blastRegenDebuffDuration })
    end

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "DOTA_Item.ShivasGuard.Activate", caster)
end
------------
function modifier_shining_shivas_antiregen:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true
    }

    return state
end

function modifier_shining_shivas_antiregen:GetEffectName()
    return "particles/units/heroes/hero_winter_wyvern/wyvern_cold_embrace_buff.vpcf"
end
------------
function modifier_shining_shivas:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }

    return funcs
end

function modifier_shining_shivas:IsAura()
  return true
end

function modifier_shining_shivas:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_CREEP)
end

function modifier_shining_shivas:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_shining_shivas:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES 
end

function modifier_shining_shivas:GetAuraRadius()
  return self:GetAbility():GetLevelSpecialValueFor("aura_radius", (self:GetAbility():GetLevel() - 1))
end

function modifier_shining_shivas:GetModifierAura()
    return self.auraName
end

function modifier_shining_shivas:GetAuraEntityReject(target)
    if target:GetTeamNumber() == self:GetCaster():GetTeamNumber() then
        if target:IsRealHero() and not target:IsIllusion() then
            self.auraName = "modifier_shining_shivas_aura_allies"
        else
            return true
        end
    else
        self.auraName = "modifier_shining_shivas_aura"
    end

    return false
end

function modifier_shining_shivas:OnCreated()
    self.auraName = "modifier_shining_shivas_aura"
end

function modifier_shining_shivas:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_shining_shivas:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_shining_shivas:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_shining_shivas:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end
---------
function modifier_shining_shivas_aura:OnCreated()
end

function modifier_shining_shivas_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE, --GetModifierAttackSpeedPercentage
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }

    return funcs
end

function modifier_shining_shivas_aura:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("aura_attack_speed")
end

function modifier_shining_shivas_aura:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("hp_regen_degen_aura")
end

function modifier_shining_shivas_aura:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("hp_regen_degen_aura")
end

function modifier_shining_shivas_aura:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("hp_regen_degen_aura")
end

function modifier_shining_shivas_aura:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("hp_regen_degen_aura")
end

function modifier_shining_shivas_aura:IsDebuff()
    return true
end
--------
function modifier_shining_shivas_aura_allies:OnCreated()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    if not IsServer() then return end

    local id = parent:GetPlayerID()
    if id == nil or not id then return end
    self.accountID = PlayerResource:GetSteamAccountID(id)
    if self.accountID == nil or not self.accountID then return end

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("aura_damage_reduction")

    self:StartIntervalThink(0.1)
end

function modifier_shining_shivas_aura_allies:OnIntervalThink()
    _G.PlayerDamageReduction[self.accountID][self:GetName()] = self:GetAbility():GetSpecialValueFor("aura_damage_reduction")
end

function modifier_shining_shivas_aura_allies:OnRemoved()
    if not IsServer() then return end

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_shining_shivas_aura_allies:IsDebuff()
    return false
end