LinkLuaModifier("modifier_laguna_blade_scepter_custom", "heroes/hero_lina/laguna_blade_scepter", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

laguna_blade_scepter_custom = class(ItemBaseClass)
modifier_laguna_blade_scepter_custom = class(laguna_blade_scepter_custom)
-------------
function laguna_blade_scepter_custom:GetIntrinsicModifierName()
    return "modifier_laguna_blade_scepter_custom"
end

function modifier_laguna_blade_scepter_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_laguna_blade_scepter_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_laguna_blade_scepter_custom:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local victim = event.target

    if unit ~= parent then
        return
    end

    print("boop")

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL or event.inflictor ~= nil or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end
    
    local chance = ability:GetLevelSpecialValueFor("chance", (ability:GetLevel() - 1))

    if not RollPercentage(chance) then
        return
    end

    self:CastRandomAbility(unit, victim)
end

function modifier_laguna_blade_scepter_custom:CastRandomAbility(caster, target)
    local dragonSlave = unit:FindAbilityByName("lina_dragon_slave")
    local lightStrikeArray = unit:FindAbilityByName("lina_light_strike_array")
    local lagunaBlade = unit:FindAbilityByName("lina_laguna_blade")

    local random = RandomInt(1, 3)
    if random == 1 and dragonSlave ~= nil and dragonSlave:GetLevel() > 0 then
        caster:CastAbilityOnPosition(target:GetAbsOrigin(), dragonSlave, 1)
    elseif random == 2 and lightStrikeArray ~= nil and lightStrikeArray:GetLevel() > 0 then
        caster:CastAbilityOnPosition(target:GetAbsOrigin(), lightStrikeArray, 1)
    elseif random == 3 and lagunaBlade ~= nil and lagunaBlade:GetLevel() > 0 then
        caster:CastAbilityOnTarget(target, lagunaBlade, 1)
    else
        self:CastRandomAbility(caster, target)
    end
end

function modifier_laguna_blade_scepter_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_faceless_void/laguna_blade_scepter_bash.vpcf"
    local sound_cast = "Hero_FacelessVoid.TimeLockImpact"

    -- Get Data
    local forward = (target:GetOrigin()-self.parent:GetOrigin()):Normalized()

    -- Create Particle
    local particle = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, target )
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin() )
    ParticleManager:SetParticleControlEnt(particle, 2, self.parent, PATTACH_CUSTOMORIGIN, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end