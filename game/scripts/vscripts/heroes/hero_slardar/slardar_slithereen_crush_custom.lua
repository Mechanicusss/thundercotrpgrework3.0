LinkLuaModifier("modifier_slardar_slithereen_crush_custom", "heroes/hero_slardar/slardar_slithereen_crush_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slardar_slithereen_crush_custom_emitter", "heroes/hero_slardar/slardar_slithereen_crush_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slardar_slithereen_crush_custom_emitter_aura", "heroes/hero_slardar/slardar_slithereen_crush_custom", LUA_MODIFIER_MOTION_NONE)

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

slardar_slithereen_crush_custom = class(ItemBaseClass)
boss_slardar_slithereen_crush_custom = slardar_slithereen_crush_custom
modifier_slardar_slithereen_crush_custom = class(slardar_slithereen_crush_custom)
modifier_slardar_slithereen_crush_custom_emitter = class(ItemBaseClass)
modifier_slardar_slithereen_crush_custom_emitter_aura = class(ItemBaseAura)
-------------
function slardar_slithereen_crush_custom:GetIntrinsicModifierName()
    return "modifier_slardar_slithereen_crush_custom"
end

function slardar_slithereen_crush_custom:GetAOERadius()
    return self:GetSpecialValueFor("crush_radius")
end

function slardar_slithereen_crush_custom:OnSpellStart()
    if not IsServer() then return end
--
    local caster = self:GetCaster()
    local point = caster:GetAbsOrigin()
    local ability = self

    local duration = ability:GetLevelSpecialValueFor("puddle_duration", (ability:GetLevel() - 1))

    local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        ability:GetSpecialValueFor("crush_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            ApplyDamage({
                victim = unit,
                attacker = caster,
                damage = (self:GetSpecialValueFor("crush_damage") + (caster:GetStrength() * (self:GetSpecialValueFor("str_to_damage")/100))),
                damage_type = self:GetAbilityDamageType(),
                ability = self
            })

            unit:AddNewModifier(caster, nil, "modifier_stunned", {
                duration = self:GetSpecialValueFor("stun_duration")
            })
        end
    end

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNewModifier(caster, ability, "modifier_slardar_slithereen_crush_custom_emitter", { 
        duration = duration
    })
    -- --

    caster:EmitSound("Hero_Slardar.Slithereen_Crush")
end
------------
function modifier_slardar_slithereen_crush_custom:DeclareFunctions()
    local funcs = {}

    return funcs
end

function modifier_slardar_slithereen_crush_custom:OnCreated()
    if not IsServer() then return end
end
----------------
function modifier_slardar_slithereen_crush_custom_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_slardar_slithereen_crush_custom_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_slardar_slithereen_crush_custom_emitter:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("crush_radius")

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_slardar/slardar_water_puddle.vpcf", PATTACH_POINT, self.parent)
    ParticleManager:SetParticleControl(self.vfx, 0, self.parent:GetAbsOrigin())
end

function modifier_slardar_slithereen_crush_custom_emitter:OnDestroy()
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

function modifier_slardar_slithereen_crush_custom_emitter:CheckState()
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

function modifier_slardar_slithereen_crush_custom_emitter:IsAura()
  return true
end

function modifier_slardar_slithereen_crush_custom_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_slardar_slithereen_crush_custom_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_slardar_slithereen_crush_custom_emitter:GetAuraRadius()
  return self.radius
end

function modifier_slardar_slithereen_crush_custom_emitter:GetModifierAura()
    return "modifier_slardar_slithereen_crush_custom_emitter_aura"
end

function modifier_slardar_slithereen_crush_custom_emitter:GetAuraEntityReject(ent) 
    if ent:GetTeamNumber() == self:GetCaster():GetTeamNumber() and ent ~= self:GetCaster() then
        return true
    end

    return false
end
--------------
function modifier_slardar_slithereen_crush_custom_emitter_aura:OnCreated()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local parent = self:GetParent()

    if caster:GetTeam() ~= parent:GetTeam() then
        if caster:HasModifier("modifier_item_aghanims_shard") then
            local haze = caster:FindAbilityByName("slardar_amplify_damage_custom")
            if haze ~= nil and haze:GetLevel() > 0 then
                parent:AddNewModifier(caster, haze, "modifier_slardar_amplify_damage_custom_debuff", {
                    duration = haze:GetSpecialValueFor("duration")
                })
            end
        end
    end
end

function modifier_slardar_slithereen_crush_custom_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE 
    }

    return funcs
end

function modifier_slardar_slithereen_crush_custom_emitter_aura:GetStatusEffectName()
    return "particles/status_fx/status_effect_slardar_crush.vpcf"
end

function modifier_slardar_slithereen_crush_custom_emitter_aura:IsDebuff()
    if self:GetCaster() ~= self:GetParent() then
        return true
    else
        return false
    end
end

function modifier_slardar_slithereen_crush_custom_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    if self:GetCaster() ~= self:GetParent() then
        return self:GetAbility():GetSpecialValueFor("puddle_slow")
    else
        return self:GetAbility():GetSpecialValueFor("puddle_speed_increase")
    end
end

function modifier_slardar_slithereen_crush_custom_emitter_aura:GetModifierAttackSpeedPercentage()
    if self:GetCaster() ~= self:GetParent() then
        return self:GetAbility():GetSpecialValueFor("puddle_slow")
    else
        return self:GetAbility():GetSpecialValueFor("puddle_speed_increase")
    end
end