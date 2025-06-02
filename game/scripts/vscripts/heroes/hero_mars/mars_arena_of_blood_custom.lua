mars_arena_of_blood_custom = class({})
LinkLuaModifier( "modifier_generic_knockback_lua", "modifiers/modifier_generic_knockback_lua", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier( "modifier_mars_arena_of_blood_custom", "heroes/hero_mars/mars_arena_of_blood_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_mars_arena_of_blood_custom_blocker", "heroes/hero_mars/mars_arena_of_blood_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_mars_arena_of_blood_custom_thinker", "heroes/hero_mars/mars_arena_of_blood_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_mars_arena_of_blood_custom_wall_aura", "heroes/hero_mars/mars_arena_of_blood_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_mars_arena_of_blood_custom_wall_aura_allies", "heroes/hero_mars/mars_arena_of_blood_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_mars_arena_of_blood_custom_spear_aura", "heroes/hero_mars/mars_arena_of_blood_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_mars_arena_of_blood_custom_projectile_aura", "heroes/hero_mars/mars_arena_of_blood_custom", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_mars_arena_of_blood_custom_wall_aura_allies = class(ItemBaseClassBuff)
--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function mars_arena_of_blood_custom:GetAOERadius()
    return self:GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------
-- Ability Start
function mars_arena_of_blood_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- create thinker
    CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_mars_arena_of_blood_custom_thinker", -- modifier name
        {  }, -- kv
        point,
        caster:GetTeamNumber(),
        false
    )
end

--------------------------------------------------------------------------------
-- Projectile
mars_arena_of_blood_custom.projectiles = {}
function mars_arena_of_blood_custom:OnProjectileHitHandle( target, location, id )
    local data = self.projectiles[id]
    self.projectiles[id] = nil

    if data.destroyed then return end

    local attacker = EntIndexToHScript( data.entindex_source_const )
    attacker:PerformAttack( target, true, true, true, true, false, false, true )
end

modifier_mars_arena_of_blood_custom_blocker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_mars_arena_of_blood_custom_blocker:IsHidden()
    return true
end

function modifier_mars_arena_of_blood_custom_blocker:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_mars_arena_of_blood_custom_blocker:OnCreated( kv )
    if not IsServer() then return end

    if kv.model==1 then
        -- references
        self.fade_min = self:GetAbility():GetSpecialValueFor( "warrior_fade_min_dist" )
        self.fade_max = self:GetAbility():GetSpecialValueFor( "warrior_fade_max_dist" )
        self.fade_range = self.fade_max-self.fade_min
        self.caster = self:GetCaster()
        self.parent = self:GetParent()
        self.origin = self.parent:GetOrigin()

        -- replace model for even soldiers
        self:GetParent():SetOriginalModel( "models/heroes/mars/mars_soldier.vmdl" )
        self:GetParent():SetRenderAlpha( 0 )
        self:GetParent().model = 1

        -- Start interval
        self:StartIntervalThink( 0.1 )
    end
end

function modifier_mars_arena_of_blood_custom_blocker:OnRefresh( kv )
end

function modifier_mars_arena_of_blood_custom_blocker:OnRemoved()
end

function modifier_mars_arena_of_blood_custom_blocker:OnDestroy()
    if not IsServer() then return end
    self:GetParent():ForceKill( false )
    -- UTIL_Remove( self:GetParent() )
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_mars_arena_of_blood_custom_blocker:CheckState()
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
        [MODIFIER_STATE_NO_TEAM_SELECT] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
    }

    return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_mars_arena_of_blood_custom_blocker:OnIntervalThink()
    local alpha = 0

    -- find enemies
    local enemies = FindUnitsInRadius(
        self.caster:GetTeamNumber(),    -- int, your team number
        self.origin,    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.fade_max,  -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,    -- int, flag filter
        FIND_CLOSEST,   -- int, order filter
        false   -- bool, can grow cache
    )

    -- find out distance between closest enemy
    if #enemies>0 then
        local enemy = enemies[1]
        local range = math.max( self.parent:GetRangeToUnit( enemy ), self.fade_min )
        range = math.min( range, self.fade_max )-self.fade_min
        alpha = self:Interpolate( range/self.fade_range, 255, 0 )
    end

    -- set alpha based on distance
    self.parent:SetRenderAlpha( alpha )
