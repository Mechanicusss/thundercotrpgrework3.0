LinkLuaModifier("modifier_ancient_apparition_chilling_ground", "heroes/hero_ancient_apparition/ancient_apparition_chilling_ground", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ancient_apparition_chilling_ground_emitter", "heroes/hero_ancient_apparition/ancient_apparition_chilling_ground", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ancient_apparition_chilling_ground_emitter_aura", "heroes/hero_ancient_apparition/ancient_apparition_chilling_ground", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ancient_apparition_chilling_frozen_debuff", "heroes/hero_ancient_apparition/ancient_apparition_chilling_ground", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

ancient_apparition_chilling_ground = class(ItemBaseClass)
boss_ancient_apparition_chilling_ground = ancient_apparition_chilling_ground
modifier_ancient_apparition_chilling_ground = class(ancient_apparition_chilling_ground)
modifier_ancient_apparition_chilling_ground_emitter = class(ItemBaseClass)
modifier_ancient_apparition_chilling_ground_emitter_aura = class(ItemBaseAura)
modifier_ancient_apparition_chilling_frozen_debuff = class(ItemBaseClassDebuff)
-------------
function ancient_apparition_chilling_ground:GetIntrinsicModifierName()
    return "modifier_ancient_apparition_chilling_ground"
end

function ancient_apparition_chilling_ground:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function ancient_apparition_chilling_ground:OnSpellStart()
    if not IsServer() then return end
--
    local point = self:GetCursorPosition()
    local caster = self:GetCaster()
    local ability = self

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNewModifier(caster, ability, "modifier_ancient_apparition_chilling_ground_emitter", { 
        duration = duration
    })
    -- --

    caster:EmitSound("Hero_Ancient_Apparition.IceVortexCast")
end
------------
function modifier_ancient_apparition_chilling_ground:DeclareFunctions()
    local funcs = {}

    return funcs
end

function modifier_ancient_apparition_chilling_ground:OnCreated()
    if not IsServer() then return end
end
----------------
function modifier_ancient_apparition_chilling_ground_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_ancient_apparition_chilling_ground_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_ancient_apparition_chilling_ground_emitter:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    self.interval = ability:GetSpecialValueFor("interval")
    self.damage = ability:GetSpecialValueFor("damage")
    self.intToDamage = ability:GetSpecialValueFor("int_to_damage")

    -- Start the thinker to drain hp/do damage --
    self:StartIntervalThink(self.interval)

    self.vfx = ParticleManager:CreateParticle("particles/econ/items/ancient_apparition/ancient_apparation_ti8/ancient_ice_vortex_ti8.vpcf", PATTACH_WORLDORIGIN, self.parent)
    ParticleManager:SetParticleControl(self.vfx, 0, self.parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 5, Vector(self.radius, self.radius, self.radius))
end

function modifier_ancient_apparition_chilling_ground_emitter:OnIntervalThink()
    local units = FindUnitsInRadius(self.caster:GetTeam(), self.parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    local intellectDamage = 0
    if self.caster:IsRealHero() then
        intellectDamage = self.caster:GetBaseIntellect()
    end

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            ApplyDamage({
                victim = unit,
                attacker = self.caster,
                damage = (self.damage + (intellectDamage * (self.intToDamage/100))) * self.interval,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            })
        end
    end
end

function modifier_ancient_apparition_chilling_ground_emitter:OnDestroy()
    if not IsServer() then return end

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_ancient_apparition_chilling_ground_emitter:CheckState()
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
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end

function modifier_ancient_apparition_chilling_ground_emitter:IsAura()
  return true
end

function modifier_ancient_apparition_chilling_ground_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_ancient_apparition_chilling_ground_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ancient_apparition_chilling_ground_emitter:GetAuraRadius()
  return self.radius
end

function modifier_ancient_apparition_chilling_ground_emitter:GetModifierAura()
    return "modifier_ancient_apparition_chilling_ground_emitter_aura"
end

function modifier_ancient_apparition_chilling_ground_emitter:GetAuraEntityReject(ent) 
    return false
end
--------------
function modifier_ancient_apparition_chilling_ground_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_DISABLE_HEALING,
    }

    return funcs
end

function modifier_ancient_apparition_chilling_ground_emitter_aura:GetDisableHealing()
    if self:GetCaster():HasTalent("special_bonus_unique_ancient_apparition_6_custom") then
        return 1
    end

    return 0
end

function modifier_ancient_apparition_chilling_ground_emitter_aura:OnCreated()
    if not IsServer() then return end

    self.freezeCounter = 0
    self.freezeLimit = self:GetAbility():GetSpecialValueFor("time_limit")
    self.freezeDuration = self:GetAbility():GetSpecialValueFor("freeze_duration")
    self.freezeInterval = self:GetAbility():GetSpecialValueFor("interval")

    self:StartIntervalThink(self.freezeInterval)
end

function modifier_ancient_apparition_chilling_ground_emitter_aura:OnIntervalThink()
    local parent = self:GetParent()

    if not parent:HasModifier("modifier_ancient_apparition_chilling_frozen_debuff") then
        self.freezeCounter = self.freezeCounter + self.freezeInterval
    end

    if self.freezeCounter == self.freezeLimit and not parent:HasModifier("modifier_ancient_apparition_chilling_frozen_debuff") then
        parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_ancient_apparition_chilling_frozen_debuff", {
            duration = self.freezeDuration
        })

        self.freezeCounter = 0
    end

    EmitSoundOn("Hero_Ancient_Apparition.ColdFeetTick", parent)
end

function modifier_ancient_apparition_chilling_ground_emitter_aura:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end

function modifier_ancient_apparition_chilling_ground_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_ancient_apparition_chilling_ground_emitter_aura:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("resistance")
end

function modifier_ancient_apparition_chilling_frozen_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_FROZEN] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true
    }

    return state
end

function modifier_ancient_apparition_chilling_frozen_debuff:OnCreated()
    EmitSoundOn("Hero_Ancient_Apparition.ColdFeetFreeze", self:GetParent())
end

function modifier_ancient_apparition_chilling_frozen_debuff:GetEffectName()
    return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_cold_feet_frozen.vpcf"
end