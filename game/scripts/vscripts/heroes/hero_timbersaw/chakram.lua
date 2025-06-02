LinkLuaModifier( "modifier_timbersaw_chakram_custom", "heroes/hero_timbersaw/chakram", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_timbersaw_chakram_custom_disarm", "heroes/hero_timbersaw/chakram", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_timbersaw_chakram_custom_thinker", "heroes/hero_timbersaw/chakram", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Main ability
--------------------------------------------------------------------------------
timbersaw_chakram_custom = class({})

-- register here for easy copy on scepter ability
timbersaw_chakram_custom.sub_name = "timbersaw_return_chakram_custom"
timbersaw_chakram_custom.scepter = 0

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function timbersaw_chakram_custom:GetAOERadius()
    return self:GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------
-- Ability Start
function timbersaw_chakram_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- create thinker
    local thinker = CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_timbersaw_chakram_custom_thinker", -- modifier name
        {
            target_x = point.x,
            target_y = point.y,
            target_z = point.z,
            scepter = false,
        }, -- kv
        caster:GetOrigin(),
        caster:GetTeamNumber(),
        false
    )
    local modifier = thinker:FindModifierByName( "modifier_timbersaw_chakram_custom_thinker" )

    -- add return ability and swap
    if caster:FindAbilityByName(self.sub_name) == nil then
        local sub = caster:AddAbility( self.sub_name )
        sub:SetLevel( 1 )
        caster:SwapAbilities(
            self:GetAbilityName(),
            self.sub_name,
            false,
            true
        )

        -- register each other
        self.modifier = modifier
        self.sub = sub
        sub.modifier = modifier
        modifier.sub = sub
    end

    -- play effects
    local sound_cast = "Hero_Shredder.Chakram.Cast"
    EmitSoundOn( sound_cast, caster )
end

function timbersaw_chakram_custom:OnUnStolen()
    if self.modifier and not self.modifier:IsNull() then
        -- return the chakram
        self.modifier:ReturnChakram()

        -- reset position
        self:GetCaster():SwapAbilities(
            self:GetAbilityName(),
            self.sub:GetAbilityName(),
            true,
            false
        )
    end
end

--------------------------------------------------------------------------------
-- Item Events
--[[
function timbersaw_chakram_custom:OnInventoryContentsChanged( params )
    local caster = self:GetCaster()

    -- get data
    local scepter = caster:HasScepter()
    local ability = caster:FindAbilityByName( "timbersaw_chakram_2_custom" )

    -- if there's no ability, why bother
    if not ability then return end
    if ability:GetAbilityName() ~= "item_ultimate_scepter" then return end

    ability:SetActivated( scepter )
    ability:SetHidden( not scepter )

    if ability:GetLevel()<1 then
        ability:SetLevel( 1 )
    end
end
--]]

--------------------------------------------------------------------------------
-- Sub-ability
--------------------------------------------------------------------------------
timbersaw_return_chakram_custom = class({})

--------------------------------------------------------------------------------
-- Ability Start
function timbersaw_return_chakram_custom:OnSpellStart()
    if self.modifier and not self.modifier:IsNull() then
        self.modifier:ReturnChakram()
    end
end

--------------------------------------------------------------------------------
-- Scepter-ability
--------------------------------------------------------------------------------
timbersaw_chakram_2_custom = class(timbersaw_chakram_custom)
timbersaw_chakram_2_custom.sub_name = "timbersaw_return_chakram_2_custom"
timbersaw_chakram_2_custom.scepter = 1
timbersaw_chakram_2_custom.OnInventoryContentsChanged = nil

timbersaw_return_chakram_2_custom = class(timbersaw_return_chakram_custom)

modifier_timbersaw_chakram_custom_thinker = class({})
local MODE_LAUNCH = 0
local MODE_STAY = 1
local MODE_RETURN = 2

--------------------------------------------------------------------------------
-- Classifications
function modifier_timbersaw_chakram_custom_thinker:IsHidden()
    return true
end