end

function modifier_mars_arena_of_blood_custom_blocker:Interpolate( value, min, max )
    return value*(max-min) + min
end

modifier_mars_arena_of_blood_custom_projectile_aura = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_mars_arena_of_blood_custom_projectile_aura:IsHidden()
    return false
end

function modifier_mars_arena_of_blood_custom_projectile_aura:IsDebuff()
    return false
end

function modifier_mars_arena_of_blood_custom_projectile_aura:IsStunDebuff()
    return false
end

function modifier_mars_arena_of_blood_custom_projectile_aura:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_mars_arena_of_blood_custom_projectile_aura:OnCreated( kv )
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.width = self:GetAbility():GetSpecialValueFor( "width" )
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if not IsServer() then return end

    self.owner = kv.isProvidedByAura~=1
    if not self.owner then return end

    -- create filter using library
    self.filter = FilterManager:AddTrackingProjectileFilter( self.ProjectileFilter, self )

    self:StartIntervalThink( 0.03 )
end

function modifier_mars_arena_of_blood_custom_projectile_aura:OnRefresh( kv )
    
end

function modifier_mars_arena_of_blood_custom_projectile_aura:OnRemoved()
end

function modifier_mars_arena_of_blood_custom_projectile_aura:OnDestroy()
    if not IsServer() then return end

    if not self.owner then return end
    FilterManager:RemoveTrackingProjectileFilter( self.filter )
end

--------------------------------------------------------------------------------
-- Filter Effects
function modifier_mars_arena_of_blood_custom_projectile_aura:ProjectileFilter( data )
    -- get data
    local attacker = EntIndexToHScript( data.entindex_source_const )
    local target = EntIndexToHScript( data.entindex_target_const )
    local ability = EntIndexToHScript( data.entindex_ability_const )
    local isAttack = data.is_attack

    -- only block things that aren't from this ability
    if self.lock then return true end

    -- only block attacks
    if not data.is_attack then return true end

    -- only block enemies
    if attacker:GetTeamNumber()==self:GetCaster():GetTeamNumber() then return true end

    -- only block projectiles that either one of them is inside
    local mod1 = attacker:FindModifierByNameAndCaster( 'modifier_mars_arena_of_blood_custom_projectile_aura', self:GetCaster() )
    local mod2 = target:FindModifierByNameAndCaster( 'modifier_mars_arena_of_blood_custom_projectile_aura', self:GetCaster() )
    if (not mod1) and (not mod2) then return true end

    -- create projectile
    local info = {
        Target = target,
        Source = attacker,
        Ability = self.ability, 
        
        EffectName = attacker:GetRangedProjectileName(),
        iMoveSpeed = data.move_speed,
        bDodgeable = true,                           -- Optional
    
        vSourceLoc = attacker:GetAbsOrigin(),                -- Optional (HOW)
        bIsAttack = true,                                -- Optional

        ExtraData = data,
    }
    self.lock = true
    local id = ProjectileManager:CreateTrackingProjectile(info)
    self.lock = false
    self.ability.projectiles[id] = data

    return false
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_mars_arena_of_blood_custom_projectile_aura:OnIntervalThink()
    local origin = self:GetParent():GetOrigin()

    for id,_ in pairs(self.ability.projectiles) do
        -- get position
        local pos = ProjectileManager:GetTrackingProjectileLocation( id )

        -- check location
        local distance = (pos-origin):Length2D()

        -- check if position is within the ring
        if math.abs(distance-self.radius)<self.width then
            -- destroy
            self.ability.projectiles[id].destroyed = true
            ProjectileManager:DestroyTrackingProjectile( id )

            -- play effects
            self:PlayEffects( pos )
        end
    end
end

--------------------------------------------------------------------------------
-- Aura Effects
function modifier_mars_arena_of_blood_custom_projectile_aura:IsAura()
    return self.owner
end

