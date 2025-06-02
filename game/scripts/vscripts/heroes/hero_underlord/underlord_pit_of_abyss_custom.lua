LinkLuaModifier("modifier_underlord_pit_of_abyss_custom", "heroes/hero_underlord/underlord_pit_of_abyss_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_underlord_pit_of_abyss_custom_buff", "heroes/hero_underlord/underlord_pit_of_abyss_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_underlord_pit_of_abyss_custom_aura", "heroes/hero_underlord/underlord_pit_of_abyss_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

underlord_pit_of_abyss_custom = class(ItemBaseClass)
modifier_underlord_pit_of_abyss_custom = class(underlord_pit_of_abyss_custom)
modifier_underlord_pit_of_abyss_custom_buff = class(ItemBaseClassBuff)
modifier_underlord_pit_of_abyss_custom_aura = class(ItemBaseClassAura)
-------------
function underlord_pit_of_abyss_custom:GetIntrinsicModifierName()
    return "modifier_underlord_pit_of_abyss_custom"
end

function underlord_pit_of_abyss_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function underlord_pit_of_abyss_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local duration = self:GetSpecialValueFor("duration")

    caster:AddNewModifier(caster, self, "modifier_underlord_pit_of_abyss_custom_buff", {
        duration = duration
    })

    EmitSoundOn("Hero_AbyssalUnderlord.DarkRift.Cast", caster)
end
-----
function modifier_underlord_pit_of_abyss_custom_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local radius = ability:GetSpecialValueFor("radius")

    self.vfx = ParticleManager:CreateParticle("particles/econ/items/underlord/underlord_2021_immortal/underlord_2021_immortal_darkrift_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.vfx, 1, Vector(radius, 1, 1))
    ParticleManager:SetParticleControlEnt(
        self.vfx,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.vfx,
        2,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.vfx,
        5,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    self:AddParticle(
        self.vfx,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )

    self.stored = 0
end

function modifier_underlord_pit_of_abyss_custom_buff:OnDestroy()
    if not IsServer() then return end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local radius = ability:GetSpecialValueFor("radius")

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        ApplyDamage({
            victim = victim, 
            attacker = parent, 
            damage = self.stored, 
            damage_type = ability:GetAbilityDamageType(),
            ability = ability
        })
    end

    EmitSoundOn("Hero_AbyssalUnderlord.DarkRift.Complete", parent)
    EmitSoundOn("Hero_AbyssalUnderlord.DarkRift.Aftershock", parent)
end

function modifier_underlord_pit_of_abyss_custom_buff:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_underlord_pit_of_abyss_custom_buff:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if event.attacker ~= caster then return end
    if event.inflictor == nil then return end

    if event.inflictor ~= self:GetAbility() then return end

    self.stored = self.stored + event.damage
end

function modifier_underlord_pit_of_abyss_custom_buff:IsAura()
  return true
end

function modifier_underlord_pit_of_abyss_custom_buff:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_underlord_pit_of_abyss_custom_buff:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_underlord_pit_of_abyss_custom_buff:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_underlord_pit_of_abyss_custom_buff:GetModifierAura()
    return "modifier_underlord_pit_of_abyss_custom_aura"
end

function modifier_underlord_pit_of_abyss_custom_buff:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_underlord_pit_of_abyss_custom_buff:GetAuraEntityReject(target)
    return false
end 
------------
function modifier_underlord_pit_of_abyss_custom_aura:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    local interval = ability:GetSpecialValueFor("interval")
    local damage = ability:GetSpecialValueFor("damage") + (caster:GetStrength() * (ability:GetSpecialValueFor("str_to_damage")/100))
    
    self.damageTable = {
        victim = parent,
        attacker = caster,
        damage = damage * interval,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    }

    self:StartIntervalThink(interval)
end

function modifier_underlord_pit_of_abyss_custom_aura:OnIntervalThink()
    ApplyDamage(self.damageTable)
end

function modifier_underlord_pit_of_abyss_custom_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_underlord_pit_of_abyss_custom_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end