LinkLuaModifier("modifier_riki_decoy", "heroes/hero_riki/riki_decoy.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_riki_decoy_emitter", "heroes/hero_riki/riki_decoy.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_riki_decoy_emitter_aura", "heroes/hero_riki/riki_decoy.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_riki_decoy_sleep_debuff", "heroes/hero_riki/riki_decoy.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return true end,
}

riki_decoy = class(ItemBaseClass)
modifier_riki_decoy = class(riki_decoy)
modifier_riki_decoy_emitter = class(ItemBaseClass)
modifier_riki_decoy_emitter_aura = class(ItemBaseAura)
modifier_riki_decoy_sleep_debuff = class(ItemBaseClassDebuff)
-------------
function riki_decoy:GetIntrinsicModifierName()
    return "modifier_riki_decoy"
end

function riki_decoy:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function riki_decoy:OnSpellStart()
    if not IsServer() then return end
--
    local point = self:GetCursorPosition()
    local caster = self:GetCaster()
    local ability = self

    EmitSoundOn("Hero_Riki.SleepDart.Cast", caster)

    -- Flash --
    local vfxFlash = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_shard_sleeping_dart_cast.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(vfxFlash, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(vfxFlash, 2, caster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfxFlash)
    -- --

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    local radius = ability:GetSpecialValueFor("radius")

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("npc_dota_hero_riki_decoy_custom", point, false, caster, caster, caster:GetTeamNumber())

    emitter:SetBaseMaxHealth(ability:GetSpecialValueFor("max_hits"))
    emitter:SetMaxHealth(ability:GetSpecialValueFor("max_hits"))
    emitter:SetHealth(ability:GetSpecialValueFor("max_hits"))

    emitter:AddNewModifier(caster, ability, "modifier_riki_decoy_emitter", { 
        duration = duration
    })
    -- --

    emitter:EmitSound("Hero_Riki.Smoke_Screen.ti8")

    Timers:CreateTimer(duration, function()
        --emitter:Kill(nil, nil)
        if emitter ~= nil and not emitter:IsNull() then
            UTIL_Remove(emitter)
        end
    end)
end
-----------
function modifier_riki_decoy:OnCreated()
    if not IsServer() then return end
end
----------------
function modifier_riki_decoy_emitter:RemoveOnDeath() return true end

function modifier_riki_decoy_emitter:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_ATTACKED,
        MODIFIER_PROPERTY_DISABLE_HEALING,
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_riki_decoy_emitter:OnAttacked( params )
    if IsServer() then
        if self:GetParent() == params.target then
            if params.attacker then
                self:GetParent():ModifyHealth( self:GetParent():GetHealth() - 1, nil, true, 0 )
            end
        end
    end

    return 0
end

function modifier_riki_decoy_emitter:GetDisableHealing()
    return 1
end

function modifier_riki_decoy_emitter:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_riki_decoy_emitter:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_riki_decoy_emitter:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_riki_decoy_emitter:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    self.interval = ability:GetSpecialValueFor("interval")
    self.radius = ability:GetSpecialValueFor("radius")

    -- Particle --
    self.vfx = ParticleManager:CreateParticle("particles/econ/items/riki/riki_head_ti8/riki_smokebomb_ti8.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(self.vfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 1, Vector(self.radius, self.radius, self.radius))
    -- --

    -- Start the thinker to drain hp/do damage --
    self:StartIntervalThink(self.interval)
end

function modifier_riki_decoy_emitter:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    local units = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if unit:IsAlive() and not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            unit:SetForceAttackTarget(parent)

            ApplyDamage({
                attacker = caster,
                victim = unit,
                damage = self:GetAbility():GetSpecialValueFor("damage") + (caster:GetAgility() * (self:GetAbility():GetSpecialValueFor("agi_to_damage")/100)),
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            })
        end
    end
end

function modifier_riki_decoy_emitter:OnDestroy()
    if not IsServer() then return end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_riki_decoy_emitter:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.unit ~= parent then return end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    if self:GetParent():IsAlive() then
        local units = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,unit in ipairs(units) do
            if unit:IsAlive() then
                unit:SetForceAttackTarget(nil)
                unit:SetAttacking(nil)
                unit:MoveToPositionAggressive(unit:GetAbsOrigin())
            end
        end

        if parent ~= nil and not parent:IsNull() then
            UTIL_Remove(parent)
        end
    end
end

function modifier_riki_decoy_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_SPECIALLY_UNDENIABLE] = true
    }   

    return state
end

function modifier_riki_decoy_emitter:IsAura()
  return true
end

function modifier_riki_decoy_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_riki_decoy_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_riki_decoy_emitter:GetAuraRadius()
  return self.radius
end

function modifier_riki_decoy_emitter:GetModifierAura()
    return "modifier_riki_decoy_emitter_aura"
end

function modifier_riki_decoy_emitter:GetAuraEntityReject(ent) 
    return false
end

function modifier_riki_decoy_emitter:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_riki_decoy_emitter:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_riki_decoy_emitter:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_riki_decoy_emitter:StatusEffectPriority()
    return 10001
end
--------------
function modifier_riki_decoy_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function modifier_riki_decoy_emitter_aura:OnCreated()
    if not IsServer() then return end

    self.sleepCounter = 0
    self.sleepDuration = self:GetAbility():GetSpecialValueFor("sleep_duration")
    self.sleepThreshold = self:GetAbility():GetSpecialValueFor("sleep_threshold")
    self.interval = self:GetAbility():GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(self.interval)
end

function modifier_riki_decoy_emitter_aura:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if parent:HasModifier("modifier_riki_decoy_sleep_debuff") then return end

    self.sleepCounter = self.sleepCounter + 1

    if self.sleepCounter >= self.sleepThreshold then
        parent:AddNewModifier(caster, self:GetAbility(), "modifier_riki_decoy_sleep_debuff", {
            duration = self.sleepDuration
        })

        self.sleepCounter = 0
    end
end

function modifier_riki_decoy_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_riki_decoy_sleep_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function modifier_riki_decoy_sleep_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true
    }

    return state
end

function modifier_riki_decoy_sleep_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.sleepOverheadSign = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_shard_sleep_debuff.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.sleepOverheadSign, 0, parent:GetAbsOrigin())

    EmitSoundOn("Hero_Riki.SleepDart.Target", self:GetParent())
end

function modifier_riki_decoy_sleep_debuff:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.sleepOverheadSign, true)
    ParticleManager:ReleaseParticleIndex(self.sleepOverheadSign)
end

function modifier_riki_decoy_sleep_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("sleep_incoming_damage")
end