function modifier_mars_arena_of_blood_custom_projectile_aura:GetModifierAura()
    return "modifier_mars_arena_of_blood_custom_projectile_aura"
end

function modifier_mars_arena_of_blood_custom_projectile_aura:GetAuraRadius()
    return self.radius
end

function modifier_mars_arena_of_blood_custom_projectile_aura:GetAuraDuration()
    return 0.3
end

function modifier_mars_arena_of_blood_custom_projectile_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_mars_arena_of_blood_custom_projectile_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_mars_arena_of_blood_custom_projectile_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_mars_arena_of_blood_custom_projectile_aura:GetAuraEntityReject( hEntity )
    if IsServer() then
        
    end

    return false
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_mars_arena_of_blood_custom_projectile_aura:PlayEffects( loc )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_mars/mars_arena_of_blood_impact.vpcf"
    local sound_cast = "Hero_Mars.Block_Projectile"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, loc )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOnLocationWithCaster( loc, sound_cast, self:GetCaster() )
end

modifier_mars_arena_of_blood_custom_spear_aura = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_mars_arena_of_blood_custom_spear_aura:IsHidden()
    return true
end

function modifier_mars_arena_of_blood_custom_spear_aura:IsDebuff()
    return true
end

function modifier_mars_arena_of_blood_custom_spear_aura:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_mars_arena_of_blood_custom_spear_aura:OnCreated( kv )
    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.width = self:GetAbility():GetSpecialValueFor( "spear_distance_from_wall" )
    self.duration = self:GetAbility():GetSpecialValueFor( "spear_attack_interval" )
    self.damage = self:GetAbility():GetSpecialValueFor( "spear_damage_curr_hp" )
    self.knockback_duration = 0.2

    self.parent = self:GetParent()
    self.spear_radius = self.radius-self.width

    if not IsServer() then return end
    self.owner = kv.isProvidedByAura~=1
    self.aura_origin = self:GetParent():GetOrigin()

    if not self.owner then
        self.aura_origin = Vector( kv.aura_origin_x, kv.aura_origin_y, 0 )
        local direction = self.aura_origin-self:GetParent():GetOrigin()
        direction.z = 0

        -- damage
        local damageTable = {
            victim = self:GetParent(),
            attacker = self:GetCaster(),
            damage = self:GetParent():GetHealth() * (self.damage/100),
            damage_type = self:GetAbility():GetAbilityDamageType(),
            damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
            ability = self:GetAbility(), --Optional.
        }
        ApplyDamage(damageTable)

        -- animate soldiers
        local arena_walls = Entities:FindAllByClassnameWithin( "npc_dota_phantomassassin_gravestone", self.parent:GetOrigin(), 160 )
        for _,arena_wall in pairs(arena_walls) do
            if arena_wall:HasModifier( "modifier_mars_arena_of_blood_custom_blocker" ) and arena_wall.model then
                arena_wall:FadeGesture( ACT_DOTA_ATTACK )
                arena_wall:StartGesture( ACT_DOTA_ATTACK )
                break
            end
        end

        -- play effects
        self:PlayEffects( direction:Normalized() )

        -- knockback if not having spear buff
        if self:GetParent():HasModifier( "modifier_mars_spear_of_mars_lua" ) then return end
        if self:GetParent():HasModifier( "modifier_mars_spear_of_mars_lua_debuff" ) then return end
        self:GetParent():AddNewModifier(
            self:GetCaster(), -- player source
            self:GetAbility(), -- ability source
            "modifier_generic_knockback_lua", -- modifier name
            {
                duration = self.knockback_duration,
                distance = self.width,
                height = 30,
                direction_x = direction.x,
                direction_y = direction.y,
            } -- kv
        )
    end
end

function modifier_mars_arena_of_blood_custom_spear_aura:OnRefresh( kv )
    
end

function modifier_mars_arena_of_blood_custom_spear_aura:OnRemoved()
end

function modifier_mars_arena_of_blood_custom_spear_aura:OnDestroy()
end

--------------------------------------------------------------------------------
-- Aura Effects
function modifier_mars_arena_of_blood_custom_spear_aura:IsAura()
    return self.owner
