LinkLuaModifier("modifier_furion_sufferwood_sapling_custom", "heroes/hero_furion/furion_sufferwood_sapling_custom", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_furion_sufferwood_sapling_custom_thinker", "heroes/hero_furion/furion_sufferwood_sapling_custom", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_furion_sufferwood_sapling_custom_emitter", "heroes/hero_furion/furion_sufferwood_sapling_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_sufferwood_sapling_custom_emitter_aura", "heroes/hero_furion/furion_sufferwood_sapling_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furion_sufferwood_sapling_custom_debuff", "heroes/hero_furion/furion_sufferwood_sapling_custom", LUA_MODIFIER_MOTION_NONE)

local AbilityClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local AbilityClassDebuff = {
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
}

local AbilityClassDebuffStack = {
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
}

furion_sufferwood_sapling_custom = class(AbilityClass)
modifier_furion_sufferwood_sapling_custom = class(furion_sufferwood_sapling_custom)
modifier_furion_sufferwood_sapling_custom_thinker = class(AbilityClass)
modifier_furion_sufferwood_sapling_custom_emitter = class(AbilityClass)
modifier_furion_sufferwood_sapling_custom_emitter_aura = class(AbilityClassDebuffStack)
modifier_furion_sufferwood_sapling_custom_debuff = class(AbilityClassDebuffStack)

function modifier_furion_sufferwood_sapling_custom_thinker:IsStackable() return true end
function modifier_furion_sufferwood_sapling_custom_emitter:IsHidden() return true end

function furion_sufferwood_sapling_custom:GetIntrinsicModifierName()
  return "modifier_furion_sufferwood_sapling_custom"
end

function furion_sufferwood_sapling_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function furion_sufferwood_sapling_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local particle = ParticleManager:CreateParticle("particles/econ/items/natures_prophet/natures_prophet_weapon_sufferwood/furion_teleport_end_sufferwood.vpcf", PATTACH_POINT, caster)
    ParticleManager:SetParticleControl(particle, 0, point)
    ParticleManager:SetParticleControl(particle, 1, point)
    ParticleManager:ReleaseParticleIndex(particle)

    caster:AddNewModifier(caster, self, "modifier_furion_sufferwood_sapling_custom_thinker", {
        x = point.x,
        y = point.y,
        z = point.z
    })

    EmitSoundOnLocationWithCaster(point, "Hero_Furion.Teleport_Grow", caster)
end
--------------
function modifier_furion_sufferwood_sapling_custom_thinker:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_furion_sufferwood_sapling_custom_thinker:OnCreated(params)
    if not IsServer() then return end

    local ability = self:GetAbility()

    local delay = ability:GetSpecialValueFor("delay")

    self.point = Vector(params.x, params.y, params.z)

    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")

    self:StartIntervalThink(delay)
end

function modifier_furion_sufferwood_sapling_custom_thinker:OnIntervalThink()
    local caster = self:GetCaster()

    local emitter = CreateUnitByName("outpost_placeholder_unit", self.point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNewModifier(caster, self:GetAbility(), "modifier_furion_sufferwood_sapling_custom_emitter", { 
        duration = self.duration,
    })

    self:StartIntervalThink(-1)
    self:Destroy()
end
-----------
function modifier_furion_sufferwood_sapling_custom_emitter:OnCreated()
    if not IsServer() then return end

    local radius = self:GetAbility():GetSpecialValueFor("radius")

    self.particle = ParticleManager:CreateParticle("particles/econ/items/riki/riki_head_ti8/riki_smokebomb_ti8_crimson_2.vpcf", PATTACH_WORLDORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.particle, 1, Vector(radius, radius, radius))

    EmitSoundOn("Hero_Furion.Teleport_Appear", self:GetParent())
    EmitSoundOn("Hero_Venomancer.PoisonNova", self:GetParent())
end

function modifier_furion_sufferwood_sapling_custom_emitter:OnDestroy()
    if not IsServer() then return end

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, false)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end
end

function modifier_furion_sufferwood_sapling_custom_emitter:CheckState()
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

function modifier_furion_sufferwood_sapling_custom_emitter:IsAura()
  return true
end

function modifier_furion_sufferwood_sapling_custom_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_furion_sufferwood_sapling_custom_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_furion_sufferwood_sapling_custom_emitter:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_furion_sufferwood_sapling_custom_emitter:GetModifierAura()
    return "modifier_furion_sufferwood_sapling_custom_emitter_aura"
end

function modifier_furion_sufferwood_sapling_custom_emitter:GetAuraEntityReject(ent) 
    return false
end
----------
function modifier_furion_sufferwood_sapling_custom_emitter_aura:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.duration = ability:GetSpecialValueFor("duration")
    self.interval = ability:GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(self.interval)
end

function modifier_furion_sufferwood_sapling_custom_emitter_aura:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    local debuff = parent:FindModifierByName("modifier_furion_sufferwood_sapling_custom_debuff")
    if not debuff then
        parent:AddNewModifier(caster, self:GetAbility(), "modifier_furion_sufferwood_sapling_custom_debuff", {
            duration = self.duration
        })
        EmitSoundOn("Hero_Venomancer.PoisonNovaImpact", parent)
    end

    if debuff then
        if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end
        debuff:ForceRefresh()
    end
end

function modifier_furion_sufferwood_sapling_custom_emitter_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
-----------------
function modifier_furion_sufferwood_sapling_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_furion_sufferwood_sapling_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_furion_sufferwood_sapling_custom_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_furion_sufferwood_sapling_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_furion_sufferwood_sapling_custom_debuff:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    self.interval = ability:GetSpecialValueFor("interval")
    self.damage = ability:GetSpecialValueFor("damage")
    self.intToDamage = ability:GetSpecialValueFor("int_to_damage")

    self.damageTable = {
        attacker = caster,
        victim = parent,
        ability = ability,
        damage_type = ability:GetAbilityDamageType(),
    }

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_shard_sleep_debuff_c_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.vfx, 0, parent:GetAbsOrigin())

    self:OnIntervalThink()
    self:StartIntervalThink(self.interval)
end

function modifier_furion_sufferwood_sapling_custom_debuff:OnDestroy()
    if not IsServer() then return end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_furion_sufferwood_sapling_custom_debuff:OnIntervalThink()
    local damage = self.damage + (self:GetCaster():GetBaseIntellect() * (self.intToDamage/100)) * self.interval * self:GetStackCount()
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), damage, nil)
    self.damageTable.damage = damage
    ApplyDamage(self.damageTable)
end