function modifier_timbersaw_chakram_custom_thinker:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_timbersaw_chakram_custom_thinker:OnCreated( kv )
    if not IsServer() then return end
    self.parent = self:GetParent()
    self.caster = self:GetCaster()

    -- references
    self.damage_pass = self:GetAbility():GetSpecialValueFor( "pass_damage" )
    self.damage_stay = self:GetAbility():GetSpecialValueFor( "damage_per_second" )
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.speed = self:GetAbility():GetSpecialValueFor( "speed" )
    self.duration = self:GetAbility():GetSpecialValueFor( "pass_slow_duration" )
    self.manacost = self:GetAbility():GetSpecialValueFor( "mana_per_second" )
    self.max_range = self:GetAbility():GetSpecialValueFor( "break_distance" )
    self.interval = self:GetAbility():GetSpecialValueFor( "damage_interval" )

    -- kv references
    self.point = Vector( kv.target_x, kv.target_y, kv.target_z )
    self.scepter = false

    -- init vars
    self.mode = MODE_LAUNCH
    self.move_interval = FrameTime()
    self.proximity = 50
    self.caught_enemies = {}
    self.damageTable = {
        -- victim = target,
        attacker = self.caster,
        -- damage = damage,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(), --Optional.
    }
    -- ApplyDamage(damageTable)

    -- give vision to thinker
    self.parent:SetDayTimeVisionRange( 500 )
    self.parent:SetNightTimeVisionRange( 500 )

    -- add disarm to caster
    self.disarm = self.caster:AddNewModifier(
        self.caster, -- player source
        self:GetAbility(), -- ability source
        "modifier_timbersaw_chakram_custom_disarm", -- modifier name
        {} -- kv
    )

    -- Init mode
    self.damageTable.damage = self.damage_pass + (self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("str_damage_pct")/100))
    self:StartIntervalThink( self.move_interval )

    -- play effects
    self:PlayEffects1()
end

function modifier_timbersaw_chakram_custom_thinker:OnRemoved()
end

function modifier_timbersaw_chakram_custom_thinker:OnDestroy()
    if not IsServer() then return end

    -- remove disarm
    if not self.disarm:IsNull() then
        self.disarm:Destroy()
    end

    -- swap ability back, then remove sub
    local main = self:GetAbility()
    if main and (not main:IsNull()) and (not self.sub:IsNull()) then
        -- check if main is hidden (due to scepter or stolen)
        local active = main:IsActivated()

        self.caster:SwapAbilities(
            main:GetAbilityName(),
            self.sub:GetAbilityName(),
            active,
            false
        )
    end
    self.caster:RemoveAbilityByHandle( self.sub )

    -- stop effects
    self:StopEffects()

    -- remove
    UTIL_Remove( self.parent )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_timbersaw_chakram_custom_thinker:OnIntervalThink()
    -- check mode
    if self.mode==MODE_LAUNCH then
        self:LaunchThink()
    elseif self.mode==MODE_STAY then
        self:StayThink()
    elseif self.mode==MODE_RETURN then
        self:ReturnThink()
    end
end

function modifier_timbersaw_chakram_custom_thinker:LaunchThink()
    local origin = self.parent:GetOrigin()

    -- pass logic
    self:PassLogic( origin )

    -- move logic
    local close = self:MoveLogic( origin )

    local damage = (self.damage_stay+(self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("str_damage_pct")/100)))

    self.shardDamage = 0

    if self.parent:HasModifier("modifier_item_aghanims_shard") then
        self.shardDamage = damage * (self:GetAbility():GetSpecialValueFor("pure_to_damage")/100)
    end

    -- if close, switch to stay mode
    if close then
        self.mode = MODE_STAY
        self.damageTable.damage = damage
        self:StartIntervalThink( self.interval )
        self:OnIntervalThink()

        -- play effects
        self:PlayEffects2()
    end
end

