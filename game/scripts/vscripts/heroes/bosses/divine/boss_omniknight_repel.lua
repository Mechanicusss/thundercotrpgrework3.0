LinkLuaModifier("modifier_boss_omniknight_repel", "heroes/bosses/divine/boss_omniknight_repel", LUA_MODIFIER_MOTION_NONE)

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

boss_omniknight_repel = class(ItemBaseClass)
modifier_boss_omniknight_repel = class(boss_omniknight_repel)
-------------
function boss_omniknight_repel:GetIntrinsicModifierName()
    return "modifier_boss_omniknight_repel"
end

function boss_omniknight_repel:OnProjectileHit(hTarget, vLoc)
    if not IsServer() then return end

    if not hTarget then return end

    local caster = self:GetCaster()
    local ability = self

    ApplyDamage({
        victim = hTarget,
        attacker = caster,
        damage = ability:GetSpecialValueFor("damage"),
        ability = ability,
        damage_type = ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
    })

    EmitSoundOn("Hero_Omniknight.HammerOfPurity.Crit", hTarget)

    self:PlayEffects(hTarget)
    self:PlayEffects2(hTarget)
end

function boss_omniknight_repel:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_omniknight/omniknight_hammer_of_purity_detonation.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        3,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function boss_omniknight_repel:PlayEffects2(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_omniknight/omniknight_shard_hammer_of_purity_target.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
-------------
function modifier_boss_omniknight_repel:GetEffectName()
    return "particles/econ/items/omniknight/omni_ti8_head/omniknight_repel_buff_ti8.vpcf"
end

function modifier_boss_omniknight_repel:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_MODIFIER_ADDED,
    }
end

function modifier_boss_omniknight_repel:OnModifierAdded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()
    
    if parent ~= event.unit then return end 

    local buff = event.added_buff

    if not buff then return end 

    local caster = buff:GetCaster()

    if caster == parent then return end 

    if not buff:IsDebuff() then return end 

    if caster:GetTeam() ~= DOTA_TEAM_GOODGUYS then return end 

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    if parent:PassivesDisabled() then return end

    if (caster:GetAbsOrigin()-parent:GetAbsOrigin()):Length2D() > 1200 then return end

    EmitSoundOn("Hero_Omniknight.HammerOfPurity.Cast", parent)

    local info = 
    {
        Target = caster,
        Source = parent,
        Ability = ability,  
        EffectName = "particles/units/heroes/hero_omniknight/omniknight_hammer_of_purity_projectile.vpcf",
        iMoveSpeed = 1100,
        vSourceLoc = parent:GetAbsOrigin(),                -- Optional (HOW)
        bDrawsOnMinimap = false,                          -- Optional
        bDodgeable = false,                                -- Optional
        bIsAttack = false,                                -- Optional
        bVisibleToEnemies = true,                         -- Optional
        bReplaceExisting = false,                         -- Optional
        bProvidesVision = true,                           -- Optional
        iVisionRadius = 150,                              -- Optional
        iVisionTeamNumber = parent:GetTeamNumber()        -- Optional
    }

    ProjectileManager:CreateTrackingProjectile(info)

    ability:UseResources(false, false, false, true)

    buff:Destroy()
end

function modifier_boss_omniknight_repel:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local interval = ability:GetSpecialValueFor("purge_interval")

    self:StartIntervalThink(interval)
end

function modifier_boss_omniknight_repel:OnIntervalThink()
    local parent = self:GetParent()

    if parent:PassivesDisabled() then return end 
    
    parent:Purge(false, true, false, true, true)
end