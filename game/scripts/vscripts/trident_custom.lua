require("libraries/cfinder")

LinkLuaModifier("modifier_trident_custom", "trident_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_trident_custom_burn_debuff", "trident_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

item_trident_custom = class(ItemBaseClass)
item_trident_custom_2 = item_trident_custom
item_trident_custom_3 = item_trident_custom
item_trident_custom_4 = item_trident_custom
item_trident_custom_5 = item_trident_custom
item_trident_custom_6 = item_trident_custom
item_trident_custom_7 = item_trident_custom
item_trident_custom_8 = item_trident_custom
modifier_trident_custom = class(item_trident_custom)
modifier_trident_custom_burn_debuff = class(ItemBaseClassDebuff)
-------------
function item_trident_custom:GetIntrinsicModifierName()
    return "modifier_trident_custom"
end
------------
function modifier_trident_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_trident_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local victim = event.unit

    if event.attacker ~= parent or victim == parent then return end
    if not event.inflictor then return end
    if (event.inflictor and event.inflictor == ability) then return end
    if not parent:IsRealHero() or victim:IsOther() or victim:IsBuilding() or (not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim)) then return end
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return end

    local critChance = ability:GetSpecialValueFor("spell_crit_chance")
    local critDmg = ability:GetSpecialValueFor("spell_crit_damage")

    local witchBlade = parent:FindModifierByName("modifier_item_witch_blade_custom")
    if witchBlade ~= nil and victim:HasModifier("modifier_item_witch_blade_custom_poison") then
        local witchBladeItem = witchBlade:GetAbility()
        if witchBladeItem ~= nil then
            critDmg = critDmg + witchBladeItem:GetSpecialValueFor("poison_critical_multiplier")
        end
    end

    for _,banned in ipairs(TRIDENT_CRITICAL_IGNORE) do
        if event.inflictor:GetAbilityName() == banned then 
            return
        end
    end

    if IsBossTCOTRPG(victim) then
        for _,banned in ipairs(DAMAGE_FILTER_BANNED_BOSS_ABILITIES) do
            if event.inflictor:GetAbilityName() == banned then 
                return
            end
        end
    end

    if not RollPercentage(critChance) then return end

    local damage = event.damage * (critDmg / 100)

    ApplyDamage({
        victim = victim,
        attacker = attacker,
        ability = ability,
        damage = damage,
        damage_type = event.damage_type,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION 
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, damage, nil)

    if ability:GetLevel() == 8 and not victim:HasModifier("modifier_trident_custom_burn_debuff") then
        local debuff = victim:AddNewModifier(parent, ability, "modifier_trident_custom_burn_debuff", {
            duration = ability:GetSpecialValueFor("burn_duration"),
            damage = damage * (ability:GetSpecialValueFor("burn_damage_pct")/100)
        })
    end
end

function modifier_trident_custom:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1)) + self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_custom:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_custom:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_custom:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("spell_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_custom:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_custom:GetModifierStatusResistance()
    return self:GetAbility():GetLevelSpecialValueFor("status_resistance", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_trident_custom:GetEffectName() 
    if self:GetAbility():GetLevel() == 8 then
        return "particles/units/heroes/hero_clinkz/clinkz_burning_army_ambient_2.vpcf"
    end
end

function modifier_trident_custom:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_trident_custom:OnIntervalThink()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    if ability:GetLevel() == 8 then
        if parent:GetLevel() < MAX_LEVEL then
            DisplayError(parent:GetPlayerID(), "Requires Level " .. MAX_LEVEL)
            parent:DropItemAtPositionImmediate(ability, parent:GetAbsOrigin())
        end
    end
end
---------------
function modifier_trident_custom_burn_debuff:IsHidden() return false end

function modifier_trident_custom_burn_debuff:GetEffectName() return "particles/econ/items/huskar/huskar_2021_immortal/huskar_2021_immortal_burning_spear_debuff_gold.vpcf" end

function modifier_trident_custom_burn_debuff:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local attacker = self:GetCaster()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("burn_interval")

    self.damageTable = {
        attacker = attacker,
        victim = parent,
        damage = params.damage,
        ability = ability,
        damage_type = DAMAGE_TYPE_MAGICAL,
    }

    self:StartIntervalThink(interval)
end

function modifier_trident_custom_burn_debuff:OnIntervalThink() 
    local attacker = self:GetCaster()
    local ability = self:GetAbility()

    ApplyDamage(self.damageTable)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, self:GetParent(), self.damageTable.damage, nil)
end
