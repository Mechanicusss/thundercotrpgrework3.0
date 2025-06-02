-- Created by Elfansoer
--[[
Ability checklist (erase if done/checked):
- Scepter Upgrade
- Break behavior
- Linken/Reflect behavior
- Spell Immune/Invulnerable/Invisible behavior
- Illusion behavior
- Stolen behavior
]]
--------------------------------------------------------------------------------
primal_beast_onslaught_custom = class({})
primal_beast_onslaught_release_custom = class({})
primal_beast_onslaught_stop_custom = class({})
LinkLuaModifier( "modifier_primal_beast_onslaught_custom_charge", "heroes/hero_primal_beast/primal_beast_onslaught_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_primal_beast_onslaught_custom", "heroes/hero_primal_beast/primal_beast_onslaught_custom", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_primal_beast_onslaught_custom_slowed", "heroes/hero_primal_beast/primal_beast_onslaught_custom", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_primal_beast_onslaught_custom_shard_debuff", "heroes/hero_primal_beast/primal_beast_onslaught_custom", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_generic_arc_lua", "modifiers/modifier_generic_arc_lua", LUA_MODIFIER_MOTION_BOTH )

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

modifier_primal_beast_onslaught_custom_slowed = class(ItemBaseClassDebuff)
modifier_primal_beast_onslaught_custom_shard_debuff = class(ItemBaseClassDebuff)
--------------------------------------------------------------------------------
-- Init Abilities
function primal_beast_onslaught_custom:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_primal_beast.vsndevts", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_primal_beast/primal_beast_onslaught_charge_active.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_primal_beast/primal_beast_onslaught_impact.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_primal_beast/primal_beast_onslaught_chargeup.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_primal_beast/primal_beast_onslaught_range_finder.vpcf", context )
    PrecacheResource( "particle", "particles/econ/items/primal_beast/primal_beast_2022_prestige/primal_beast_2022_prestige_onslaught_charge_active.vpcf", context )
    PrecacheResource( "particle", "particles/econ/items/primal_beast/primal_beast_2022_prestige/primal_beast_2022_prestige_onslaught_impact.vpcf", context )
    PrecacheResource( "particle", "particles/econ/items/primal_beast/primal_beast_2022_prestige/primal_beast_2022_prestige_onslaught_chargeup.vpcf", context )
end

function primal_beast_onslaught_custom:Spawn()
    if not IsServer() then return end
end

--------------------------------------------------------------------------------
-- Ability Start
function primal_beast_onslaught_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- load data
    local duration = self:GetSpecialValueFor( "chargeup_time" )

    -- talent 
    local talent = caster:FindAbilityByName("talent_primal_beast_1")
    if talent ~= nil and talent:GetLevel() > 0 then
        duration = FrameTime()
    end

    -- add modifier
    local mod = caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_primal_beast_onslaught_custom_charge", -- modifier name
        { duration = duration } -- kv
    )
    -- mod.direction = direction

    self.sub = caster:FindAbilityByName( "primal_beast_onslaught_release_custom" )
    if not self.sub or self.sub:IsNull() then
        self.sub = caster:AddAbility( "primal_beast_onslaught_release_custom" )
    end
    self.sub.main = self
    self.sub:SetLevel(1)

    caster:SwapAbilities(
        self:GetAbilityName(),
        self.sub:GetAbilityName(),
        false,
        true
    )

    -- set cooldown
    self.sub:UseResources( false, false, false, true )
end

