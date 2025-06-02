LinkLuaModifier("modifier_follower_spider_sandstorm", "heroes/bosses/spider/follower_spider_sandstorm", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_follower_spider_sandstorm_emitter", "heroes/bosses/spider/follower_spider_sandstorm", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_follower_spider_sandstorm_emitter_aura", "heroes/bosses/spider/follower_spider_sandstorm", LUA_MODIFIER_MOTION_NONE)

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

follower_spider_sandstorm = class(ItemBaseClass)
boss_follower_spider_sandstorm = follower_spider_sandstorm
modifier_follower_spider_sandstorm = class(follower_spider_sandstorm)
modifier_follower_spider_sandstorm_emitter = class(ItemBaseClass)
modifier_follower_spider_sandstorm_emitter_aura = class(ItemBaseAura)
-------------
function follower_spider_sandstorm:GetIntrinsicModifierName()
    return "modifier_follower_spider_sandstorm"
end

function follower_spider_sandstorm:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function follower_spider_sandstorm:OnSpellStart()
    if not IsServer() then return end
--
    local point = self:GetCursorPosition()
    local caster = self:GetCaster()
    local ability = self

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNewModifier(caster, ability, "modifier_follower_spider_sandstorm_emitter", { 
        duration = duration
    })
    -- --

    caster:EmitSound("Ability.SandKing_SandStorm.start")
end
------------
function modifier_follower_spider_sandstorm:DeclareFunctions()
    local funcs = {}

    return funcs
end

function modifier_follower_spider_sandstorm:OnCreated()
    if not IsServer() then return end
end
----------------
function modifier_follower_spider_sandstorm_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_follower_spider_sandstorm_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_follower_spider_sandstorm_emitter:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_sandstorm.vpcf", PATTACH_WORLDORIGIN, self.parent)
    ParticleManager:SetParticleControl(self.vfx, 0, self.parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 1, Vector(self.radius, self.radius, self.radius))

    EmitSoundOn("Ability.SandKing_SandStorm.loop", self.parent)
end

function modifier_follower_spider_sandstorm_emitter:OnDestroy()
    if not IsServer() then return end

    StopSoundOn("Ability.SandKing_SandStorm.loop", self:GetParent())

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_follower_spider_sandstorm_emitter:CheckState()
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

function modifier_follower_spider_sandstorm_emitter:IsAura()
  return true
end

function modifier_follower_spider_sandstorm_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_follower_spider_sandstorm_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_follower_spider_sandstorm_emitter:GetAuraRadius()
  return self.radius
end

function modifier_follower_spider_sandstorm_emitter:GetModifierAura()
    return "modifier_follower_spider_sandstorm_emitter_aura"
end

function modifier_follower_spider_sandstorm_emitter:GetAuraEntityReject(ent) 
    return false
end
--------------
function modifier_follower_spider_sandstorm_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_follower_spider_sandstorm_emitter_aura:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("interval")

    self.damageTable = {
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage = ability:GetSpecialValueFor("damage") * interval,
        ability = ability,
        damage_type = ability:GetAbilityDamageType()
    }

    self:StartIntervalThink(interval)
end

function modifier_follower_spider_sandstorm_emitter_aura:OnIntervalThink()
    if self:GetParent():IsMagicImmune() then return end
    ApplyDamage(self.damageTable)
end

function modifier_follower_spider_sandstorm_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    if self:GetParent():IsMagicImmune() then return end
    return self:GetAbility():GetSpecialValueFor("slow")
end
