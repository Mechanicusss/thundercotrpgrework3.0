LinkLuaModifier("modifier_omniknight_hammer_of_purity_custom", "heroes/hero_omniknight/omniknight_hammer_of_purity_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_omniknight_hammer_of_purity_custom_debuff", "heroes/hero_omniknight/omniknight_hammer_of_purity_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_omniknight_hammer_of_purity_custom_thinker", "heroes/hero_omniknight/omniknight_hammer_of_purity_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAbsorb = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassCasting = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

omniknight_hammer_of_purity_custom = class(ItemBaseClass)
modifier_omniknight_hammer_of_purity_custom = class(omniknight_hammer_of_purity_custom)
modifier_omniknight_hammer_of_purity_custom_debuff = class(ItemBaseClassAbsorb)
modifier_omniknight_hammer_of_purity_custom_thinker = class(ItemBaseClassCasting)
-------------
function omniknight_hammer_of_purity_custom:GetIntrinsicModifierName()
    return "modifier_omniknight_hammer_of_purity_custom"
end

function omniknight_hammer_of_purity_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function omniknight_hammer_of_purity_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    
    caster:AddNewModifier(caster, ability, "modifier_omniknight_hammer_of_purity_custom_thinker", { duration = self:GetChannelTime() })
end

function omniknight_hammer_of_purity_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_omniknight_hammer_of_purity_custom_thinker")
end

function omniknight_hammer_of_purity_custom:OnProjectileHit(hTarget, vLoc)
    if not IsServer() then return end

    if not hTarget then return end

    local caster = self:GetCaster()
    local ability = self

    local debuff = hTarget:FindModifierByName("modifier_omniknight_hammer_of_purity_custom_debuff")
    if not debuff then
        debuff = hTarget:AddNewModifier(caster, ability, "modifier_omniknight_hammer_of_purity_custom_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if debuff then
        local maxStacks = ability:GetSpecialValueFor("max_stacks")
        if debuff:GetStackCount() < maxStacks then
            debuff:IncrementStackCount()
        end
        debuff:ForceRefresh()
    end

    ApplyDamage({
        victim = hTarget,
        attacker = caster,
        damage = (caster:GetAverageTrueAttackDamage(caster)*(ability:GetSpecialValueFor("base_damage")/100)),
        ability = ability,
        damage_type = ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
    })

    EmitSoundOn("Hero_Omniknight.HammerOfPurity.Crit", hTarget)

    self:PlayEffects(hTarget)
    self:PlayEffects2(hTarget)
end

function omniknight_hammer_of_purity_custom:PlayEffects(target)
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

function omniknight_hammer_of_purity_custom:PlayEffects2(target)
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
------------
function modifier_omniknight_hammer_of_purity_custom_thinker:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")

    local interval = ability:GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_omniknight_hammer_of_purity_custom_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:StartGesture(ACT_DOTA_CAST_ABILITY_1)

    local radius = ability:GetSpecialValueFor("radius")

    local targets = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    if #targets < 1 then return end

    local target = nil 

    for _,t in ipairs(targets) do
        if t:IsAlive() and not t:IsMagicImmune() and not t:IsInvulnerable() then
            target = t
            break
        end
    end

    if not target or target == nil then self:Destroy() end
    if not target:IsAlive() then self:Destroy() end

    parent:FaceTowards(target:GetAbsOrigin())

    EmitSoundOn("Hero_Omniknight.HammerOfPurity.Cast", target)

    local info = 
    {
        Target = target,
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
end
------------
function modifier_omniknight_hammer_of_purity_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_omniknight/omniknight_shard_hammer_of_purity_overhead_debuff.vpcf"
end

function modifier_omniknight_hammer_of_purity_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_omniknight_hammer_of_purity_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, --GetModifierTotalDamageOutgoing_Percentage
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, --GetModifierIncomingDamage_Percentage
    }
end

function modifier_omniknight_hammer_of_purity_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movement_slow")*self:GetStackCount()
end

function modifier_omniknight_hammer_of_purity_custom_debuff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_penalty")*self:GetStackCount()
end

function modifier_omniknight_hammer_of_purity_custom_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("ally_damage_boost")*self:GetStackCount()
end

function modifier_omniknight_hammer_of_purity_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end