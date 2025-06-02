LinkLuaModifier("modifier_item_solarflare_chestplate", "items/item_solarflare_chestplate/item_solarflare_chestplate", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_solarflare_chestplate_burn", "items/item_solarflare_chestplate/item_solarflare_chestplate", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return true end,
}

item_solarflare_chestplate = class(ItemBaseClass)
item_solarflare_chestplate2 = item_solarflare_chestplate
item_solarflare_chestplate3 = item_solarflare_chestplate
item_solarflare_chestplate4 = item_solarflare_chestplate
item_solarflare_chestplate5 = item_solarflare_chestplate
item_solarflare_chestplate6 = item_solarflare_chestplate
item_solarflare_chestplate7 = item_solarflare_chestplate
item_solarflare_chestplate8 = item_solarflare_chestplate
item_solarflare_chestplate9 = item_solarflare_chestplate
modifier_item_solarflare_chestplate = class(item_solarflare_chestplate)
modifier_item_solarflare_chestplate_burn = class(ItemBaseClassAura)
-------------
function item_solarflare_chestplate:GetIntrinsicModifierName()
    return "modifier_item_solarflare_chestplate"
end

function item_solarflare_chestplate:GetAOERadius()
    return self:GetSpecialValueFor("burn_radius")
end
-------------
function modifier_item_solarflare_chestplate:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        --MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        --MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE 
    }
end

function modifier_item_solarflare_chestplate:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_max_hp_regen")
end

function modifier_item_solarflare_chestplate:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_solarflare_chestplate:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_solarflare_chestplate:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_solarflare_chestplate:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_solarflare_chestplate:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("bonus_damage_reduction")

    self.effect_cast = ParticleManager:CreateParticle("particles/econ/items/spectre/spectre_arcana/spectre_arcana_radiance_owner_body.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl( self.effect_cast, 0, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, parent:GetAbsOrigin() )

    self:StartIntervalThink(0.1)
end

function modifier_item_solarflare_chestplate:OnIntervalThink()
    local abilityName = self:GetName()
    
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("bonus_damage_reduction")
end

function modifier_item_solarflare_chestplate:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex( self.effect_cast )
    end
end

function modifier_item_solarflare_chestplate:IsAura()
  return true
end

function modifier_item_solarflare_chestplate:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BUILDING)
end

function modifier_item_solarflare_chestplate:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_solarflare_chestplate:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("burn_radius")
end

function modifier_item_solarflare_chestplate:GetModifierAura()
    return "modifier_item_solarflare_chestplate_burn"
end

function modifier_item_solarflare_chestplate:GetAuraEntityReject(target)
    return false
end
---------------
function modifier_item_solarflare_chestplate_burn:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MISS_PERCENTAGE 
    }
end

function modifier_item_solarflare_chestplate_burn:GetModifierMiss_Percentage()
    return self:GetAbility():GetSpecialValueFor("burn_miss_chance")
end

function modifier_item_solarflare_chestplate_burn:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local radius = ability:GetSpecialValueFor("burn_radius")
    local damage = caster:GetMaxHealth() * (ability:GetSpecialValueFor("burn_max_hp_damage_pct")/100)

    ApplyDamage({
        victim = parent, 
        attacker = caster, 
        damage = damage, 
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
        ability = ability
    })
end

function modifier_item_solarflare_chestplate_burn:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("burn_interval")

    self:StartIntervalThink(interval)
end

function modifier_item_solarflare_chestplate_burn:GetEffectName()
    return "particles/units/heroes/hero_phoenix/phoenix_supernova_radiance.vpcf"
end