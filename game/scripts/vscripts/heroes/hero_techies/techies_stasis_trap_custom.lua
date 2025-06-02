LinkLuaModifier("modifier_techies_stasis_trap_custom", "heroes/hero_techies/techies_stasis_trap_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_stasis_trap_custom_thinker", "heroes/hero_techies/techies_stasis_trap_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_stasis_trap_custom_debuff", "heroes/hero_techies/techies_stasis_trap_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassThinker = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

techies_stasis_trap_custom = class(ItemBaseClass)
modifier_techies_stasis_trap_custom = class(techies_stasis_trap_custom)
modifier_techies_stasis_trap_custom_thinker = class(ItemBaseClassThinker)
modifier_techies_stasis_trap_custom_debuff = class(ItemBaseClassDebuff)
-------------
function techies_stasis_trap_custom:GetIntrinsicModifierName()
    return "modifier_techies_stasis_trap_custom"
end

function techies_stasis_trap_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function techies_stasis_trap_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    CreateUnitByNameAsync(
        "npc_dota_techies_stasis_trap_custom",
        point,
        true,
        caster,
        caster,
        caster:GetTeamNumber(),

        function(unit)
            EmitSoundOn("Hero_Techies.StasisTrap.Plant", unit)

            unit:AddNewModifier(unit, self, "modifier_techies_stasis_trap_custom_thinker", {
                duration = self:GetSpecialValueFor("duration")+0.5
            })
        end
    )
end

----
--
function modifier_techies_stasis_trap_custom_thinker:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
    }

    return funcs
end

function modifier_techies_stasis_trap_custom_thinker:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true
    }
end

function modifier_techies_stasis_trap_custom_thinker:OnCreated()
    if not IsServer() then return end

    local unit = self:GetParent()

    self.radius = self:GetAbility():GetSpecialValueFor("radius")

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_tazer.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControl(self.particle, 0, unit:GetOrigin())
    ParticleManager:SetParticleControl(self.particle, 1, unit:GetOrigin())

    self:OnIntervalThink()
    self:StartIntervalThink(1)
end

function modifier_techies_stasis_trap_custom_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local owner = parent:GetOwner()

    local enemies = FindUnitsInRadius(
        owner:GetTeamNumber(),   -- int, your team number
        parent:GetOrigin(),   -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        ApplyDamage({
            victim = enemy,
            attacker = owner,
            damage = self:GetAbility():GetSpecialValueFor("damage") + (owner:GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100)),
            damage_type = self:GetAbility():GetAbilityDamageType(),
            ability = self:GetAbility()
        })

        local debuff = enemy:AddNewModifier(owner, self:GetAbility(), "modifier_techies_stasis_trap_custom_debuff", {
            duration = 1
        })

        if debuff ~= nil then
            debuff:ForceRefresh()
        end
    end

    self:PlayEffects(parent)
end

function modifier_techies_stasis_trap_custom_thinker:OnDeath(event)
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
end

function modifier_techies_stasis_trap_custom_thinker:OnRemoved(event)
    if not IsServer() then return end

    UTIL_RemoveImmediate(self:GetParent())
end

function modifier_techies_stasis_trap_custom_thinker:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_techies/techies_tazer_explode.vpcf"
    local sound_cast = "Hero_Techies.ReactiveTazer.Detonate"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:SetParticleControl(effect_cast, 0, target:GetOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, Vector(self.radius, self.radius, self.radius))
    ParticleManager:SetParticleControl(effect_cast, 10, target:GetOrigin())
    ParticleManager:SetParticleControl(effect_cast, 11, target:GetOrigin())
    ParticleManager:SetParticleControl(effect_cast, 12, target:GetOrigin())
    ParticleManager:SetParticleControl(effect_cast, 13, target:GetOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end
---
--
function modifier_techies_stasis_trap_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE, --GetModifierAttackSpeedPercentage
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, --GetModifierDamageOutgoing_Percentage
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
    }

    return funcs
end

function modifier_techies_stasis_trap_custom_debuff:OnCreated()
    if not IsServer() then return end

    local target = self:GetParent()

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_techies/techies_tazer_target.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:SetParticleControl(self.effect_cast, 0, target:GetOrigin())
    ParticleManager:SetParticleControl(self.effect_cast, 1, target:GetOrigin())
end

function modifier_techies_stasis_trap_custom_debuff:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.effect_cast, true)
    ParticleManager:ReleaseParticleIndex(self.effect_cast)
end

function modifier_techies_stasis_trap_custom_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_techies_stasis_trap_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_techies_stasis_trap_custom_debuff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("outgoing_damage")
end

function modifier_techies_stasis_trap_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res")
end