function primal_beast_onslaught_custom:OnChargeFinish( interrupt )
    -- unit identifier
    local caster = self:GetCaster()

    caster:SwapAbilities(
        self:GetAbilityName(),
        self.sub:GetAbilityName(),
        true,
        false
    )

    -- load data
    local max_duration = self:GetSpecialValueFor( "chargeup_time" )
    local max_distance = self:GetSpecialValueFor( "max_distance" )
    local speed = self:GetSpecialValueFor( "charge_speed" )

    local chargeTable = {}

    -- find charge modifier
    local charge_duration = max_duration
    local mod = caster:FindModifierByName( "modifier_primal_beast_onslaught_custom_charge" )
    if mod then
        charge_duration = mod:GetElapsedTime()

        mod.charge_finish = true
        mod:Destroy()
    end

    local distance = max_distance * charge_duration/max_duration
    local duration = distance/speed

    -- cancel if interrupted
    if interrupt then return end

    chargeTable = { duration = duration  }

    -- talent 
    local talent = caster:FindAbilityByName("talent_primal_beast_1")
    if talent ~= nil and talent:GetLevel() > 0 then
        chargeTable = {}
        caster:CenterCameraOnEntity(caster, 9999)
    end

    -- add modifier
    caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_primal_beast_onslaught_custom", -- modifier name
        chargeTable -- kv
    )

    -- play effects
    EmitSoundOn( "Hero_PrimalBeast.Onslaught", caster )
end

--------------------------------------------------------------------------------
-- Sub-ability
function primal_beast_onslaught_release_custom:OnSpellStart()
    self.main:OnChargeFinish( false )
end

function primal_beast_onslaught_stop_custom:OnSpellStart()
    if not IsServer() then return end 

    local mod = self:GetCaster():FindModifierByName("modifier_primal_beast_onslaught_custom")
    if mod then
        mod:Destroy()
    end
end

modifier_primal_beast_onslaught_custom_charge = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_primal_beast_onslaught_custom_charge:IsHidden()
    return false
end

function modifier_primal_beast_onslaught_custom_charge:IsDebuff()
    return false
end

function modifier_primal_beast_onslaught_custom_charge:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_primal_beast_onslaught_custom_charge:OnCreated( kv )
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    -- references
    self.speed = self:GetAbility():GetSpecialValueFor( "charge_speed" )
    self.turn_speed = self:GetAbility():GetSpecialValueFor( "turn_rate" )

    if not IsServer() then return end

    self.origin = self.parent:GetOrigin()
    self.charge_finish = false

    -- turning data
    self.target_angle = self.parent:GetAnglesAsVector().y
    self.current_angle = self.target_angle
    self.face_target = true

    -- Start interval
    self:StartIntervalThink( FrameTime() )

    -- order filter using library
    self.filter = FilterManager:AddExecuteOrderFilter( self.OrderFilter, self )

    local hasTalent = false 
    local talent = self.parent:FindAbilityByName("talent_primal_beast_1")
    if talent ~= nil and talent:GetLevel() > 0 then
        hasTalent = true 
    end

    -- play effect
    self:PlayEffects1(hasTalent)
    self:PlayEffects2(hasTalent)
end

function modifier_primal_beast_onslaught_custom_charge:OnRefresh( kv )
end

function modifier_primal_beast_onslaught_custom_charge:OnRemoved()
    if not IsServer() then return end

    -- stop effects
    local sound_cast = "Hero_PrimalBeast.Onslaught.Channel"
    EmitSoundOn( sound_cast, self.parent )

    if not self.charge_finish then
        self.ability:OnChargeFinish( false )
    end

    -- remove filter
    FilterManager:RemoveExecuteOrderFilter( self.filter )
end

function modifier_primal_beast_onslaught_custom_charge:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_primal_beast_onslaught_custom_charge:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ORDER,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }

    return funcs
end

function modifier_primal_beast_onslaught_custom_charge:OnOrder( params )
    if params.unit~=self:GetParent() then return end

    -- point right click
    if  params.order_type==DOTA_UNIT_ORDER_MOVE_TO_POSITION or
        params.order_type==DOTA_UNIT_ORDER_MOVE_TO_DIRECTION
    then
        -- set facing
        self:SetDirection( params.new_pos )

    -- targetted right click
    elseif 
        params.order_type==DOTA_UNIT_ORDER_MOVE_TO_TARGET or
        params.order_type==DOTA_UNIT_ORDER_ATTACK_TARGET
    then
        -- set facing
        self:SetDirection( params.target:GetOrigin() )
    
    elseif
        params.order_type==DOTA_UNIT_ORDER_STOP or 
        params.order_type==DOTA_UNIT_ORDER_HOLD_POSITION
    then
        self.ability:OnChargeFinish( false )
    end 