end

function modifier_mars_arena_of_blood_custom_spear_aura:GetModifierAura()
    return "modifier_mars_arena_of_blood_custom_spear_aura"
end

function modifier_mars_arena_of_blood_custom_spear_aura:GetAuraRadius()
    return self.radius
end

function modifier_mars_arena_of_blood_custom_spear_aura:GetAuraDuration()
    return self.duration
end

function modifier_mars_arena_of_blood_custom_spear_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_mars_arena_of_blood_custom_spear_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_mars_arena_of_blood_custom_spear_aura:GetAuraSearchFlags()
    return 0
end
function modifier_mars_arena_of_blood_custom_spear_aura:GetAuraEntityReject( unit )
    if not IsServer() then return end

    -- check flying
    if unit:HasFlyMovementCapability() then return true end

    -- check vertical motion controlled
    if unit:IsCurrentlyVerticalMotionControlled() then return true end

    -- check if already own this aura
    if unit:FindModifierByNameAndCaster( "modifier_mars_arena_of_blood_custom_spear_aura", self:GetCaster() ) then
        return true
    end

    -- check distance
    local distance = (unit:GetOrigin()-self.aura_origin):Length2D()
    if (distance-self.spear_radius)<0 then
        return true
    end

    return false
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_mars_arena_of_blood_custom_spear_aura:PlayEffects( direction )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_mars/mars_arena_of_blood_spear.vpcf"
    local sound_cast = "Hero_Mars.Phalanx.Attack"
    local sound_target = "Hero_Mars.Phalanx.Target"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetParent() )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
    EmitSoundOn( sound_target, self:GetParent() )
end

modifier_mars_arena_of_blood_custom_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_mars_arena_of_blood_custom_thinker:IsHidden()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_mars_arena_of_blood_custom_thinker:OnCreated( kv )
    -- references
    self.delay = self:GetAbility():GetSpecialValueFor( "formation_time" )
    self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

    if IsServer() then
        self.thinkers = {}

        -- Start interval
        self.phase_delay = true
        self:StartIntervalThink( self.delay )

        -- play effects
        self:PlayEffects()
    end
end

function modifier_mars_arena_of_blood_custom_thinker:OnRefresh( kv )
    
end

function modifier_mars_arena_of_blood_custom_thinker:OnRemoved()
    if not IsServer() then return end
    -- stop effects
    local sound_stop = "Hero_Mars.ArenaOfBlood.End"
    local sound_loop = "Hero_Mars.ArenaOfBlood"

    EmitSoundOn( sound_stop, self:GetParent() )
    StopSoundOn( sound_loop, self:GetParent() )
end

function modifier_mars_arena_of_blood_custom_thinker:OnDestroy()
    if not IsServer() then return end

    -- destroy modifiers (somehow it does not automatically calls OnDestroy on modifiers)
    local modifiers = {}
    for k,v in pairs(self:GetParent():FindAllModifiers()) do
        modifiers[k] = v
    end
    for k,v in pairs(modifiers) do
        v:Destroy()
    end

    UTIL_Remove( self:GetParent() ) 
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_mars_arena_of_blood_custom_thinker:OnIntervalThink()
    if self.phase_delay then
        self.phase_delay = false

        -- create vision
        AddFOWViewer( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), self.radius, self.duration, false)
        
        -- create wall aura
        self:GetParent():AddNewModifier(
            self:GetCaster(), -- player source
            self:GetAbility(), -- ability source
            "modifier_mars_arena_of_blood_custom_wall_aura", -- modifier name
            {  } -- kv
        )

        -- create spear aura
        self:GetParent():AddNewModifier(
            self:GetCaster(), -- player source
            self:GetAbility(), -- ability source
            "modifier_mars_arena_of_blood_custom_spear_aura", -- modifier name
            {  } -- kv
        )

        -- create spear aura
        self:GetParent():AddNewModifier(
            self:GetCaster(), -- player source
            self:GetAbility(), -- ability source
            "modifier_mars_arena_of_blood_custom_projectile_aura", -- modifier name
            {  } -- kv
        )

        if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
            self:GetParent():AddNewModifier(
                self:GetCaster(), -- player source
                self:GetAbility(), -- ability source
                "modifier_mars_arena_of_blood_custom_wall_aura_allies", -- modifier name
                {  } -- kv
            )
        end

        -- create phantom blockers
        self:SummonBlockers()

        -- play effects
        local sound_loop = "Hero_Mars.ArenaOfBlood"
        EmitSoundOn( sound_loop, self:GetParent() )

        -- add end duration
        self:StartIntervalThink( self.duration )
        self.phase_duration = true
        return
    end
    if self.phase_duration then
        self:Destroy()
        return
    end