function modifier_timbersaw_chakram_custom_thinker:StayThink()
    local origin = self.parent:GetOrigin()

    -- check if died, too far or not enough manacost
    local mana = self.caster:GetMana()
    if (self.caster:GetOrigin()-origin):Length2D()>self.max_range or mana<self.manacost*self.interval or (not self.caster:IsAlive()) then
        self:ReturnChakram()
        return
    end

    -- spend mana
    self.caster:SpendMana( self.manacost*self.interval, self:GetAbility() )

    -- find enemies
    local enemies = FindUnitsInRadius(
        self.caster:GetTeamNumber(),    -- int, your team number
        origin, -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        -- damage
        self.damageTable.victim = enemy
        ApplyDamage( self.damageTable )
        
        if self.shardDamage > 0 then
            ApplyDamage({
                victim = enemy,
                attacker = self.parent,
                damage = self.shardDamage,
                damage_type = DAMAGE_TYPE_PURE,
                ability = self:GetAbility()
            })
        end

        -- -- add debuff
        -- enemy:AddNewModifier(
        --  self.caster, -- player source
        --  self:GetAbility(), -- ability source
        --  "modifier_timbersaw_chakram_custom", -- modifier name
        --  { duration = self.duration } -- kv
        -- )
    end

    -- destroy trees
    local sound_tree = "Hero_Shredder.Chakram.Tree"
    local trees = GridNav:GetAllTreesAroundPoint( origin, self.radius, true )
    for _,tree in pairs(trees) do
        EmitSoundOnLocationWithCaster( tree:GetOrigin(), sound_tree, self.parent )
    end
    GridNav:DestroyTreesAroundPoint( origin, self.radius, true )
end

function modifier_timbersaw_chakram_custom_thinker:ReturnThink()
    local origin = self.parent:GetOrigin()

    -- pass logic
    self:PassLogic( origin )

    -- move logic
    self.point = self.caster:GetOrigin( )
    local close = self:MoveLogic( origin )

    -- if close, destroy
    if close then
        self:Destroy()
    end
end

function modifier_timbersaw_chakram_custom_thinker:PassLogic( origin )
    -- find enemies
    local enemies = FindUnitsInRadius(
        self.caster:GetTeamNumber(),    -- int, your team number
        origin, -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        -- check if already hit
        if not self.caught_enemies[enemy] then
            self.caught_enemies[enemy] = true

            -- damage
            self.damageTable.victim = enemy
            ApplyDamage( self.damageTable )

            -- add debuff
            enemy:AddNewModifier(
                self.caster, -- player source
                self:GetAbility(), -- ability source
                "modifier_timbersaw_chakram_custom", -- modifier name
                { duration = self.duration } -- kv
            )

            -- play effects
            local sound_target = "Hero_Shredder.Chakram.Target"
            EmitSoundOn( sound_target, enemy )
        end
    end

    -- destroy trees
    local sound_tree = "Hero_Shredder.Chakram.Tree"
    local trees = GridNav:GetAllTreesAroundPoint( origin, self.radius, true )
    for _,tree in pairs(trees) do
        EmitSoundOnLocationWithCaster( tree:GetOrigin(), sound_tree, self.parent )
    end
    GridNav:DestroyTreesAroundPoint( origin, self.radius, true )
end

function modifier_timbersaw_chakram_custom_thinker:MoveLogic( origin )
    -- move position
    local direction = (self.point-origin):Normalized()
    local target = origin + direction * self.speed * self.move_interval
    -- target.z = GetGroundHeight( target, self.parent ) + 50
    self.parent:SetOrigin( target )

    -- return true if close to target
    return (target-self.point):Length2D()<self.proximity
end

function modifier_timbersaw_chakram_custom_thinker:ReturnChakram()
    -- if already returning, do nothing
    if self.mode == MODE_RETURN then return end

    -- switch mode
    self.mode = MODE_RETURN
    self.caught_enemies = {}
    self.damageTable.damage = self.damage_pass+(self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("str_damage_pct")/100))
    self:StartIntervalThink( self.move_interval )

    -- play effects
    self:PlayEffects3()
end

--------------------------------------------------------------------------------
-- Aura Effects
function modifier_timbersaw_chakram_custom_thinker:IsAura()
    return self.mode==MODE_STAY
end

function modifier_timbersaw_chakram_custom_thinker:GetModifierAura()
    return "modifier_timbersaw_chakram_custom"
end

function modifier_timbersaw_chakram_custom_thinker:GetAuraRadius()
    return self.radius
end

function modifier_timbersaw_chakram_custom_thinker:GetAuraDuration()
    return 0.3
end

function modifier_timbersaw_chakram_custom_thinker:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_timbersaw_chakram_custom_thinker:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_timbersaw_chakram_custom_thinker:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_timbersaw_chakram_custom_thinker:PlayEffects1()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_shredder/shredder_chakram.vpcf"
    local sound_cast = "Hero_Shredder.Chakram"

    -- get data
    local direction = self.point-self.parent:GetOrigin()
    direction.z = 0
    direction = direction:Normalized()

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent )
    ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, direction * self.speed )
    ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 0, 0, 0 ) )

    if self.scepter then
        -- set color to blue
        ParticleManager:SetParticleControl( self.effect_cast, 15, Vector( 0, 0, 255 ) )
        ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 1, 0, 0 ) )
    end

    -- Create Sound
    EmitSoundOn( sound_cast, self.parent )
