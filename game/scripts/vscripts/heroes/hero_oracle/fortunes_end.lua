LinkLuaModifier("modifier_oracle_fortunes_end_custom", "heroes/hero_oracle/fortunes_end", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

oracle_fortunes_end_custom = class(ItemBaseClass)
modifier_oracle_fortunes_end_custom = class(oracle_fortunes_end_custom)
-------------
function oracle_fortunes_end_custom:GetIntrinsicModifierName()
    return "modifier_oracle_fortunes_end_custom"
end

function oracle_fortunes_end_custom:OnProjectileHit_ExtraData( target, location, extraData )
    -- Find enemies --
    local enemies = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(), -- int, your team number
        target:GetAbsOrigin(), -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        300, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        bit.bor(DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_BASIC,DOTA_UNIT_TARGET_CREEP),  -- int, type filter
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, -- int, flag filter
        FIND_CLOSEST,   -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in ipairs(enemies) do
        local damage = {
            victim = enemy,
            attacker = self:GetCaster(),
            damage = extraData.damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            damage_flags = DOTA_DAMAGE_FLAG_FORCE_SPELL_AMPLIFICATION,
            ability = self
        }
        ApplyDamage(damage)
    end

    -- effects
    self:PlayEffects1(target)
    self:PlayEffects2(target)
end

function oracle_fortunes_end_custom:PlayEffects1(target)
    local particle_cast = "particles/units/heroes/hero_oracle/oracle_fortune_cast_tgt.vpcf"
    local sound_cast = "Hero_Oracle.FortunesEnd.Target"

    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(effect_cast, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)

    EmitSoundOn(sound_cast, target)
end

function oracle_fortunes_end_custom:PlayEffects2(target)
    local particle_cast = "particles/units/heroes/hero_oracle/oracle_fortune_aoe.vpcf"

    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(effect_cast, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 2, Vector(300, 0, 0))
    ParticleManager:ReleaseParticleIndex(effect_cast)
end

function modifier_oracle_fortunes_end_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }
    return funcs
end

function modifier_oracle_fortunes_end_custom:OnCreated()
end

function modifier_oracle_fortunes_end_custom:OnAttack(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if event.attacker:IsIllusion() then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    local damage = ability:GetSpecialValueFor("damage")
    local intScaling = ability:GetSpecialValueFor("int_to_damage_pct")
    local dmgScaling = ability:GetSpecialValueFor("attack_to_damage_pct")
    local projectile_name = "particles/units/heroes/hero_oracle/oracle_fortune_prj.vpcf"
    local projectile_speed = 1000

    local info = {
        Source = unit,
        Target = victim,
        Ability = ability,
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bIsAttack = true,
        bDodgeable = true,
        ExtraData = {
            damage = damage + (unit:GetAverageTrueAttackDamage(unit) * (dmgScaling/100)) + (unit:GetBaseIntellect() * (intScaling/100)),
        }
    }

    ProjectileManager:CreateTrackingProjectile(info)

    EmitSoundOn("Hero_Oracle.FortunesEnd.Attack", unit)

    ability:UseResources(false, false, false, true)
end