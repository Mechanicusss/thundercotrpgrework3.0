LinkLuaModifier("modifier_item_martyrs_plate_custom", "items/item_martyrs_plate_custom/item_martyrs_plate_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_plate_custom_aura", "items/item_martyrs_plate_custom/item_martyrs_plate_custom", LUA_MODIFIER_MOTION_NONE)

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
}

item_martyrs_plate_custom = class(ItemBaseClass)
item_martyrs_plate_custom_2 = item_martyrs_plate_custom
item_martyrs_plate_custom_3 = item_martyrs_plate_custom
item_martyrs_plate_custom_4 = item_martyrs_plate_custom
item_martyrs_plate_custom_5 = item_martyrs_plate_custom
item_martyrs_plate_custom_6 = item_martyrs_plate_custom
item_martyrs_plate_custom_7 = item_martyrs_plate_custom
item_martyrs_plate_custom_8 = item_martyrs_plate_custom
item_martyrs_plate_custom_9 = item_martyrs_plate_custom
modifier_item_martyrs_plate_custom = class(item_martyrs_plate_custom)
modifier_item_martyrs_plate_custom_aura = class(ItemBaseClassBuff)
-------------
function item_martyrs_plate_custom:GetIntrinsicModifierName()
    return "modifier_item_martyrs_plate_custom"
end
-------------
function modifier_item_martyrs_plate_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_item_martyrs_plate_custom:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
end

function modifier_item_martyrs_plate_custom:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_martyrs_plate_custom:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_martyrs_plate_custom:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_martyrs_plate_custom:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_martyrs_plate_custom:IsAura()
    return true
end

function modifier_item_martyrs_plate_custom:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_item_martyrs_plate_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_martyrs_plate_custom:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_martyrs_plate_custom:GetModifierAura()
    return "modifier_item_martyrs_plate_custom_aura"
end

function modifier_item_martyrs_plate_custom:GetAuraEntityReject(target)
    return target == self:GetCaster()
end
---------------------------
function modifier_item_martyrs_plate_custom_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
        MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT 
    }
end

function modifier_item_martyrs_plate_custom_aura:GetModifierIncomingPhysicalDamageConstant(event)
    if not IsServer() then return end 

    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end 

    local ability = self:GetAbility()
    local redirect = ability:GetSpecialValueFor("damage_redirection")/100
    
    local damage = event.damage * redirect

    if IsServer() then
        ApplyDamage({
            victim = self:GetCaster(),
            attacker = event.attacker,
            damage = damage,
            damage_type = event.damage_type,
            ability = ability
        })
    end

    return -damage
end

function modifier_item_martyrs_plate_custom_aura:GetModifierIncomingSpellDamageConstant(event)
    if not IsServer() then return end 

    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end 

    local ability = self:GetAbility()
    local redirect = ability:GetSpecialValueFor("damage_redirection")/100

    local damage = event.damage * redirect

    if IsServer() then
        ApplyDamage({
            victim = self:GetCaster(),
            attacker = event.attacker,
            damage = damage,
            damage_type = event.damage_type,
            ability = ability
        })
    end

    return -damage
end