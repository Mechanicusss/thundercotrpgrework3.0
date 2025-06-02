LinkLuaModifier("modifier_lich_ice_spire_custom_field", "heroes/hero_lich/ice_spire/lich_ice_spire_custom_field", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lich_ice_spire_custom_field_aura", "heroes/hero_lich/ice_spire/lich_ice_spire_custom_field", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

lich_ice_spire_custom_field = class(ItemBaseClass)
modifier_lich_ice_spire_custom_field = class(lich_ice_spire_custom_field)
modifier_lich_ice_spire_custom_field_aura = class(ItemBaseClassAura)
-------------
function lich_ice_spire_custom_field:GetIntrinsicModifierName()
    return "modifier_lich_ice_spire_custom_field"
end
---------
function modifier_lich_ice_spire_custom_field:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_lich/lich_ice_spire.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControl(self.effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.effect_cast, 1, Vector(parent:GetAbsOrigin().x, 0, 142.828))
    ParticleManager:SetParticleControl(self.effect_cast, 2, Vector(parent:GetAbsOrigin().x, 0, 213.386))
    ParticleManager:SetParticleControl(self.effect_cast, 3, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.effect_cast, 4, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.effect_cast, 5, Vector(600,600,600))  
end

function modifier_lich_ice_spire_custom_field:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_lich_ice_spire_custom_field:IsAura()
  return true
end

function modifier_lich_ice_spire_custom_field:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_lich_ice_spire_custom_field:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_lich_ice_spire_custom_field:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_lich_ice_spire_custom_field:GetModifierAura()
    return "modifier_lich_ice_spire_custom_field_aura"
end

function modifier_lich_ice_spire_custom_field:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_lich_ice_spire_custom_field:GetAuraEntityReject(target)
    return false
end
---------------
function modifier_lich_ice_spire_custom_field_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_lich_ice_spire_custom_field_aura:GetModifierMoveSpeedBonus_Percentage()
    if self:GetAbility() == nil then return end
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_lich_ice_spire_custom_field_aura:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local owner = caster:GetOwner()
    local innateIceSpire = owner:FindAbilityByName("lich_ice_spire_custom")

    if innateIceSpire == nil then return end

    local interval = ability:GetSpecialValueFor("interval")
    local damage = ability:GetSpecialValueFor("damage") + (owner:GetBaseIntellect() * (innateIceSpire:GetSpecialValueFor("int_to_damage")/100))

    self.damageTable = {
        victim = parent,
        attacker = owner,
        damage = damage*interval,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    }

    self:StartIntervalThink(interval)
end

function modifier_lich_ice_spire_custom_field_aura:OnIntervalThink()
    ApplyDamage(self.damageTable)
end

function modifier_lich_ice_spire_custom_field_aura:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end