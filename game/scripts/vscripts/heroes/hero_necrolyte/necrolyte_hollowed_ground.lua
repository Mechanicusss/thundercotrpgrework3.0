LinkLuaModifier("modifier_necrolyte_hollowed_ground", "heroes/hero_necrolyte/necrolyte_hollowed_ground", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_hollowed_ground_emitter", "heroes/hero_necrolyte/necrolyte_hollowed_ground", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_hollowed_ground_emitter_aura", "heroes/hero_necrolyte/necrolyte_hollowed_ground", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

necrolyte_hollowed_ground = class(ItemBaseClass)
modifier_necrolyte_hollowed_ground = class(necrolyte_hollowed_ground)
modifier_necrolyte_hollowed_ground_emitter = class(ItemBaseClassBuff)
modifier_necrolyte_hollowed_ground_emitter_aura = class(ItemBaseClassDebuff)
-------------
function necrolyte_hollowed_ground:GetIntrinsicModifierName()
    return "modifier_necrolyte_hollowed_ground"
end

function necrolyte_hollowed_ground:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function necrolyte_hollowed_ground:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local pos = self:GetCursorPosition()
    local duration = self:GetSpecialValueFor("duration")
    local ability = self

    caster:AddNewModifier(caster, ability, "modifier_necrolyte_hollowed_ground_emitter", { duration = duration })

    EmitSoundOn("Hero_Necrolyte.SpiritForm.Cast", caster)
end

function modifier_necrolyte_hollowed_ground_emitter:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    }

    return funcs
end

function modifier_necrolyte_hollowed_ground_emitter:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("regen_amp_pct")
end

function modifier_necrolyte_hollowed_ground_emitter:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")
    self.duration = ability:GetSpecialValueFor("duration")
    self.interval = ability:GetSpecialValueFor("interval")
    self.damage = ability:GetSpecialValueFor("damage")
    self.intToDamage = ability:GetSpecialValueFor("int_to_damage")

    self.vfx = ParticleManager:CreateParticle("particles/econ/items/necrolyte/necro_ti9_immortal/necro_ti9_immortal_shroud.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(self.vfx, 0, caster:GetAbsOrigin())

    -- Start the thinker to drain hp/do damage --
    self:StartIntervalThink(self.interval)
end

function modifier_necrolyte_hollowed_ground_emitter:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local units = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if unit:IsAlive() and not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            ApplyDamage({
                victim = unit,
                attacker = caster,
                damage = (self.damage + (caster:GetBaseIntellect() * (self.intToDamage/100))) * self.interval,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = ability
            })
        end
    end
end

function modifier_necrolyte_hollowed_ground_emitter:OnDestroy()
    if not IsServer() then return end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_necrolyte_hollowed_ground_emitter:IsAura()
  return true
end

function modifier_necrolyte_hollowed_ground_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_necrolyte_hollowed_ground_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_necrolyte_hollowed_ground_emitter:GetAuraRadius()
  return self.radius
end

function modifier_necrolyte_hollowed_ground_emitter:GetModifierAura()
    return "modifier_necrolyte_hollowed_ground_emitter_aura"
end

function modifier_necrolyte_hollowed_ground_emitter:GetAuraEntityReject(ent) 
    return false
end

function modifier_necrolyte_hollowed_ground_emitter_aura:GetStatusEffectName()
    return "particles/econ/items/necrolyte/necro_ti9_immortal/status_effect_necro_ti9_immortal_shroud.vpcf"
end
--------------
function modifier_necrolyte_hollowed_ground_emitter_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_necrolyte_hollowed_ground_emitter_aura:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self:PlayEffects(parent)
end

function modifier_necrolyte_hollowed_ground_emitter_aura:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.effect, false)
    ParticleManager:ReleaseParticleIndex(self.effect)
end

function modifier_necrolyte_hollowed_ground_emitter_aura:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_necrolyte/necrolyte_spirit_debuff.vpcf"

    -- Create Particle
    self.effect = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:SetParticleControl( self.effect, 0, target:GetOrigin() )
end

function modifier_necrolyte_hollowed_ground_emitter_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end