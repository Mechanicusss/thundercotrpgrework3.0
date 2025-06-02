LinkLuaModifier("modifier_item_assault_cuirass_custom", "items/item_assault_cuirass_custom/item_assault_cuirass_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_assault_cuirass_custom_aura", "items/item_assault_cuirass_custom/item_assault_cuirass_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_assault_cuirass_custom_aura_enemy", "items/item_assault_cuirass_custom/item_assault_cuirass_custom", LUA_MODIFIER_MOTION_NONE)

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
}

item_assault_cuirass_custom = class(ItemBaseClass)
item_assault_cuirass_custom_2 = item_assault_cuirass_custom
item_assault_cuirass_custom_3 = item_assault_cuirass_custom
item_assault_cuirass_custom_4 = item_assault_cuirass_custom
item_assault_cuirass_custom_5 = item_assault_cuirass_custom
item_assault_cuirass_custom_6 = item_assault_cuirass_custom
item_assault_cuirass_custom_7 = item_assault_cuirass_custom
item_assault_cuirass_custom_8 = item_assault_cuirass_custom
item_assault_cuirass_custom_9 = item_assault_cuirass_custom
modifier_item_assault_cuirass_custom = class(item_assault_cuirass_custom)
modifier_item_assault_cuirass_custom_aura = class(ItemBaseClassAura)
modifier_item_assault_cuirass_custom_aura_enemy = class(ItemBaseClassAura)

-------------
function item_assault_cuirass_custom:GetIntrinsicModifierName()
    return "modifier_item_assault_cuirass_custom"
end

function item_assault_cuirass_custom:GetAOERadius()
    return 1200
end
------------
function modifier_item_assault_cuirass_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK 
    }

    return funcs
end

function modifier_item_assault_cuirass_custom:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_assault_cuirass_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_assault_cuirass_custom:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_assault_cuirass_custom:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_assault_cuirass_custom:GetModifierPhysical_ConstantBlock(event)
    if RollPercentage(self:GetAbility():GetSpecialValueFor("block_chance")) then
        return event.original_damage * (self:GetAbility():GetSpecialValueFor("block_damage_pct")/100)
    end
end

function modifier_item_assault_cuirass_custom:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.allStats = self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
        self.statStr = self:GetAbility():GetLevelSpecialValueFor("bonus_str", (self:GetAbility():GetLevel() - 1))
        self.maxHpRegen = self:GetAbility():GetLevelSpecialValueFor("max_hp_regen", (self:GetAbility():GetLevel() - 1))
        self.bonusAttackSpeed = self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
        self.bonusHealth = self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
        self.bonusArmor = self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
    end

    self.caster = self:GetCaster()
    self.aura_modifier_name = "modifier_item_assault_cuirass_custom_aura"
    self.allyAura = "modifier_item_assault_cuirass_custom_aura"
    self.enemyAura = "modifier_item_assault_cuirass_custom_aura_enemy"
end

function modifier_item_assault_cuirass_custom:IsAura()
  return true
end

function modifier_item_assault_cuirass_custom:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BUILDING)
end

function modifier_item_assault_cuirass_custom:GetAuraSearchTeam()
  return bit.bor(DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_TEAM_ENEMY)
end

function modifier_item_assault_cuirass_custom:GetAuraRadius()
  return 1200
end

function modifier_item_assault_cuirass_custom:GetModifierAura()
    return self.aura_modifier_name
end

function modifier_item_assault_cuirass_custom:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_item_assault_cuirass_custom:GetAuraEntityReject(target)
    if target:GetTeamNumber() == self.caster:GetTeamNumber() then
        self.aura_modifier_name = self.allyAura
    else
        self.aura_modifier_name = self.enemyAura
    end

    return false
end
----------
function modifier_item_assault_cuirass_custom_aura:OnCreated()

end

function modifier_item_assault_cuirass_custom_aura:IsDebuff()
    return false
end

function modifier_item_assault_cuirass_custom_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }

    return funcs
end

function modifier_item_assault_cuirass_custom_aura:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("aura_damage_pct")
end

function modifier_item_assault_cuirass_custom_aura:GetModifierAttackSpeedBonus_Constant()
    return  self:GetAbility():GetSpecialValueFor("aura_attack_speed")
end

function modifier_item_assault_cuirass_custom_aura:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("aura_armor")
end
----------
function modifier_item_assault_cuirass_custom_aura_enemy:OnCreated()
end

function modifier_item_assault_cuirass_custom_aura_enemy:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }

    return funcs
end

function modifier_item_assault_cuirass_custom_aura_enemy:GetModifierPhysicalArmorBonus()    
    return self:GetAbility():GetSpecialValueFor("aura_disarmor")
end

function modifier_item_assault_cuirass_custom_aura_enemy:IsDebuff()
    return true
end
----------

