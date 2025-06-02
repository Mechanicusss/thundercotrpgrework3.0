LinkLuaModifier("modifier_grimstroke_dark_artistry_custom", "heroes/hero_grimstroke/grimstroke_dark_artistry_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_dark_artistry_custom_shard", "heroes/hero_grimstroke/grimstroke_dark_artistry_custom", LUA_MODIFIER_MOTION_NONE)

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

grimstroke_dark_artistry_custom = class(ItemBaseClass)
modifier_grimstroke_dark_artistry_custom = class(grimstroke_dark_artistry_custom)
modifier_grimstroke_dark_artistry_custom_shard = class(ItemBaseClassBuff)

_G.grimstroke_dark_artistry_custom_projectiles = {}
-------------
function grimstroke_dark_artistry_custom:GetIntrinsicModifierName()
    return "modifier_grimstroke_dark_artistry_custom"
end

function grimstroke_dark_artistry_custom:GetBehavior()
    local caster = self:GetCaster()

    if caster:HasModifier("modifier_item_aghanims_shard") then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
    else
        return DOTA_ABILITY_BEHAVIOR_PASSIVE 
    end
end

function grimstroke_dark_artistry_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_grimstroke_dark_artistry_custom_shard", {
        duration = self:GetSpecialValueFor("shard_duration")
    })
end

function grimstroke_dark_artistry_custom:GetCooldown()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then return self:GetSpecialValueFor("shard_cooldown") end

    return self.BaseClass.GetCooldown(self, -1) or 0
end

function grimstroke_dark_artistry_custom:GetManaCost(level)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_item_aghanims_shard") then return 0 end

    return self:GetCaster():GetMaxMana() * (self:GetSpecialValueFor("mana_cost_pct")/100)
end

function grimstroke_dark_artistry_custom:OnProjectileHitHandle( target, location, handle )
    if not target then
        -- unregister projectile
        _G.grimstroke_dark_artistry_custom_projectiles[handle] = nil

        -- create Vision
        local vision_radius = (self:GetSpecialValueFor( "start_radius" )+self:GetSpecialValueFor( "end_radius" ))/2
        local vision_duration = self:GetSpecialValueFor( "vision_duration" )
        AddFOWViewer( self:GetCaster():GetTeamNumber(), location, vision_radius, vision_duration, false )

        return
    end

    -- get data
    local data = _G.grimstroke_dark_artistry_custom_projectiles[handle]
    local numTargets = data.targets

    local increasePerTarget = self:GetSpecialValueFor("bonus_damage_per_target_pct")
    local bonusDamage = (increasePerTarget*numTargets)

    local damage = data.damage * (1+(bonusDamage/100))

    -- damage
    local damageTable = {
        victim = target,
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }
    ApplyDamage(damageTable)

    -- reduce damage
    data.damage = damage

    -- Play effects
    local sound_cast = "Hero_Grimstroke.DarkArtistry.Damage"
    EmitSoundOn( sound_cast, target )

    local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_grimstroke/grimstroke_darkartistry_dmg.vpcf", PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(vfx, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(vfx, 3, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfx)

    _G.grimstroke_dark_artistry_custom_projectiles[handle].targets = _G.grimstroke_dark_artistry_custom_projectiles[handle].targets + 1
end
----------
function modifier_grimstroke_dark_artistry_custom:OnCreated()
    if not IsServer() then return end

    self.proc = false
end

function modifier_grimstroke_dark_artistry_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_START 
    }
end

function modifier_grimstroke_dark_artistry_custom:OnAttackStart(event)
    if not IsServer() then return end

    local caster = self:GetParent()

    if event.attacker ~= caster then return end
    if event.target == caster then return end

    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")

    if caster:HasModifier("modifier_grimstroke_dark_artistry_custom_shard") then
        chance = 100
    end

    if not RollPercentage(chance) or caster:GetMana() < ability:GetManaCost(-1) then return end

    self.proc = true

    caster:StartGesture(ACT_DOTA_CAST_ABILITY_3)
end

function modifier_grimstroke_dark_artistry_custom:OnAttack(event)
    if not IsServer() then return end

    local caster = self:GetParent()

    if event.attacker ~= caster then return end
    if event.target == caster then return end

    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")

    if not self.proc then caster:RemoveGesture(ACT_DOTA_CAST_ABILITY_3) return end

    EmitSoundOn("Hero_Grimstroke.DarkArtistry.PreCastPoint", caster)

    -- load data
    local damage = caster:GetMaxMana() * (ability:GetSpecialValueFor( "mana_cost_pct" )/100)
    local vision_radius = (ability:GetSpecialValueFor( "start_radius" )+ability:GetSpecialValueFor( "end_radius" ))/2
    
    local projectile_name = "particles/units/heroes/hero_grimstroke/grimstroke_darkartistry_proj.vpcf"
    local projectile_speed = ability:GetSpecialValueFor( "projectile_speed" )
    local projectile_distance =  caster:Script_GetAttackRange()
    local projectile_start_radius = ability:GetSpecialValueFor( "start_radius" )
    local projectile_end_radius = ability:GetSpecialValueFor( "end_radius" )
    local projectile_direction = (event.target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
    
    local projectile_start_position = caster:GetAbsOrigin()
    projectile_start_position = projectile_start_position + projectile_direction * ((projectile_start_radius+projectile_end_radius)/2)

    local iParticleCastID = ParticleManager:CreateParticle("particles/units/heroes/hero_grimstroke/grimstroke_cast_generic.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:ReleaseParticleIndex(iParticleCastID)

    local iParticleID = ParticleManager:CreateParticle("particles/units/heroes/hero_grimstroke/grimstroke_darkartistry_proj.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControlEnt(iParticleID, 0, caster, PATTACH_CUSTOMORIGIN, nil, caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(iParticleID, 0, projectile_start_position)
    ParticleManager:SetParticleControl(iParticleID, 1, projectile_direction * projectile_speed)
    ParticleManager:SetParticleControl(iParticleID, 5, projectile_start_position + projectile_direction * projectile_distance)

    -- create projectile
    local info = {
        Source = caster,
        Ability = ability,
        vSpawnOrigin = caster:GetAbsOrigin(),
        
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        
        EffectName = "particles/units/heroes/hero_grimstroke/grimstroke_darkartistry_proj.vpcf",
        fDistance = projectile_distance,
        fStartRadius = projectile_start_radius,
        fEndRadius = projectile_end_radius,
        vVelocity = projectile_direction * projectile_speed,
    
        bProvidesVision = true,
        iVisionRadius = vision_radius,
        iVisionTeamNumber = caster:GetTeamNumber(),
    }

    local projectile = ProjectileManager:CreateLinearProjectile(info)

    -- register projectile data
    _G.grimstroke_dark_artistry_custom_projectiles[projectile] = {}
    _G.grimstroke_dark_artistry_custom_projectiles[projectile].targets = 0
    _G.grimstroke_dark_artistry_custom_projectiles[projectile].damage = damage

    EmitSoundOn("Hero_Grimstroke.DarkArtistry.Cast", caster)
    EmitSoundOn("Hero_Grimstroke.DarkArtistry.Projectile", caster)

    ability:UseResources(true, false, false, false)
    self.proc = false
end