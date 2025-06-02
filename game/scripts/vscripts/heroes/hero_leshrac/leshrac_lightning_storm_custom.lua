leshrac_lightning_storm_custom = class({})
LinkLuaModifier( "modifier_leshrac_lightning_storm_custom", "heroes/hero_leshrac/leshrac_lightning_storm_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_leshrac_lightning_storm_custom_thinker", "heroes/hero_leshrac/leshrac_lightning_storm_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_leshrac_lightning_storm_custom_intrin", "heroes/hero_leshrac/leshrac_lightning_storm_custom.lua", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_leshrac_lightning_storm_custom_intrin = class(ItemBaseClass)

--------------------------------------------------------------------------------
-- Ability Start
function leshrac_lightning_storm_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    -- cancel if linken
    if target:TriggerSpellAbsorb( self ) then return end

    -- create thinker
    local thinker = CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_leshrac_lightning_storm_custom_thinker", -- modifier name
        {  }, -- kv
        caster:GetOrigin(),
        caster:GetTeamNumber(),
        false
    )
    local modifier = thinker:FindModifierByName( "modifier_leshrac_lightning_storm_custom_thinker" )
    modifier:Cast( target )
end

function leshrac_lightning_storm_custom:GetIntrinsicModifierName()
    return "modifier_leshrac_lightning_storm_custom_intrin"
end

modifier_leshrac_lightning_storm_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_leshrac_lightning_storm_custom:IsHidden()
    return false
end

function modifier_leshrac_lightning_storm_custom:IsDebuff()
    return true
end

function modifier_leshrac_lightning_storm_custom:IsStunDebuff()
    return false
end

function modifier_leshrac_lightning_storm_custom:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_leshrac_lightning_storm_custom:OnCreated( kv )
    if IsServer() then
        -- references
        self.slow = kv.slow
    end
end

function modifier_leshrac_lightning_storm_custom:OnRefresh( kv )
    
end

function modifier_leshrac_lightning_storm_custom:OnRemoved()
end

function modifier_leshrac_lightning_storm_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_leshrac_lightning_storm_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACKED,
    }

    return funcs
end

function modifier_leshrac_lightning_storm_custom:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

modifier_leshrac_lightning_storm_custom_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_leshrac_lightning_storm_custom_thinker:IsHidden()
    return true
end

function modifier_leshrac_lightning_storm_custom_thinker:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_leshrac_lightning_storm_custom_thinker:OnCreated( kv )
    if not IsServer() then return end

    -- references
    self.delay = self:GetAbility():GetSpecialValueFor( "jump_delay" )
    self.count = self:GetAbility():GetSpecialValueFor( "jump_count" )
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.duration = self:GetAbility():GetSpecialValueFor( "slow_duration" )
    self.slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" )

    -- init and precache
    self.targets = {}
    self.damageTable = {
        -- victim = target,
        attacker = self:GetCaster(),
        damage = self:GetAbility():GetSpecialValueFor( "damage" ) + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor( "int_to_damage" )/100)),
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(), --Optional.
    }
    -- ApplyDamage(damageTable)
end

function modifier_leshrac_lightning_storm_custom_thinker:Cast( target )
    -- guaranteed on server
    self.current_target = target
    self.started = false
    self:StartIntervalThink( self.delay )
end

function modifier_leshrac_lightning_storm_custom_thinker:OnRefresh( kv )
    
end

function modifier_leshrac_lightning_storm_custom_thinker:OnRemoved()
end

function modifier_leshrac_lightning_storm_custom_thinker:OnDestroy()
    if not IsServer() then return end
    UTIL_Remove( self:GetParent() )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_leshrac_lightning_storm_custom_thinker:OnIntervalThink()
    if not self.started then
        self.started = true

        self:Struck( self.current_target )
        return
    end

    -- find enemies
    local enemies = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(),   -- int, your team number
        self.current_target:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, -- int, flag filter
        FIND_CLOSEST,   -- int, order filter
        false   -- bool, can grow cache
    )

    local found = false
    for _,enemy in pairs(enemies) do
        if not self.targets[enemy] then
            found = true
            self.current_target = enemy
            self:Struck( enemy )
            break
        end
    end

    if not found then
        self:Destroy()
    end
end

--------------------------------------------------------------------------------
-- Helper
function modifier_leshrac_lightning_storm_custom_thinker:Struck( target )
    if not target:IsMagicImmune() then
        -- damage
        self.damageTable.victim = target
        ApplyDamage( self.damageTable )

        -- slow
        target:AddNewModifier(
            self:GetCaster(), -- player source
            self:GetAbility(), -- ability source
            "modifier_leshrac_lightning_storm_custom", -- modifier name
            {
                duration = self.duration,
                slow = self.slow,
            } -- kv
        )

        -- track targeted
        self.targets[target] = true

    end

    -- play effects
    self:PlayEffects( target )

    -- count
    self.count = self.count - 1
    if self.count<=0 then
        self:Destroy()
    end
end


--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_leshrac_lightning_storm_custom_thinker:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_leshrac/leshrac_lightning_bolt.vpcf"
    local sound_cast = "Hero_Leshrac.Lightning_Storm"

    -- get data
    local location = target:GetOrigin()
    local height = Vector( 0, 0, 100 )

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, target )
    ParticleManager:SetParticleControl( effect_cast, 0, location + Vector( 0, 0, 800 ) )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
----------
function modifier_leshrac_lightning_storm_custom_intrin:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_leshrac_lightning_storm_custom_intrin:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    if not parent:HasModifier("modifier_item_aghanims_shard") then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("shard_chance")

    if not RollPercentage(ability, chance) then return end 

    SpellCaster:Cast(ability, target, false)
end