end

function modifier_primal_beast_onslaught_custom_charge:SetDirection( location )
    local dir = ((location-self.parent:GetOrigin())*Vector(1,1,0)):Normalized()
    self.target_angle = VectorToAngles( dir ).y
    self.face_target = false
end

function modifier_primal_beast_onslaught_custom_charge:GetModifierMoveSpeed_Limit()
    return 0.1
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_primal_beast_onslaught_custom_charge:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true,
    }

    return state
end

--------------------------------------------------------------------------------
-- Filter
-- NOTE: Filter is required because right-clicking faces the unit to target position, RESPECTING the terrain, so the target point may be different
function modifier_primal_beast_onslaught_custom_charge:OrderFilter( data )
    -- only filter right-clicks
    if data.order_type~=DOTA_UNIT_ORDER_MOVE_TO_POSITION and
        data.order_type~=DOTA_UNIT_ORDER_MOVE_TO_TARGET and
        data.order_type~=DOTA_UNIT_ORDER_ATTACK_TARGET
    then
        return true
    end

    -- filter orders given to parent
    local found = false
    for _,entindex in pairs(data.units) do
        local entunit = EntIndexToHScript( entindex )
        if entunit==self.parent then
            found = true
        end
    end
    if not found then return true end

    -- set order to move to direction
    data.order_type = DOTA_UNIT_ORDER_MOVE_TO_DIRECTION

    -- if there is target, set position to its origin
    if data.entindex_target~=0 then
        local pos = EntIndexToHScript( data.entindex_target ):GetOrigin()
        data.position_x = pos.x
        data.position_y = pos.y
        data.position_z = pos.z
    end

    return true
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_primal_beast_onslaught_custom_charge:OnIntervalThink()
    -- cancel logic
    if self.parent:IsRooted() or self.parent:IsStunned() or self.parent:IsSilenced() or
        self.parent:IsCurrentlyHorizontalMotionControlled() or self.parent:IsCurrentlyVerticalMotionControlled()
    then
        self.ability:OnChargeFinish( true )
    end

    -- turning logic
    self:TurnLogic( FrameTime() )

    -- set particles
    self:SetEffects()
end

function modifier_primal_beast_onslaught_custom_charge:TurnLogic( dt )
    -- only rotate when target changed
    if self.face_target then return end

    local angle_diff = AngleDiff( self.current_angle, self.target_angle )
    local turn_speed = self.turn_speed*dt

    local sign = -1
    if angle_diff<0 then sign = 1 end

    if math.abs( angle_diff )<1.1*turn_speed then
        -- end rotating
        self.current_angle = self.target_angle
        self.face_target = true
    else
        -- rotate current angle
        self.current_angle = self.current_angle + sign*turn_speed
    end

    -- turn the unit
    local angles = self.parent:GetAnglesAsVector()
    self.parent:SetLocalAngles( angles.x, self.current_angle, angles.z )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_primal_beast_onslaught_custom_charge:PlayEffects1()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_primal_beast/primal_beast_onslaught_range_finder.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticleForPlayer( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent, self.parent:GetPlayerOwner() )
    ParticleManager:SetParticleControl( effect_cast, 0, self.parent:GetOrigin() )

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )

    self.effect_cast = effect_cast
    self:SetEffects()
end

function modifier_primal_beast_onslaught_custom_charge:SetEffects()
    local target_pos = self.origin + self.parent:GetForwardVector() * self.speed * self:GetElapsedTime()
    ParticleManager:SetParticleControl( self.effect_cast, 1, target_pos )
end

function modifier_primal_beast_onslaught_custom_charge:PlayEffects2(hasTalent)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_primal_beast/primal_beast_onslaught_chargeup.vpcf"
    local sound_cast = "Hero_PrimalBeast.Onslaught.Channel"

    if hasTalent then
        particle_cast = "particles/econ/items/primal_beast/primal_beast_2022_prestige/primal_beast_2022_prestige_onslaught_chargeup.vpcf"
    end

    -- Get Data

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, self.parent )
    ParticleManager:SetParticleControl( effect_cast, 0, self.parent:GetOrigin() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )

    -- Create Sound
    EmitSoundOn( sound_cast, self.parent )
