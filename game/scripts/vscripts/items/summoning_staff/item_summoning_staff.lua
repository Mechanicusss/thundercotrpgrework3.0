LinkLuaModifier("modifier_item_summoning_staff", "items/summoning_staff/item_summoning_staff", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_summoning_staff_aura", "items/summoning_staff/item_summoning_staff", LUA_MODIFIER_MOTION_NONE)

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

item_summoning_staff = class(ItemBaseClass)
item_summoning_staff_2 = item_summoning_staff
item_summoning_staff_3 = item_summoning_staff
item_summoning_staff_4 = item_summoning_staff
item_summoning_staff_5 = item_summoning_staff
item_summoning_staff_6 = item_summoning_staff
item_summoning_staff_7 = item_summoning_staff
item_summoning_staff_8 = item_summoning_staff
item_summoning_staff_9 = item_summoning_staff
modifier_item_summoning_staff = class(ItemBaseClass)
modifier_item_summoning_staff_aura = class(ItemBaseClassBuff)
-------------
function item_summoning_staff:GetIntrinsicModifierName()
    return "modifier_item_summoning_staff"
end
---
function modifier_item_summoning_staff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }

    return funcs
end

function modifier_item_summoning_staff:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_summoning_staff:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_summoning_staff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_summoning_staff:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_summoning_staff:GetModifierBonusStats_Intellect()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_summoning_staff:GetModifierBonusStats_Agility()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_summoning_staff:GetModifierBonusStats_Strength()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_summoning_staff:IsAura()
    return true
end

function modifier_item_summoning_staff:GetAuraSearchType()
    return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_item_summoning_staff:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_summoning_staff:GetAuraRadius()
    return FIND_UNITS_EVERYWHERE
end

function modifier_item_summoning_staff:GetModifierAura()
    return "modifier_item_summoning_staff_aura"
end

function modifier_item_summoning_staff:GetAuraEntityReject(target)
    -- Reject non-summons
    if not IsSummonTCOTRPG(target) then return true end 

    -- Reject summons that don't belong to the wearer
    if target:GetOwner() ~= self:GetCaster() then return true end 
    
    return false
end
---------------------
function modifier_item_summoning_staff_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_item_summoning_staff_aura:GetModifierExtraHealthBonus()
    return self:GetCaster():GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("shared_health_pct")/100)
end

function modifier_item_summoning_staff_aura:GetModifierPreAttack_BonusDamage()
    return ((self:GetCaster():GetDamageMin()+self:GetCaster():GetDamageMax())/2) * (self:GetAbility():GetSpecialValueFor("shared_damage_pct")/100)
end

function modifier_item_summoning_staff_aura:GetModifierAttackSpeedBonus_Constant()
    return (self:GetCaster():GetAttackSpeed()*100) * (self:GetAbility():GetSpecialValueFor("shared_attack_speed_pct")/100)
end

function modifier_item_summoning_staff_aura:GetModifierPhysicalArmorBonus()
    return self:GetCaster():GetPhysicalArmorValue(false) * (self:GetAbility():GetSpecialValueFor("shared_armor_pct")/100)
end