end

function modifier_mars_arena_of_blood_custom_thinker:SummonBlockers()
    -- init data
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local teamnumber = caster:GetTeamNumber()
    local origin = self:GetParent():GetOrigin()
    local angle = 0
    local vector = origin + Vector(self.radius,0,0)
    local zero = Vector(0,0,0)
    local one = Vector(1,0,0)
    local count = 28

    local angle_diff = 360/count

    for i=0,count-1 do
        local location = RotatePosition( origin, QAngle( 0, angle_diff*i, 0 ), vector )
        local facing = RotatePosition( zero, QAngle( 0, 200+angle_diff*i, 0 ), one )

        -- callback after creation
        local callback = function( unit )
            unit:SetForwardVector( facing )
            unit:SetNeverMoveToClearSpace( true )

            -- add modifier
            unit:AddNewModifier(
                caster, -- player source
                self:GetAbility(), -- ability source
                "modifier_mars_arena_of_blood_custom_blocker", -- modifier name
                {
                    duration = self.duration,
                    model = i%2==0,
                } -- kv
            )
        end

        -- create unit async (to avoid high think time)
        local unit = CreateUnitByNameAsync(
            "aghsfort_mars_bulwark_soldier",
            location,
            false,
            caster,
            nil,
            caster:GetTeamNumber(),
            callback
        )
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_mars_arena_of_blood_custom_thinker:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_mars/mars_arena_of_blood.vpcf"
    local sound_cast = "Hero_Mars.ArenaOfBlood.Start"
    -- Hero_Mars.Block_Projectile

    -- Get data
    -- colloseum radius = radius + 50
    local radius = self.radius + 50

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetParent() )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, 0, 0 ) )
    ParticleManager:SetParticleControl( effect_cast, 2, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 3, self:GetParent():GetOrigin() )

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )

    -- Play sound
    EmitSoundOn( sound_cast, self:GetParent() )
end

modifier_mars_arena_of_blood_custom_wall_aura = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_mars_arena_of_blood_custom_wall_aura:IsHidden()
    return true
end

function modifier_mars_arena_of_blood_custom_wall_aura:IsDebuff()
    return true
end

function modifier_mars_arena_of_blood_custom_wall_aura:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_mars_arena_of_blood_custom_wall_aura:OnCreated( kv )
    if not IsServer() then return end
    -- references
    -- normal limit inner ring = radius - 200
    -- zero limit inner ring = radius - 100
    -- zero limit outer ring = radius + 100
    -- normal limit outer ring = radius + 200

    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.width = self:GetAbility():GetSpecialValueFor( "width" )
    self.parent = self:GetParent()

    self.twice_width = self.width*2
    self.aura_radius = self.radius + self.twice_width
    self.MAX_SPEED = 550
    self.MIN_SPEED = 1

    self.owner = kv.isProvidedByAura~=1

    if not self.owner then
        self.aura_origin = Vector( kv.aura_origin_x, kv.aura_origin_y, 0 )
    else
        self.aura_origin = self:GetParent():GetOrigin()
    end
end

function modifier_mars_arena_of_blood_custom_wall_aura:OnRefresh( kv )
end

function modifier_mars_arena_of_blood_custom_wall_aura:OnRemoved()
end

function modifier_mars_arena_of_blood_custom_wall_aura:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_mars_arena_of_blood_custom_wall_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }

    return funcs
end