end

modifier_primal_beast_onslaught_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_primal_beast_onslaught_custom:IsHidden()
    return false
end

function modifier_primal_beast_onslaught_custom:IsDebuff()
    return false
end

function modifier_primal_beast_onslaught_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_primal_beast_onslaught_custom:OnCreated( kv )
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    -- references
    self.speed = self:GetAbility():GetSpecialValueFor( "charge_speed" )
    self.turn_speed = self:GetAbility():GetSpecialValueFor( "turn_rate" )

    self.radius = self:GetAbility():GetSpecialValueFor( "knockback_radius" )
    self.distance = self:GetAbility():GetSpecialValueFor( "knockback_distance" )
    self.duration = self:GetAbility():GetSpecialValueFor( "knockback_duration" )
    self.stun = self:GetAbility():GetSpecialValueFor( "stun_duration" )
    self.slowDuration = self:GetAbility():GetSpecialValueFor( "slow_duration" )

    self.damage = self:GetAbility():GetSpecialValueFor( "max_hp_damage" )
    self.strengthMultiplier = self:GetAbility():GetSpecialValueFor( "strength_multiplier" )

    self.tree_radius = 100
    self.height = 50
    self.duration = 0.3 -- kv above is a lie

    self.maxManaPct = 0
    self.maxManaPctSec = 0
    self.timeDamageMultiplier = 0

    self.hasTalent = false
    self.primalBeastTalent = nil

    local talent = self.parent:FindAbilityByName("talent_primal_beast_1")
    if talent ~= nil and talent:GetLevel() > 0 then
        self.hasTalent = true
        self.primalBeastTalent = talent

        self.maxManaPct = talent:GetSpecialValueFor("max_mana_drain_pct")
        self.maxManaPctSec = talent:GetSpecialValueFor("max_mana_drain_increase_per_sec")
        self.timeDamageMultiplier = talent:GetSpecialValueFor("time_damage_multiplier")
    end

    if not IsServer() then return end

    self:StartIntervalThink(1.0)

    self.ability:SetActivated(false)

    -- ability properties
    self.abilityDamageType = self:GetAbility():GetAbilityDamageType()
    self.abilityTargetTeam = self:GetAbility():GetAbilityTargetTeam()
    self.abilityTargetType = self:GetAbility():GetAbilityTargetType()
    self.abilityTargetFlags = self:GetAbility():GetAbilityTargetFlags()

    -- turning data
    self.target_angle = self.parent:GetAnglesAsVector().y
    self.current_angle = self.target_angle
    self.face_target = true

    -- knockback data
    self.knockback_units = {}
    self.knockback_units[self.parent] = true

    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
        return
    end

    -- precache damage
    self.damageTable = {
        -- victim = target,
        attacker = self.parent,
        damage_type = self.abilityDamageType,
        ability = self.ability, --Optional.
    }

    self.stop = self.parent:FindAbilityByName("primal_beast_onslaught_stop_custom")
    if not self.stop or self.stop:IsNull() then
        self.stop = self.parent:AddAbility( "primal_beast_onslaught_stop_custom")
    end

    if self.stop ~= nil then
        self.stop.main = self:GetAbility()
        self.stop:SetLevel(1)

        self.parent:SwapAbilities(
            self:GetAbility():GetAbilityName(),
            self.stop:GetAbilityName(),
            false,
            true
        )
    end
end

function modifier_primal_beast_onslaught_custom:OnRefresh( kv )
end

function modifier_primal_beast_onslaught_custom:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if self.hasTalent then
        caster:CenterCameraOnEntity(caster, 0.1)
    end

    if self.stop ~= nil then
        self.parent:SwapAbilities(
            self:GetAbility():GetAbilityName(),
            self.stop:GetAbilityName(),
            true,
            false
        )
    end
end

