LinkLuaModifier("modifier_item_veil_of_discord_custom", "items/item_veil_of_discord_custom/item_veil_of_discord_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_veil_of_discord_custom_mana_regen_aura", "items/item_veil_of_discord_custom/item_veil_of_discord_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter", "items/item_veil_of_discord_custom/item_veil_of_discord_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_veil_of_discord_custom_blaze_aura_emitter", "items/item_veil_of_discord_custom/item_veil_of_discord_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_veil_of_discord_custom_magic_weakness_aura", "items/item_veil_of_discord_custom/item_veil_of_discord_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_veil_of_discord_custom_blaze_aura", "items/item_veil_of_discord_custom/item_veil_of_discord_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_veil_of_discord_custom = class(ItemBaseClass)
item_veil_of_discord_custom2 = item_veil_of_discord_custom
item_veil_of_discord_custom3 = item_veil_of_discord_custom
item_veil_of_discord_custom4 = item_veil_of_discord_custom
item_veil_of_discord_custom5 = item_veil_of_discord_custom
item_veil_of_discord_custom6 = item_veil_of_discord_custom
item_veil_of_discord_custom7 = item_veil_of_discord_custom
item_veil_of_discord_custom8 = item_veil_of_discord_custom
item_veil_of_discord_custom9 = item_veil_of_discord_custom
modifier_item_veil_of_discord_custom = class(item_veil_of_discord_custom)
modifier_item_veil_of_discord_custom_mana_regen_aura = class(ItemBaseClassAura)
modifier_item_veil_of_discord_custom_magic_weakness_aura = class(ItemBaseClassAura)
modifier_item_veil_of_discord_custom_blaze_aura = class(ItemBaseClassAura)
modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter = class(ItemBaseClass)
modifier_item_veil_of_discord_custom_blaze_aura_emitter = class(ItemBaseClass)
-------------
function item_veil_of_discord_custom:GetIntrinsicModifierName()
    return "modifier_item_veil_of_discord_custom"
end

function modifier_item_veil_of_discord_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:AddNewModifier(parent, ability, "modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter", {})

    if ability:GetLevel() == 9 then
        parent:AddNewModifier(parent, ability, "modifier_item_veil_of_discord_custom_blaze_aura_emitter", {})
    end

    self:StartIntervalThink(0.1)
end

function modifier_item_veil_of_discord_custom:OnIntervalThink()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    if ability:GetLevel() == 9 then
        if parent:GetLevel() < MAX_LEVEL then
            DisplayError(parent:GetPlayerID(), "Requires Level " .. MAX_LEVEL)
            parent:DropItemAtPositionImmediate(ability, parent:GetAbsOrigin())
        end
    end
end

function modifier_item_veil_of_discord_custom:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:RemoveModifierByName("modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter")
    parent:RemoveModifierByName("modifier_item_veil_of_discord_custom_blaze_aura_emitter")
end

function modifier_item_veil_of_discord_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect  
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage 
    }
    return funcs
end

function modifier_item_veil_of_discord_custom:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_veil_of_discord_custom:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_veil_of_discord_custom:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_veil_of_discord_custom:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("spell_amp")
end

function modifier_item_veil_of_discord_custom:IsAura()
  return true
end

function modifier_item_veil_of_discord_custom:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_item_veil_of_discord_custom:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_veil_of_discord_custom:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_veil_of_discord_custom:GetModifierAura()
    return "modifier_item_veil_of_discord_custom_mana_regen_aura"
end

function modifier_item_veil_of_discord_custom:GetAuraEntityReject(target)
    return false
end
----------
function modifier_item_veil_of_discord_custom_mana_regen_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
    }
    return funcs
end

function modifier_item_veil_of_discord_custom_mana_regen_aura:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("aura_mana_regen")
end
---------
function modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter:OnCreated()
end

function modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter:IsAura()
  return true
end

function modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_CREEP)
end

function modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter:GetModifierAura()
    return "modifier_item_veil_of_discord_custom_magic_weakness_aura"
end

function modifier_item_veil_of_discord_custom_magic_weakness_aura_emitter:GetAuraEntityReject(target)
    return false
end
---------------
function modifier_item_veil_of_discord_custom_blaze_aura_emitter:IsAura()
  return true
end

function modifier_item_veil_of_discord_custom_blaze_aura_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_CREEP)
end

function modifier_item_veil_of_discord_custom_blaze_aura_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_veil_of_discord_custom_blaze_aura_emitter:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_veil_of_discord_custom_blaze_aura_emitter:GetModifierAura()
    return "modifier_item_veil_of_discord_custom_blaze_aura"
end

function modifier_item_veil_of_discord_custom_blaze_aura_emitter:GetAuraEntityReject(target)
    return false
end

function modifier_item_veil_of_discord_custom_blaze_aura_emitter:GetEffectName()
    if self:GetAbility():GetLevel() == 9 then
        return "particles/econ/events/fall_2022/radiance/radiance_owner_fall2022.vpcf"
    end
end
-----------
function modifier_item_veil_of_discord_custom_magic_weakness_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
    }
    return funcs
end

function modifier_item_veil_of_discord_custom_magic_weakness_aura:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("resist_shred_aura")
end

function modifier_item_veil_of_discord_custom_magic_weakness_aura:IsDebuff()
    return true
end
-----
function modifier_item_veil_of_discord_custom_blaze_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_item_veil_of_discord_custom_blaze_aura:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("dawn_magic_res")
end

function modifier_item_veil_of_discord_custom_blaze_aura:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("interval")
    local damage = ability:GetSpecialValueFor("blazing_damage") + (caster:GetPrimaryAttribute() * (ability:GetSpecialValueFor("attribute_to_damage")/100))

    self.damageTable = {
        attacker = caster,
        victim = parent,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability,
        damage = damage
    }

    self:StartIntervalThink(interval)
end

function modifier_item_veil_of_discord_custom_blaze_aura:OnIntervalThink()
    ApplyDamage(self.damageTable)
end

function modifier_item_veil_of_discord_custom_blaze_aura:IsDebuff()
    return true
end

function modifier_item_veil_of_discord_custom_blaze_aura:GetEffectName()
    return "particles/econ/events/fall_2022/radiance_target_fall2022.vpcf"
end