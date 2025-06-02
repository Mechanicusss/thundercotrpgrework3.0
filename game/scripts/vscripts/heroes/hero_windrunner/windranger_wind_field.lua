LinkLuaModifier("modifier_windranger_wind_field", "heroes/hero_windrunner/windranger_wind_field", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_windranger_wind_field_emitter", "heroes/hero_windrunner/windranger_wind_field", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_windranger_wind_field_emitter_aura", "heroes/hero_windrunner/windranger_wind_field", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_windranger_wind_field_emitter_aura_ally", "heroes/hero_windrunner/windranger_wind_field", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseAuraAlly = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

windranger_wind_field = class(ItemBaseClass)
modifier_windranger_wind_field = class(windranger_wind_field)
modifier_windranger_wind_field_emitter = class(ItemBaseClass)
modifier_windranger_wind_field_emitter_aura = class(ItemBaseAura)
modifier_windranger_wind_field_emitter_aura_ally = class(ItemBaseAuraAlly)
-------------
function windranger_wind_field:GetIntrinsicModifierName()
    return "modifier_windranger_wind_field"
end

function windranger_wind_field:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function windranger_wind_field:OnSpellStart()
    if not IsServer() then return end
--
    local point = self:GetCursorPosition()
    local caster = self:GetCaster()
    local ability = self

    local radius = ability:GetSpecialValueFor("radius")
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    -- Particle --
    local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_windrunner/windrunner_gale_force_owner.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(vfx, 0, point)
    ParticleManager:SetParticleControl(vfx, 1, Vector(radius, radius, radius))
    -- --

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNoDraw()
    emitter:AddNewModifier(caster, ability, "modifier_windranger_wind_field_emitter", { 
        duration = duration
    })
    -- --

    caster:EmitSound("Hero_Windrunner.GaleForce")

    Timers:CreateTimer(duration, function()
        ParticleManager:DestroyParticle(vfx, true)
        ParticleManager:ReleaseParticleIndex(vfx)
        --emitter:Kill(nil, nil)
        UTIL_RemoveImmediate(emitter)
    end)
end
----------
function modifier_windranger_wind_field_emitter:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    self.interval = ability:GetSpecialValueFor("interval")
    self.damage = ability:GetSpecialValueFor("damage")
    self.intToDamage = ability:GetSpecialValueFor("int_to_damage")
    self.increasePerSec = ability:GetSpecialValueFor("increase_per_sec_pct")/100

    self.aura = "modifier_windranger_wind_field_emitter_aura"

    self.multiplier = 1

    -- Start the thinker to drain hp/do damage --
    self:StartIntervalThink(self.interval)
end

function modifier_windranger_wind_field_emitter:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    local units = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    self.multiplier = self.multiplier + (self.increasePerSec*self.interval)

    local damage = (self.damage + (caster:GetBaseIntellect() * (self.intToDamage/100))) * self.multiplier * self.interval

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            ApplyDamage({
                victim = unit,
                attacker = caster,
                damage = damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            })
        end
    end
end

function modifier_windranger_wind_field_emitter:OnDestroy()
    if not IsServer() then return end

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end
end

function modifier_windranger_wind_field_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true
    }   

    return state
end

function modifier_windranger_wind_field_emitter:IsAura()
  return true
end

function modifier_windranger_wind_field_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_windranger_wind_field_emitter:GetAuraSearchTeam()
  return bit.bor(DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_TEAM_ENEMY)
end

function modifier_windranger_wind_field_emitter:GetAuraRadius()
  return self.radius
end

function modifier_windranger_wind_field_emitter:GetModifierAura()
    return self.aura
end

function modifier_windranger_wind_field_emitter:GetAuraEntityReject(ent) 
    if ent:GetTeamNumber() == self:GetCaster():GetTeamNumber() then
        self.aura = "modifier_windranger_wind_field_emitter_aura_ally"
    else
        self.aura = "modifier_windranger_wind_field_emitter_aura"
    end

    return false
end
--------------
function modifier_windranger_wind_field_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_windranger_wind_field_emitter_aura:OnCreated()
    if not IsServer() then return end
end

function modifier_windranger_wind_field_emitter_aura:GetEffectName()
    return "particles/units/heroes/hero_windrunner/windrunner_gale_force.vpcf"
end

function modifier_windranger_wind_field_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end
--------
function modifier_windranger_wind_field_emitter_aura_ally:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE  
    }
end

function modifier_windranger_wind_field_emitter_aura_ally:GetModifierIncomingPhysicalDamage_Percentage(event)
    if not IsServer() then return end

    if event.target ~= self:GetParent() then return end
    if event.target == event.attacker then return end
    if not event.attacker:IsRangedAttacker() then return end

    return -100
end