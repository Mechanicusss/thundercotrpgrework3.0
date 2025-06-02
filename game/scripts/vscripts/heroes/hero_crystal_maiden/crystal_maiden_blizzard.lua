LinkLuaModifier("modifier_crystal_maiden_blizzard", "heroes/hero_crystal_maiden/crystal_maiden_blizzard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_blizzard_emitter", "heroes/hero_crystal_maiden/crystal_maiden_blizzard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_blizzard_emitter_aura", "heroes/hero_crystal_maiden/crystal_maiden_blizzard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_blizzard_emitter_aura_friendly", "heroes/hero_crystal_maiden/crystal_maiden_blizzard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_blizzard_emitter_frozen_debuff", "heroes/hero_crystal_maiden/crystal_maiden_blizzard", LUA_MODIFIER_MOTION_NONE)

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

crystal_maiden_blizzard = class(ItemBaseClass)
modifier_crystal_maiden_blizzard = class(crystal_maiden_blizzard)
modifier_crystal_maiden_blizzard_emitter = class(ItemBaseClass)
modifier_crystal_maiden_blizzard_emitter_aura = class(ItemBaseAura)
modifier_crystal_maiden_blizzard_emitter_frozen_debuff = class(ItemBaseClassDebuff)
modifier_crystal_maiden_blizzard_emitter_aura_friendly = class(ItemBaseAura)
-------------
function crystal_maiden_blizzard:GetIntrinsicModifierName()
    return "modifier_crystal_maiden_blizzard"
end

function crystal_maiden_blizzard:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function crystal_maiden_blizzard:OnSpellStart()
    if not IsServer() then return end
--
    local point = self:GetCursorPosition()
    local caster = self:GetCaster()
    local ability = self

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    -- Particle --
    local vfx = ParticleManager:CreateParticle("particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_snow_arcana1.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(vfx, 0, point)
    ParticleManager:SetParticleControl(vfx, 1, point)
    ParticleManager:SetParticleControl(vfx, 3, point)
    -- --

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNewModifier(caster, ability, "modifier_crystal_maiden_blizzard_emitter", { 
        duration = duration
    })
    -- --

    Timers:CreateTimer(duration, function()
        ParticleManager:DestroyParticle(vfx, true)
        ParticleManager:ReleaseParticleIndex(vfx)
        --emitter:Kill(nil, nil)
        UTIL_RemoveImmediate(emitter)
    end)
end
------------
function modifier_crystal_maiden_blizzard:DeclareFunctions()
    local funcs = {}

    return funcs
end

function modifier_crystal_maiden_blizzard:OnCreated()
    if not IsServer() then return end
end
----------------
function modifier_crystal_maiden_blizzard_emitter:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    self.interval = ability:GetSpecialValueFor("interval")
    self.damage = ability:GetSpecialValueFor("damage")
    self.intToDamage = ability:GetSpecialValueFor("int_to_damage")

    EmitSoundOn("Hero_Crystal.FreezingField.Arcana", parent)

    -- Start the thinker to drain hp/do damage --
    self:StartIntervalThink(self.interval)

    self.auraName = "modifier_crystal_maiden_blizzard_emitter_aura"
end

function modifier_crystal_maiden_blizzard_emitter:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    local units = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            ApplyDamage({
                victim = unit,
                attacker = caster,
                damage = (self.damage + (caster:GetBaseIntellect() * (self.intToDamage/100))) * self.interval,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            })
        end
    end

    -- Crystal Nova --
    if not caster:HasScepter() then return end

    local crystalNova = caster:FindAbilityByName("crystal_maiden_crystal_nova_custom")
    if not crystalNova or (crystalNova ~= nil and crystalNova:GetLevel() < 1) then return end 

    local parentPos = parent:GetAbsOrigin()
    local randomOffsetY = RandomInt(-self.radius, self.radius)
    local randomOffsetX = RandomInt(-self.radius, self.radius)
    local randomPos = Vector(parentPos.x+randomOffsetX, parentPos.y+randomOffsetY, parentPos.z)

    SpellCaster:Cast(crystalNova, randomPos, false)
end

function modifier_crystal_maiden_blizzard_emitter:OnDestroy()
    if not IsServer() then return end

    StopSoundOn("Hero_Crystal.FreezingField.Arcana", self:GetParent())

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end
end

function modifier_crystal_maiden_blizzard_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true
    }   

    return state
end

function modifier_crystal_maiden_blizzard_emitter:IsAura()
  return true
end

function modifier_crystal_maiden_blizzard_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_crystal_maiden_blizzard_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_crystal_maiden_blizzard_emitter:GetAuraRadius()
  return self.radius
end

function modifier_crystal_maiden_blizzard_emitter:GetModifierAura()
    return self.auraName
end

function modifier_crystal_maiden_blizzard_emitter:GetAuraEntityReject(ent) 
    if ent:GetUnitName() == "outpost_placeholder_unit" then return true end

    self.auraName = "modifier_crystal_maiden_blizzard_emitter_aura"

    return false
end
--------------
function modifier_crystal_maiden_blizzard_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE 
    }

    return funcs
end

function modifier_crystal_maiden_blizzard_emitter_aura:OnCreated()
    if not IsServer() then return end

    self.freezeLimit = self:GetAbility():GetSpecialValueFor("time_limit")
    self.freezeDuration = self:GetAbility():GetSpecialValueFor("freeze_duration")

    self:StartIntervalThink(self.freezeLimit)
end

function modifier_crystal_maiden_blizzard_emitter_aura:OnIntervalThink()
    local parent = self:GetParent()

    parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_crystal_maiden_blizzard_emitter_frozen_debuff", {
        duration = self.freezeDuration
    })
end

function modifier_crystal_maiden_blizzard_emitter_aura:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end

function modifier_crystal_maiden_blizzard_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_crystal_maiden_blizzard_emitter_aura:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end
-------
function modifier_crystal_maiden_blizzard_emitter_frozen_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DISABLE_HEALING,
    }

    return funcs
end

function modifier_crystal_maiden_blizzard_emitter_frozen_debuff:GetDisableHealing()
    return 1
end

function modifier_crystal_maiden_blizzard_emitter_frozen_debuff:OnCreated() 
    if not IsServer() then return end

    self.interval = self:GetAbility():GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(self.interval)
end

function modifier_crystal_maiden_blizzard_emitter_frozen_debuff:OnIntervalThink()
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self:GetParent():GetHealth() * (self:GetAbility():GetSpecialValueFor("hp_damage_pct")/100) * self.interval,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
    })
end
--------------
--
function modifier_crystal_maiden_blizzard_emitter_aura_friendly:IsDebuff()
    return false
end

function modifier_crystal_maiden_blizzard_emitter_aura_friendly:OnCreated()
    if not IsServer() then return end
    
    self.interval = self:GetAbility():GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(self.interval)
end

function modifier_crystal_maiden_blizzard_emitter_aura_friendly:OnIntervalThink()
    local unit = self:GetParent()

    local amount = unit:GetHealth() * (self:GetAbility():GetSpecialValueFor("ally_heal_pct")/100) * self.interval

    unit:Heal(amount, self:GetAbility())

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, amount, nil)
end