function modifier_mars_arena_of_blood_custom_wall_aura:GetModifierMoveSpeed_Limit( params )
    if not IsServer() then return end
    -- do nothing if owner
    if self.owner then return 0 end

    -- get data
    local parent_vector = self.parent:GetOrigin()-self.aura_origin
    local parent_direction = parent_vector:Normalized()

    -- calculate distance
    local actual_distance = parent_vector:Length2D()
    local wall_distance = actual_distance-self.radius
    local isInside = (wall_distance)<0
    wall_distance = math.min( math.abs( wall_distance ), self.twice_width )
    wall_distance = math.max( wall_distance, self.width ) - self.width -- clamped between 0 and width

    -- calculate facing angle
    local parent_angle = 0
    if isInside then
        parent_angle = VectorToAngles(parent_direction).y
    else
        parent_angle = VectorToAngles(-parent_direction).y
    end
    local unit_angle = self:GetParent():GetAnglesAsVector().y
    local wall_angle = math.abs( AngleDiff( parent_angle, unit_angle ) )

    -- calculate movespeed limit
    local limit = 0
    if wall_angle>90 then
        -- no limit if facing away
        limit = 0
    else
        -- interpolate between max
        limit = self:Interpolate( wall_distance/self.width, self.MIN_SPEED, self.MAX_SPEED )
    end

    return limit
end

--------------------------------------------------------------------------------
-- Helper
function modifier_mars_arena_of_blood_custom_wall_aura:Interpolate( value, min, max )
    return value*(max-min) + min
end

--------------------------------------------------------------------------------
-- Aura Effects
function modifier_mars_arena_of_blood_custom_wall_aura:IsAura()
    return self.owner
end

function modifier_mars_arena_of_blood_custom_wall_aura:GetModifierAura()
    return "modifier_mars_arena_of_blood_custom_wall_aura"
end

function modifier_mars_arena_of_blood_custom_wall_aura:GetAuraRadius()
    return self.aura_radius
end

function modifier_mars_arena_of_blood_custom_wall_aura:GetAuraDuration()
    return 0.3
end

function modifier_mars_arena_of_blood_custom_wall_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_mars_arena_of_blood_custom_wall_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_mars_arena_of_blood_custom_wall_aura:GetAuraSearchFlags()
    return 0
end

function modifier_mars_arena_of_blood_custom_wall_aura:GetAuraEntityReject( unit )
    if not IsServer() then return end

    -- check flying
    if unit:HasFlyMovementCapability() then return true end

    return false
end
------------
function modifier_mars_arena_of_blood_custom_wall_aura_allies:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_MIN_HEALTH,
        MODIFIER_PROPERTY_HEALTH_BONUS
    }
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("friendly_aura_max_hp_regen_pct")
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetMinHealth()
    if self:GetCaster():HasScepter() then
        return 1
    end
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:IsAura()
    return self.owner
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetModifierAura()
    return "modifier_mars_arena_of_blood_custom_wall_aura_allies"
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetAuraRadius()
    return self.radius
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetAuraDuration()
    return 0.3
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetAuraEntityReject( hEntity )
    return self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber()
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:OnCreated( kv )
    self:SetHasCustomTransmitterData(true)
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if not IsServer() then return end

    self.owner = kv.isProvidedByAura~=1

    self.armor = self.parent:GetPhysicalArmorValue(false) * (self.ability:GetSpecialValueFor("friendly_aura_armor_bonus_pct")/100)
    self.health = self.parent:GetMaxHealth() * (self.ability:GetSpecialValueFor("friendly_aura_max_hp_bonus_pct")/100)

    self:InvokeBonus()
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
        health = self.fHealth,
    }
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:HandleCustomTransmitterData(data)
    if data.armor ~= nil and data.health ~= nil then
        self.fArmor = tonumber(data.armor)
        self.fHealth = tonumber(data.health)
    end
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:InvokeBonus()
    if IsServer() == true then
        self.fArmor = self.armor
        self.fHealth = self.health

        self:SendBuffRefreshToClients()
    end
end

function modifier_mars_arena_of_blood_custom_wall_aura_allies:GetModifierHealthBonus()
    return self.fHealth
end