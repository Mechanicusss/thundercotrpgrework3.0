LinkLuaModifier("modifier_boss_spectre_desolate", "heroes/bosses/spectre/desolate", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_spectre_desolate = class(ItemBaseClass)
modifier_boss_spectre_desolate = class(boss_spectre_desolate)
-------------
function boss_spectre_desolate:GetIntrinsicModifierName()
    return "modifier_boss_spectre_desolate"
end


function modifier_boss_spectre_desolate:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_boss_spectre_desolate:OnCreated()
    self.parent = self:GetParent()
end

function modifier_boss_spectre_desolate:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL or event.inflictor ~= nil or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or caster:PassivesDisabled() or not caster:IsAlive() then
        return
    end

    local ability = self:GetAbility()
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
    local damage = ability:GetLevelSpecialValueFor("bonus_damage", (ability:GetLevel() - 1))
    local damagePct = ability:GetLevelSpecialValueFor("bonus_damage_pct", (ability:GetLevel() - 1))

    local victims = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            if not victim:IsAlive() then break end

            ApplyDamage({
                victim = victim, 
                attacker = caster, 
                damage = damage + (event.damage * (damagePct / 100)), 
                damage_type = DAMAGE_TYPE_PURE
            })

            self:PlayEffects(victim)
        end
end

function modifier_boss_spectre_desolate:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/spectre/spectre_arcana/spectre_arcana_desolate.vpcf"
    local sound_cast = "Hero_Spectre.Desolate"

    -- Get Data
    local forward = (target:GetOrigin()-self.parent:GetOrigin()):Normalized()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 4, target:GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 0, forward )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end