end

function modifier_timbersaw_chakram_custom_thinker:PlayEffects2()
    -- destroy previous particle
    ParticleManager:DestroyParticle( self.effect_cast, false )
    ParticleManager:ReleaseParticleIndex( self.effect_cast )

    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_shredder/shredder_chakram_stay.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( self.effect_cast, 0, self.parent:GetOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 0, 0, 0 ) )

    if self.scepter then
        -- set color to blue
        ParticleManager:SetParticleControl( self.effect_cast, 15, Vector( 0, 0, 255 ) )
        ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 1, 0, 0 ) )
    end
end

function modifier_timbersaw_chakram_custom_thinker:PlayEffects3()
    -- destroy previous particle
    ParticleManager:DestroyParticle( self.effect_cast, false )
    ParticleManager:ReleaseParticleIndex( self.effect_cast )

    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_shredder/shredder_chakram_return.vpcf"
    local sound_cast = "Hero_Shredder.Chakram.Return"
    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent )
    ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        1,
        self.caster,
        PATTACH_ABSORIGIN_FOLLOW,
        nil,
        self.caster:GetOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect_cast, 2, Vector( self.speed, 0, 0 ) )
    ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 0, 0, 0 ) )

    if self.scepter then
        -- set color to blue
        ParticleManager:SetParticleControl( self.effect_cast, 15, Vector( 0, 0, 255 ) )
        ParticleManager:SetParticleControl( self.effect_cast, 16, Vector( 1, 0, 0 ) )
    end

    -- Create Sound
    EmitSoundOn( sound_cast, self.parent )
end

function modifier_timbersaw_chakram_custom_thinker:StopEffects()
    -- destroy previous particle
    ParticleManager:DestroyParticle( self.effect_cast, false )
    ParticleManager:ReleaseParticleIndex( self.effect_cast )

    -- stop sound
    local sound_cast = "Hero_Shredder.Chakram"
    StopSoundOn( sound_cast, self.parent )
end

modifier_timbersaw_chakram_custom_disarm = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_timbersaw_chakram_custom_disarm:IsHidden()
    return false
end

function modifier_timbersaw_chakram_custom_disarm:IsDebuff()
    return false
end

function modifier_timbersaw_chakram_custom_disarm:IsPurgable()
    return false
end

function modifier_timbersaw_chakram_custom_disarm:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_timbersaw_chakram_custom_disarm:OnCreated( kv )
end

function modifier_timbersaw_chakram_custom_disarm:OnRefresh( kv )
end

function modifier_timbersaw_chakram_custom_disarm:OnRemoved()
end

function modifier_timbersaw_chakram_custom_disarm:OnDestroy()
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_timbersaw_chakram_custom_disarm:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true,
    }

    return state
end

modifier_timbersaw_chakram_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_timbersaw_chakram_custom:IsHidden()
    return false
end

function modifier_timbersaw_chakram_custom:IsDebuff()
    return true
end

function modifier_timbersaw_chakram_custom:IsStunDebuff()
    return false
end

function modifier_timbersaw_chakram_custom:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_timbersaw_chakram_custom:OnCreated( kv )
    -- references
    if self:GetAbility() and not self:GetAbility():IsNull() then
        self.slow = self:GetAbility():GetSpecialValueFor( "slow" )
    else
        -- ability is deleted
        self.slow = 0
    end
    self.step = 5
end

function modifier_timbersaw_chakram_custom:OnRefresh( kv )
    self:OnCreated( kv )
end

function modifier_timbersaw_chakram_custom:OnRemoved()
end

function modifier_timbersaw_chakram_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_timbersaw_chakram_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_timbersaw_chakram_custom:GetModifierMoveSpeedBonus_Percentage()
    -- reduced to step of 5
    return -math.floor( (100-self:GetParent():GetHealthPercent())/self.step ) * self.slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_timbersaw_chakram_custom:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost.vpcf"
end