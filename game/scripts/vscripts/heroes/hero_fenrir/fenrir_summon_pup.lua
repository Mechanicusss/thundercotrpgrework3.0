LinkLuaModifier("modifier_fenrir_summon_pup", "heroes/hero_fenrir/fenrir_summon_pup", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fenrir_summon_pup_intrin", "heroes/hero_fenrir/fenrir_summon_pup", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fenrir_summon_pup_aura", "heroes/hero_fenrir/fenrir_summon_pup", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

fenrir_summon_pup = class(ItemBaseClass)
modifier_fenrir_summon_pup = class(fenrir_summon_pup)
modifier_fenrir_summon_pup_intrin = class(fenrir_summon_pup)
modifier_fenrir_summon_pup_aura = class(ItemBaseClassAura)
-------------
function fenrir_summon_pup:GetIntrinsicModifierName()
    return "modifier_fenrir_summon_pup_intrin"
end
------------
function modifier_fenrir_summon_pup_intrin:OnCreated()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local casterPos = caster:GetAbsOrigin()
    local ability = self:GetAbility()

    -- Delete Old Golems --
    local existing = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,ex in ipairs(existing) do
        if ex:GetUnitName() == "npc_dota_fenrir_pup" then
            UTIL_RemoveImmediate(ex)
        end
    end
    --
    
    local pos = Vector(casterPos.x+RandomInt(-200, 200), casterPos.y+RandomInt(-200, 200), casterPos.z)

    self.aurora = CreateUnitByName(
        "npc_dota_fenrir_pup",
        pos,
        true,
        caster,
        caster,
        caster:GetTeamNumber())

    self.aurora:SetControllableByPlayer(caster:GetPlayerID(), false)

    self.aurora:AddNewModifier(caster, ability, "modifier_fenrir_summon_pup", {})

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden_persona/cm_persona_freezing_field_cliff_reapear.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.aurora )
    ParticleManager:SetParticleControlEnt(
        self.particle,
        0,
        self.aurora,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        self.aurora:GetOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(self.particle)

    EmitSoundOn("Icewrack_Pup.Ult.Howl", caster)
end

function modifier_fenrir_summon_pup_intrin:OnRemoved()
    if not IsServer() then return end 

    if self.aurora ~= nil then
        self.aurora:ForceKill(false)
    end
end

function modifier_fenrir_summon_pup_intrin:IsHidden() return true end
------------
function modifier_fenrir_summon_pup:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetParent()

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden_persona/cm_persona_freezing_field_cliff_reapear.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt(
        self.particle,
        0,
        caster,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        caster:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(self.particle)

    if caster ~= nil then
        UTIL_RemoveImmediate(self:GetParent())
    end

    if self.particleAoe ~= nil then
        ParticleManager:DestroyParticle(self.particleAoe, true)
        ParticleManager:ReleaseParticleIndex(self.particleAoe)
    end
end


function modifier_fenrir_summon_pup:OnCreated()
    if not IsServer() then return end

    local caster = self:GetParent()
    local garm = self:GetCaster()

    self.garmPosOriginal = garm:GetAbsOrigin()
    self.garmPos = garm:GetAbsOrigin()

    local radius = self:GetAbility():GetSpecialValueFor("radius")

    self.particleAoe = ParticleManager:CreateParticle("particles/econ/items/juggernaut/jugg_fall20_immortal/jugg_fall20_immortal_healing_ward_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt(
        self.particleAoe,
        0,
        caster,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        caster:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    self.eternalTrigger = Entities:FindByName(nil, "wave_manager_zone")

    self:OnIntervalThink()
    self:StartIntervalThink(0.5)
end

function modifier_fenrir_summon_pup:OnIntervalThink()
    local caster = self:GetCaster()
    local casterOrigin = caster:GetAbsOrigin()

    self.garmPos = casterOrigin
    
    local distance = 300

    local offsetX = RandomInt(-distance, distance)
    local offsetY = RandomInt(-distance, distance)

    local randomPos = Vector(casterOrigin.x+offsetX, casterOrigin.y+offsetY, casterOrigin.z)

    local parent = self:GetParent()
    if not parent:IsMoving() and self.garmPos ~= self.garmPosOriginal then
        parent:MoveToPosition(randomPos)
        self.garmPosOriginal = self.garmPos
    end

    if RandomFloat(0.0, 100.0) <= 10 then
        local sounds = {
            "Icewrack_Pup.Pant",
            "Icewrack_Pup.Breath",
            "Icewrack_Pup.Happy",
            "Icewrack_Pup.idle_alt_shake",
            "Icewrack_Pup.idle_alt_bark",
            "Icewrack_Pup.Flee",
            "Icewrack_Pup.Alert",
            "Icewrack_Pup.Yawn",
            "Icewrack_Pup.Scritch",
        }

        EmitSoundOn(sounds[RandomInt(1, #sounds)], parent)
    end

    if self.eternalTrigger ~= nil then
        if (IsInTrigger(caster, self.eternalTrigger) and not IsInTrigger(parent, self.eternalTrigger)) or ((caster:GetAbsOrigin()-parent:GetAbsOrigin()):Length2D() > 1000) then
            FindClearSpaceForUnit(parent, caster:GetAbsOrigin(), false)
        end
    end
end

function modifier_fenrir_summon_pup:CheckState()
  return {
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_CANNOT_TARGET_ENEMIES] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
    [MODIFIER_STATE_UNTARGETABLE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
end

function modifier_fenrir_summon_pup:IsAura()
  return true
end

function modifier_fenrir_summon_pup:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_fenrir_summon_pup:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_fenrir_summon_pup:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_fenrir_summon_pup:GetModifierAura()
    return "modifier_fenrir_summon_pup_aura"
end

function modifier_fenrir_summon_pup:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_fenrir_summon_pup:GetAuraEntityReject(target)
    return false
end

function modifier_fenrir_summon_pup:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE 
    }
end

function modifier_fenrir_summon_pup:GetModifierIgnoreMovespeedLimit()
    return 1
end

function modifier_fenrir_summon_pup:GetModifierMoveSpeedOverride()
    return self:GetCaster():GetMoveSpeedModifier(self:GetCaster():GetBaseMoveSpeed(), true)
end
-----------
function modifier_fenrir_summon_pup_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET 
    }
end

function modifier_fenrir_summon_pup_aura:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("increased_damage")
end

function modifier_fenrir_summon_pup_aura:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("increased_healing")
end