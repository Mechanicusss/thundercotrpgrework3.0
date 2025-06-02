
modifier_aghanim_illusory_orb_thinker = class({})
-----------------------------------------------------------------------------

function modifier_aghanim_illusory_orb_thinker:OnCreated( kv )
    if IsServer() then
        self.rotation = 0
        EmitSoundOn("Hero_Puck.Illusory_Orb", self:GetParent())
        self:OnIntervalThink()
        self:StartIntervalThink(0.1)
    end
end

-----------------------------------------------------------------------------
function modifier_aghanim_illusory_orb_thinker:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    self.rotation = self.rotation + 15

    self:CreateOrb(caster, ability)
end
-----------------------------------------------------------------------------

function modifier_aghanim_illusory_orb_thinker:CreateOrb(caster, ability)
    local origin = caster:GetAbsOrigin()
    local point = RotatePosition(Vector(0,0,0), QAngle(0, self.rotation, 0), origin)
    local damage = ability:GetSpecialValueFor("orb_damage")
    local projectile_speed = ability:GetSpecialValueFor("orb_speed")
    local projectile_distance = ability:GetSpecialValueFor("max_distance")
    local projectile_radius = ability:GetSpecialValueFor("radius")
    local vision_radius = ability:GetSpecialValueFor("orb_vision")
    local vision_duration = ability:GetSpecialValueFor("vision_duration")

    local projectile_direction = point
    projectile_direction = Vector( projectile_direction.x, projectile_direction.y, 0 ):Normalized()
    local projectile_name = "particles/units/heroes/hero_puck/puck_illusory_orb.vpcf"

    -- create projectile
    local info = {
        Source = caster,
        Ability = ability,
        vSpawnOrigin = caster:GetOrigin(),
        
        bDeleteOnHit = false,
        
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        
        EffectName = projectile_name,
        fDistance = projectile_distance,
        fStartRadius = projectile_radius,
        fEndRadius = projectile_radius,
        vVelocity = ((projectile_direction):Normalized()) * projectile_speed,
    
        bReplaceExisting = false,
        
        bProvidesVision = true,
        iVisionRadius = vision_radius,
        iVisionTeamNumber = caster:GetTeamNumber(),
    }

    local projectile = ProjectileManager:CreateLinearProjectile(info)

    local extraData = {}
    extraData.damage = damage
    extraData.location = caster:GetOrigin()
    extraData.time = GameRules:GetGameTime()
    ability.projectiles[projectile] = extraData
end

