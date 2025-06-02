LinkLuaModifier("modifier_legion_commander_battlefield_custom", "heroes/hero_legion_commander/legion_commander_battlefield_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_battlefield_custom_emitter", "heroes/hero_legion_commander/legion_commander_battlefield_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_battlefield_custom_emitter_aura", "heroes/hero_legion_commander/legion_commander_battlefield_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_battlefield_custom_arrow_thinker", "heroes/hero_legion_commander/legion_commander_battlefield_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_battlefield_custom_arrow_debuff", "heroes/hero_legion_commander/legion_commander_battlefield_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

legion_commander_battlefield_custom = class(ItemBaseClass)
modifier_legion_commander_battlefield_custom = class(legion_commander_battlefield_custom)
modifier_legion_commander_battlefield_custom_emitter = class(ItemBaseClass)
modifier_legion_commander_battlefield_custom_emitter_aura = class(ItemBaseAura)
modifier_legion_commander_battlefield_custom_arrow_thinker = class(ItemBaseClassBuff)
modifier_legion_commander_battlefield_custom_arrow_debuff = class(ItemBaseClassBuff)
-------------
function legion_commander_battlefield_custom:GetIntrinsicModifierName()
    return "modifier_legion_commander_battlefield_custom"
end

function legion_commander_battlefield_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function legion_commander_battlefield_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = caster:GetAbsOrigin()
    local ability = self

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNoDraw()
    emitter:AddNewModifier(caster, ability, "modifier_legion_commander_battlefield_custom_emitter", { 
        duration = duration
    })
    -- --

    caster:EmitSound("Hero_LegionCommander.Duel.Cast.Arcana")

    Timers:CreateTimer(duration, function()
        UTIL_RemoveImmediate(emitter)
    end)
end


function modifier_legion_commander_battlefield_custom:DeclareFunctions()
    local funcs = {}

    return funcs
end

function modifier_legion_commander_battlefield_custom:OnCreated()
    if not IsServer() then return end
end
----------------
function modifier_legion_commander_battlefield_custom_emitter:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()

    self.vfx = ParticleManager:CreateParticle("particles/econ/items/legion/legion_weapon_voth_domosh/legion_duel__2ring_arcana.vpcf", PATTACH_WORLDORIGIN, parent)

    ParticleManager:SetParticleControl(self.vfx, 0, parent:GetAbsOrigin())

    EmitSoundOn("Hero_LegionCommander.Duel.FP", self:GetParent())

    self:StartIntervalThink(FrameTime())

    self.ctx = CreateModifierThinker(
        caster,
        self:GetAbility(),
        "modifier_legion_commander_battlefield_custom_arrow_thinker",
        { duration = self:GetAbility():GetSpecialValueFor("duration") },
        parent:GetAbsOrigin(),
        caster:GetTeam(),
        false
    )
end

function modifier_legion_commander_battlefield_custom_emitter:OnIntervalThink(params)
    local legion = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if (Vector(parent:GetAbsOrigin().x+(75), parent:GetAbsOrigin().y, parent:GetAbsOrigin().z) - legion:GetAbsOrigin()):Length2D() > ability:GetSpecialValueFor("radius") then
        if parent:IsAlive() then
            UTIL_RemoveImmediate(parent)
        end
    end
end

function modifier_legion_commander_battlefield_custom_emitter:OnDestroy()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.vfx, true)
    ParticleManager:ReleaseParticleIndex(self.vfx)

    StopSoundOn("Hero_LegionCommander.Duel.FP", self:GetParent())

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end

    if self.ctx then
        UTIL_Remove(self.ctx)
    end
end

function modifier_legion_commander_battlefield_custom_emitter:CheckState()
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

function modifier_legion_commander_battlefield_custom_emitter:IsAura()
  return true
end

function modifier_legion_commander_battlefield_custom_emitter:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_legion_commander_battlefield_custom_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_legion_commander_battlefield_custom_emitter:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_legion_commander_battlefield_custom_emitter:GetModifierAura()
    return "modifier_legion_commander_battlefield_custom_emitter_aura"
end

function modifier_legion_commander_battlefield_custom_emitter:GetAuraEntityReject(ent) 
    return false
end
--------------
function modifier_legion_commander_battlefield_custom_emitter_aura:GetEffectName()
    return "particles/econ/items/legion/legion_overwhelming_odds_ti7/legion_commander_odds_ti7_buff.vpcf"
end

function modifier_legion_commander_battlefield_custom_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }

    return funcs
end

function modifier_legion_commander_battlefield_custom_emitter_aura:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    if not IsServer() then return end
end

function modifier_legion_commander_battlefield_custom_emitter_aura:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    self.armor = parent:GetPhysicalArmorValue(false) * (ability:GetSpecialValueFor("bonus_armor_pct")/100)
    self.damage = ((parent:GetBaseDamageMax()+parent:GetBaseDamageMin())/2) * (ability:GetSpecialValueFor("bonus_base_damage_pct")/100)

    self:InvokeBonus()
end

function modifier_legion_commander_battlefield_custom_emitter_aura:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_legion_commander_battlefield_custom_emitter_aura:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_legion_commander_battlefield_custom_emitter_aura:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
        damage = self.fDamage
    }
end

function modifier_legion_commander_battlefield_custom_emitter_aura:HandleCustomTransmitterData(data)
    if data.armor ~= nil and data.damage ~= nil then
        self.fArmor = tonumber(data.armor)
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_legion_commander_battlefield_custom_emitter_aura:InvokeBonus()
    if IsServer() == true then
        self.fArmor = self.armor
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
------------
function modifier_legion_commander_battlefield_custom_arrow_thinker:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("arrows_interval")

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_legion_commander_battlefield_custom_arrow_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    
    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_odds.vpcf", PATTACH_WORLDORIGIN, parent)

    local ability = self:GetAbility()
    
    local radius = ability:GetSpecialValueFor("radius")

    ParticleManager:SetParticleControl(self.vfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 1, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 3, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 4, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(self.vfx)

    EmitSoundOn("Hero_LegionCommander.Overwhelming.Cast", self:GetParent())
    EmitSoundOn("Hero_LegionCommander.Overwhelming.Location", self:GetParent())

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() or enemy:IsMagicImmune() then break end

        ApplyDamage({
            attacker = caster,
            victim = enemy,
            damage = caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("arrows_damage_from_attack")/100),
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = ability
        })

        enemy:AddNewModifier(caster, ability, "modifier_legion_commander_battlefield_custom_arrow_debuff", {
            duration = ability:GetSpecialValueFor("arrows_slow_duration")
        })

        EmitSoundOn("Hero_LegionCommander.Overwhelming.Creep", self:GetParent())
    end
end

function modifier_legion_commander_battlefield_custom_arrow_thinker:OnDestroy()
    if not IsServer() then return end

    UTIL_Remove(self:GetParent())
end
-----------
function modifier_legion_commander_battlefield_custom_arrow_debuff:IsDebuff() return true end

function modifier_legion_commander_battlefield_custom_arrow_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_legion_commander_battlefield_custom_arrow_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("arrows_slow")
end