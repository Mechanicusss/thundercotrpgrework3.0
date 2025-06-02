LinkLuaModifier("modifier_doom_doomsday_apocalypse", "heroes/hero_doom/doom_doomsday_apocalypse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doom_doomsday_apocalypse_emitter", "heroes/hero_doom/doom_doomsday_apocalypse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doom_doomsday_apocalypse_emitter_aura", "heroes/hero_doom/doom_doomsday_apocalypse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doom_doomsday_apocalypse_emitter_aura_friendly", "heroes/hero_doom/doom_doomsday_apocalypse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_doom_doomsday_apocalypse_soul_stacks", "heroes/hero_doom/doom_doomsday_apocalypse", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

local ItemBaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

doom_doomsday_apocalypse = class(ItemBaseClass)
modifier_doom_doomsday_apocalypse = class(doom_doomsday_apocalypse)
modifier_doom_doomsday_apocalypse_emitter = class(ItemBaseClass)
modifier_doom_doomsday_apocalypse_emitter_aura = class(ItemBaseAura)
modifier_doom_doomsday_apocalypse_emitter_aura_friendly = class(ItemBaseAura)
modifier_doom_doomsday_apocalypse_soul_stacks = class(ItemBaseClassStacks)
-------------
function doom_doomsday_apocalypse:GetIntrinsicModifierName()
    return "modifier_doom_doomsday_apocalypse"
end

function doom_doomsday_apocalypse:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function doom_doomsday_apocalypse:GetCooldown()
    if self:GetCaster():HasScepter() then
        return self:GetSpecialValueFor("scepter_cooldown")
    end

    return self.BaseClass.GetCooldown(self, -1) or 0
end

function doom_doomsday_apocalypse:OnSpellStart()
    if not IsServer() then return end
--
    local point = self:GetCursorPosition()
    local caster = self:GetCaster()
    local ability = self

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    -- Particle --
    local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_doom_aura.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(vfx, 0, point)
    ParticleManager:SetParticleControl(vfx, 3, point)
    ParticleManager:SetParticleControl(vfx, 4, point)
    -- --

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNewModifier(caster, ability, "modifier_doom_doomsday_apocalypse_emitter", { 
        duration = duration
    })
    -- --

    emitter:EmitSound("Hero_DoomBringer.Doom")

    Timers:CreateTimer(duration, function()
        ParticleManager:DestroyParticle(vfx, true)
        ParticleManager:ReleaseParticleIndex(vfx)
        --emitter:Kill(nil, nil)
        UTIL_RemoveImmediate(emitter)
    end)
end
------------
function modifier_doom_doomsday_apocalypse:DeclareFunctions()
    local funcs = {
        --MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_doom_doomsday_apocalypse:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local victim = event.unit

    if parent ~= event.attacker then return end
    if not victim:HasModifier("modifier_doom_doomsday_apocalypse_emitter_aura") then return end

    local buff = parent:FindModifierByName("modifier_doom_doomsday_apocalypse_soul_stacks")
    if buff == nil then
        buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_doom_doomsday_apocalypse_soul_stacks", {})
    end

    if buff and buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then buff:IncrementStackCount() end
end

function modifier_doom_doomsday_apocalypse_soul_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
----------------
function modifier_doom_doomsday_apocalypse_emitter:OnCreated()
    self.aura_modifier_name = "modifier_doom_doomsday_apocalypse_emitter_aura"
end

function modifier_doom_doomsday_apocalypse_emitter:IsAura()
    return true
end

function modifier_doom_doomsday_apocalypse_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_doom_doomsday_apocalypse_emitter:GetAuraSearchTeam()
  return bit.bor(DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_TEAM_FRIENDLY)
end

function modifier_doom_doomsday_apocalypse_emitter:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_doom_doomsday_apocalypse_emitter:GetModifierAura()
    return self.aura_modifier_name
end

function modifier_doom_doomsday_apocalypse_emitter:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS)
end

function modifier_doom_doomsday_apocalypse_emitter:GetAuraEntityReject(target)
    if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then
        self.aura_modifier_name = "modifier_doom_doomsday_apocalypse_emitter_aura"
        return false
    end

    return true
end

function modifier_doom_doomsday_apocalypse_emitter:OnDestroy()
    if not IsServer() then return end

    if self:GetParent():IsAlive() then
        self:GetParent():StopSound("Hero_DoomBringer.Doom")
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end
end

function modifier_doom_doomsday_apocalypse_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
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
-----------
function modifier_doom_doomsday_apocalypse_emitter_aura:IsDebuff() return true end

function modifier_doom_doomsday_apocalypse_emitter_aura:CheckState()
    local state = {
        [MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_PASSIVES_DISABLED] = true,
        [MODIFIER_STATE_DISARMED] = true,
    }   

    return state
end
function modifier_doom_doomsday_apocalypse_emitter_aura:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    self.interval = ability:GetSpecialValueFor("interval")
    self.damage = ability:GetSpecialValueFor("damage")
    self.strToDamage = ability:GetSpecialValueFor("strength_to_damage")

    self:OnIntervalThink()
    self:StartIntervalThink(self.interval)

    local particle_cast = "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControl( self.effect_cast, 0, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 4, parent:GetAbsOrigin() )
end

function modifier_doom_doomsday_apocalypse_emitter_aura:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_doom_doomsday_apocalypse_emitter_aura:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    if not parent:IsMagicImmune() and not parent:IsInvulnerable() then
        ApplyDamage({
            victim = parent,
            attacker = caster,
            damage = (self.damage + (caster:GetBaseIntellect() * (self.strToDamage/100))) * self.interval,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })
    end
end

--[[
function modifier_doom_doomsday_apocalypse_soul_stacks:OnStackCountChanged(old)
    if not IsServer() then return end

    local parent = self:GetParent()
    local servant = parent:FindAbilityByName("doom_infernal_servant")
    if servant ~= nil and servant:GetLevel() > 0 then
        if self:GetStackCount() >= servant:GetSpecialValueFor("stacks_required") then
            servant:SetActivated(true)
        else
            servant:SetActivated(false)
        end
    else
        servant:SetActivated(false)
    end
end
--]]
------
function modifier_doom_doomsday_apocalypse_emitter_aura_friendly:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function modifier_doom_doomsday_apocalypse_emitter_aura_friendly:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_reduction")
end