function modifier_primal_beast_onslaught_custom:OnDestroy()
    if not IsServer() then return end
    self.parent:RemoveHorizontalMotionController(self)
    self.ability:SetActivated(true)
    FindClearSpaceForUnit( self.parent, self.parent:GetOrigin(), false )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_primal_beast_onslaught_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ORDER,
        MODIFIER_PROPERTY_DISABLE_TURNING,

        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,

        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    }

    return funcs
end

function modifier_primal_beast_onslaught_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    local parent = self:GetParent()

    if not self.hasTalent or not self.primalBeastTalent then return end
    if not event.inflictor then return end
    if event.inflictor ~= self:GetAbility() then return end
    if self.primalBeastTalent:GetLevel() < 2 then return end

    local multiplier = self:GetElapsedTime() * self.timeDamageMultiplier

    return multiplier
end

function modifier_primal_beast_onslaught_custom:OnOrder( params )
    if params.unit~=self:GetParent() then return end

    -- point right click
    if  params.order_type==DOTA_UNIT_ORDER_MOVE_TO_POSITION then
        ExecuteOrderFromTable({
            UnitIndex = self.parent:entindex(),
            OrderType = DOTA_UNIT_ORDER_MOVE_TO_DIRECTION,
            Position = params.new_pos,
        })
    elseif
        params.order_type==DOTA_UNIT_ORDER_MOVE_TO_DIRECTION
    then
        -- set facing
        self:SetDirection( params.new_pos )

    -- targetted right click
    elseif 
        params.order_type==DOTA_UNIT_ORDER_MOVE_TO_TARGET or
        params.order_type==DOTA_UNIT_ORDER_ATTACK_TARGET
    then
        -- set facing
        self:SetDirection( params.target:GetOrigin() )
    
    elseif
        params.order_type==DOTA_UNIT_ORDER_STOP or 
        params.order_type==DOTA_UNIT_ORDER_HOLD_POSITION
    then
        self:Destroy()
    end 
end

function modifier_primal_beast_onslaught_custom:GetModifierDisableTurning()
    return 1
end

function modifier_primal_beast_onslaught_custom:SetDirection( location )
    local dir = ((location-self.parent:GetOrigin())*Vector(1,1,0)):Normalized()
    self.target_angle = VectorToAngles( dir ).y
    self.face_target = false
end

function modifier_primal_beast_onslaught_custom:GetOverrideAnimation()
    return ACT_DOTA_RUN
end

function modifier_primal_beast_onslaught_custom:GetActivityTranslationModifiers()
    return "onslaught_movement"
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_primal_beast_onslaught_custom:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local costMaxMana = self.maxManaPct + (self.maxManaPctSec*self:GetElapsedTime())

    local cost = parent:GetMaxMana() * (costMaxMana/100)
    if cost > parent:GetMana() then
        self:Destroy()
        return
    end

    parent:SpendMana(cost, ability)
end

function modifier_primal_beast_onslaught_custom:TurnLogic( dt )
    -- only rotate when target changed
    if self.face_target then return end

    local angle_diff = AngleDiff( self.current_angle, self.target_angle )
    local turn_speed = self.turn_speed*dt

    local sign = -1
    if angle_diff<0 then sign = 1 end

    if math.abs( angle_diff )<1.1*turn_speed then
        -- end rotating
        self.current_angle = self.target_angle
        self.face_target = true
    else
        -- rotate current angle
        self.current_angle = self.current_angle + sign*turn_speed
    end

    -- turn the unit
    local angles = self.parent:GetAnglesAsVector()
    self.parent:SetLocalAngles( angles.x, self.current_angle, angles.z )
end

