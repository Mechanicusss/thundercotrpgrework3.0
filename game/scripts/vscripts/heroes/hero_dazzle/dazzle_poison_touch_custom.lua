dazzle_poison_touch_custom = class({})
LinkLuaModifier( "modifier_dazzle_poison_touch_custom", "heroes/hero_dazzle/dazzle_poison_touch_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function dazzle_poison_touch_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local origin = caster:GetOrigin()

    -- cancel if linken
    if target:TriggerSpellAbsorb( self ) then return end

    -- load data
    local max_targets = self:GetSpecialValueFor( "targets" )
    local distance = self:GetSpecialValueFor( "end_distance" )
    local start_radius = self:GetSpecialValueFor( "start_radius" )
    local end_radius = self:GetSpecialValueFor( "end_radius" )

    -- get direction
    local direction = target:GetOrigin()-origin
    direction.z = 0
    direction = direction:Normalized()

    local enemies = self:FindUnitsInCone(
        caster:GetTeamNumber(), -- nTeamNumber
        target:GetOrigin(), -- vCenterPos
        caster:GetOrigin(), -- vStartPos
        caster:GetOrigin() + direction*distance,    -- vEndPos
        start_radius,   -- fStartRadius
        end_radius, -- fEndRadius
        nil,    -- hCacheUnit
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- nTeamFilter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- nTypeFilter
        0,  -- nFlagFilter
        FIND_CLOSEST,   -- nOrderFilter
        false   -- bCanGrowCache
    )

    -- projectile data
    local projectile_name = "particles/units/heroes/hero_dazzle/dazzle_poison_touch.vpcf"
    local projectile_speed = self:GetSpecialValueFor( "projectile_speed" )

    -- precache projectile
    local info = {
        -- Target = target,
        Source = caster,
        Ability = self, 
        
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bDodgeable = true,                           -- Optional
    
        bVisibleToEnemies = true,                         -- Optional
        bProvidesVision = false,                           -- Optional
    }

    -- create projectile
    local counter = 0
    for _,enemy in pairs(enemies) do
        info.Target = enemy
        ProjectileManager:CreateTrackingProjectile(info)

        counter = counter+1
        if counter>=max_targets then break end
    end

    -- Play effects
    local sound_cast = "Hero_Dazzle.Poison_Cast"
    EmitSoundOn( sound_cast, caster )
end

--------------------------------------------------------------------------------
-- Projectile
function dazzle_poison_touch_custom:OnProjectileHit( target, location )
    if not target then return end

    -- get data
    local duration = self:GetSpecialValueFor( "duration" )

    -- add debuff
    local debuff = target:FindModifierByName("modifier_dazzle_poison_touch_custom")
    if not debuff then
        debuff = target:AddNewModifier(
            self:GetCaster(), -- player source
            self, -- ability source
            "modifier_dazzle_poison_touch_custom", -- modifier name
            { duration = duration } -- kv
        )
    end

    if debuff then
        if debuff:GetStackCount() < self:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end

    -- Play effects
    local sound_target = "Hero_Dazzle.Poison_Touch"
    EmitSoundOn( sound_target, target )
end

--------------------------------------------------------------------------------
-- Helper
function dazzle_poison_touch_custom:FindUnitsInCone( nTeamNumber, vCenterPos, vStartPos, vEndPos, fStartRadius, fEndRadius, hCacheUnit, nTeamFilter, nTypeFilter, nFlagFilter, nOrderFilter, bCanGrowCache )
    -- vCenterPos is used to determine searching center (FIND_CLOSEST will refer to units closest to vCenterPos)

    -- get cast direction and length distance
    local direction = vEndPos-vStartPos
    direction.z = 0

    local distance = direction:Length2D()
    direction = direction:Normalized()

    -- get max radius circle search
    local big_radius = distance + math.max(fStartRadius, fEndRadius)

    -- find enemies closest to primary target within max radius
    local units = FindUnitsInRadius(
        nTeamNumber,    -- int, your team number
        vCenterPos, -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        big_radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        nTeamFilter,    -- int, team filter
        nTypeFilter,    -- int, type filter
        nFlagFilter,    -- int, flag filter
        nOrderFilter,   -- int, order filter
        bCanGrowCache   -- bool, can grow cache
    )

    -- Filter within cone
    local targets = {}
    for _,unit in pairs(units) do

        -- get unit vector relative to vStartPos
        local vUnitPos = unit:GetOrigin()-vStartPos

        -- get projection scalar of vUnitPos onto direction using dot-product
        local fProjection = vUnitPos.x*direction.x + vUnitPos.y*direction.y + vUnitPos.z*direction.z

        -- clamp projected scalar to [0,distance]
        fProjection = math.max(math.min(fProjection,distance),0)
        
        -- get projected vector of vUnitPos onto direction
        local vProjection = direction*fProjection

        -- calculate distance between vUnitPos and the projected vector
        local fUnitRadius = (vUnitPos - vProjection):Length2D()

        -- calculate interpolated search radius at projected vector
        local fInterpRadius = (fProjection/distance)*(fEndRadius-fStartRadius) + fStartRadius

        -- if unit is within distance, add them
        if fUnitRadius<=fInterpRadius then
            table.insert( targets, unit )
        end
    end

    return targets
end

modifier_dazzle_poison_touch_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_dazzle_poison_touch_custom:IsHidden()
    return false
end

function modifier_dazzle_poison_touch_custom:IsDebuff()
    return true
end

function modifier_dazzle_poison_touch_custom:IsStunDebuff()
    return false
end

function modifier_dazzle_poison_touch_custom:IsPurgable()
    return true
end

function modifier_dazzle_poison_touch_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_dazzle_poison_touch_custom:OnCreated( kv )
    -- references
    self.slow = self:GetAbility():GetSpecialValueFor( "slow" )
    self.duration = kv.duration

    if not IsServer() then return end
    -- precache damage
    self.damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self, --Optional.
    }
    -- ApplyDamage(damageTable)

    self.count = 0

    -- Start interval
    self:StartIntervalThink( 1 )
    self:OnIntervalThink()