function modifier_primal_beast_onslaught_custom:HitLogic()
    -- destroy trees
    GridNav:DestroyTreesAroundPoint( self.parent:GetOrigin(), self.tree_radius, false )

    local units = FindUnitsInRadius(
        self.parent:GetTeamNumber(),    -- int, your team number
        self.parent:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY, -- int, team filter
        self.abilityTargetType, -- int, type filter
        self.abilityTargetFlags,    -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,unit in pairs(units) do
        -- only knockback once
        if not self.knockback_units[unit] then
            self.knockback_units[unit] = true

            local is_enemy = unit:GetTeamNumber()~=self.parent:GetTeamNumber()

            -- damage and stun
            if is_enemy then
                local enemy = unit

                -- damage
                self.damageTable.victim = enemy
                self.damageTable.damage = (self.parent:GetMaxHealth() * (self.damage/100)) + (self.parent:GetStrength() * (self.strengthMultiplier/100))

                ApplyDamage(self.damageTable)

                if self.parent:HasModifier("modifier_item_aghanims_shard") then
                    enemy:AddNewModifier(
                        self.parent,
                        self.ability,
                        "modifier_primal_beast_onslaught_custom_shard_debuff",
                        {
                            duration = self.ability:GetSpecialValueFor("shard_duration")
                        }
                    )
                end

                -- stun
                enemy:AddNewModifier(
                    self.parent, -- player source
                    self.ability, -- ability source
                    "modifier_stunned", -- modifier name
                    { duration = self.stun } -- kv
                )

                -- slow 
                enemy:AddNewModifier(
                    self.parent, -- player source
                    self.ability, -- ability source
                    "modifier_primal_beast_onslaught_custom_slowed", -- modifier name
                    { duration = self.slowDuration } -- kv
                )
            end

            -- knockback, for both enemies and allies
            if is_enemy or not (unit:IsCurrentlyHorizontalMotionControlled() or unit:IsCurrentlyVerticalMotionControlled()) then
                -- knockback data
                local direction = unit:GetOrigin()-self.parent:GetOrigin()
                direction.z = 0
                direction = direction:Normalized()

                -- create arc
                unit:AddNewModifier(
                    self.parent, -- player source
                    self.ability, -- ability source
                    "modifier_generic_arc_lua", -- modifier name
                    {
                        dir_x = direction.x,
                        dir_y = direction.y,
                        duration = self.duration,
                        distance = self.distance,
                        height = self.height,
                        activity = ACT_DOTA_FLAIL,
                    } -- kv
                )
            end

            -- play effects
            self:PlayEffects( unit, self.radius )
        end
    end
end

--------------------------------------------------------------------------------
-- Motion Effects
function modifier_primal_beast_onslaught_custom:UpdateHorizontalMotion( me, dt )
    -- cancel if rooted
    if self.parent:IsRooted() then
        self:Destroy()
        return
    end

    self:HitLogic()

    self:TurnLogic( dt )

    local nextpos = me:GetOrigin() + me:GetForwardVector() * self.speed * dt
    me:SetOrigin(nextpos)
end

function modifier_primal_beast_onslaught_custom:OnHorizontalMotionInterrupted()
    self:Destroy()
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_primal_beast_onslaught_custom:GetEffectName()
    local talent = self:GetCaster():FindAbilityByName("talent_primal_beast_1")
    if talent ~= nil and talent:GetLevel() > 0 then
        return "particles/econ/items/primal_beast/primal_beast_2022_prestige/primal_beast_2022_prestige_onslaught_charge_active.vpcf"
    end

    return "particles/units/heroes/hero_primal_beast/primal_beast_onslaught_charge_active.vpcf"
end

function modifier_primal_beast_onslaught_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_primal_beast_onslaught_custom:PlayEffects( target, radius )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_primal_beast/primal_beast_onslaught_impact.vpcf"
    local sound_cast = "Hero_PrimalBeast.Onslaught.Hit"

    local talent = self:GetCaster():FindAbilityByName("talent_primal_beast_1")
    if talent ~= nil and talent:GetLevel() > 0 then
        return "particles/econ/items/primal_beast/primal_beast_2022_prestige/primal_beast_2022_prestige_onslaught_impact.vpcf"
    end

    -- Get Data

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

-------------------------------
function modifier_primal_beast_onslaught_custom_slowed:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_primal_beast_onslaught_custom_slowed:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end
---------------
function modifier_primal_beast_onslaught_custom_shard_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_primal_beast_onslaught_custom_shard_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("shard_damage_amp")
end