end

function modifier_dazzle_poison_touch_custom:OnRefresh( kv )
end

function modifier_dazzle_poison_touch_custom:OnRemoved()
end

function modifier_dazzle_poison_touch_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_dazzle_poison_touch_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,

        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function modifier_dazzle_poison_touch_custom:OnAttackLanded( params )
    if not IsServer() then return end
    if params.target~=self:GetParent() then return end

    -- refresh duration
    if self:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
        self:IncrementStackCount()
    end

    self:ForceRefresh()
end

function modifier_dazzle_poison_touch_custom:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

function modifier_dazzle_poison_touch_custom:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res") * self:GetStackCount()
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_dazzle_poison_touch_custom:OnIntervalThink()
    -- apply damage
    local damage = ((self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100)) + self:GetAbility():GetSpecialValueFor( "damage" )) * self:GetStackCount()
    self.damageTable.damage = damage
    ApplyDamage( self.damageTable )

    -- Play effects
    local sound_cast = "Hero_Dazzle.Poison_Tick"
    EmitSoundOn( sound_cast, self:GetParent() )

    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        if self.count == self:GetAbility():GetSpecialValueFor("hex_interval") then
            self:GetParent():AddNewModifier(self:GetCaster(), nil, "modifier_hexxed", {
                duration = self:GetAbility():GetSpecialValueFor("hex_duration")
            })

            self.count = 0
        end

        self.count = self.count + 1
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_dazzle_poison_touch_custom:GetEffectName()
    return "particles/units/heroes/hero_dazzle/dazzle_poison_debuff.vpcf"
end

function modifier_dazzle_poison_touch_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_dazzle_poison_touch_custom:GetStatusEffectName()
    return "particles/status_fx/status_effect_poison_dazzle_copy.vpcf"
end

function modifier_dazzle_poison_touch_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end