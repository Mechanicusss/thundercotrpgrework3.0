lich_chain_frost_custom = class({})
LinkLuaModifier( "modifier_lich_chain_frost_custom", "heroes/hero_lich/lich_chain_frost_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lich_chain_frost_custom_thinker", "heroes/hero_lich/lich_chain_frost_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_tracking_projectile", "modifiers/modifier_generic_tracking_projectile", LUA_MODIFIER_MOTION_NONE )
local tempTable = require( "libraries/tempTable" )

--------------------------------------------------------------------------------
-- Ability Start
function lich_chain_frost_custom:CastFilterResultTarget(target)
    if target:GetTeamNumber() == self:GetCaster():GetTeamNumber() and target:GetUnitName() ~= "npc_dota_lich_ice_spire_custom" then
       return UF_FAIL_OTHER
    end

    if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() and (target:IsCreep() or target:IsHero() or target:IsCreepHero() or target:IsNeutralUnitType()) then
        return UF_SUCCESS
    end
end

function lich_chain_frost_custom:OnSpellStart()
    if not IsServer() then return end

    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    -- load data
    local damage = self:GetSpecialValueFor("damage") + (self:GetCaster():GetBaseIntellect() * (self:GetSpecialValueFor("int_to_damage")/100))

    -- store data
    local castTable = {
        damage = damage,
        jump = 0,
        jumps = self:GetSpecialValueFor("jumps"),
        jump_range = self:GetSpecialValueFor("jump_range"),
        as_slow = self:GetSpecialValueFor("slow_attack_speed"),
        ms_slow = self:GetSpecialValueFor("slow_movement_speed"),
        slow_duration = self:GetSpecialValueFor("slow_duration"),
    }
    local key = tempTable:AddATValue( castTable )

    -- load projectile
    local projectile_name = "particles/units/heroes/hero_lich/lich_chain_frost.vpcf"
    local projectile_speed = self:GetSpecialValueFor("projectile_speed")
    if caster:HasTalent("special_bonus_unique_lich_3_custom") then
        projectile_speed = projectile_speed + caster:FindAbilityByName("special_bonus_unique_lich_3_custom"):GetSpecialValueFor("value")
    end

    local projectile_vision = self:GetSpecialValueFor("vision_radius")

    local projectile_info = {
        Target = target,
        Source = caster,
        Ability = self, 
        
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bDodgeable = false,                           -- Optional
    
        bVisibleToEnemies = true,                         -- Optional
        bProvidesVision = true,                           -- Optional
        iVisionRadius = projectile_vision,                              -- Optional
        iVisionTeamNumber = caster:GetTeamNumber(),        -- Optional
        ExtraData = {
            key = key,
        }
    }
    projectile_info = self:PlayProjectile( projectile_info )
    castTable.projectile = projectile_info
    ProjectileManager:CreateTrackingProjectile( castTable.projectile )

    -- play effects
    local sound_cast = "Hero_Lich.ChainFrost"
    EmitSoundOn( sound_cast, caster )
end

--------------------------------------------------------------------------------
-- Projectile
function lich_chain_frost_custom:OnProjectileHit_ExtraData( target, location, kv )
    self:StopProjectile( kv )

    -- load data
    local bounce_delay = 0.2
    local castTable = tempTable:GetATValue( kv.key )

    -- bounce thinker
    target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_lich_chain_frost_custom_thinker", -- modifier name
        {
            key = kv.key,
            duration = bounce_delay,
        } -- kv
    )

    -- apply damage and slow
    if (not target:IsMagicImmune()) and (not target:IsInvulnerable()) then
        local damageTable = {
            victim = target,
            attacker = self:GetCaster(),
            damage = castTable.damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self, --Optional.
        }

        ApplyDamage(damageTable)

        target:AddNewModifier(
            self:GetCaster(), -- player source
            self, -- ability source
            "modifier_lich_chain_frost_custom", -- modifier name
            {
                duration = castTable.slow_duration,
                as_slow = castTable.as_slow,
                ms_slow = castTable.ms_slow,
            } -- kv
        )
    end

    -- play effects
    local sound_target = "Hero_Lich.ChainFrostImpact.Creep"
    if target:IsConsideredHero() then
        sound_target = "Hero_Lich.ChainFrostImpact.Hero"
    end
    EmitSoundOn( sound_target, target )
end

--------------------------------------------------------------------------------
-- Graphics & Effects
function lich_chain_frost_custom:PlayProjectile( info )
    local tracker = info.Target:AddNewModifier(
        info.Source, -- player source
        self, -- ability source
        "modifier_generic_tracking_projectile", -- modifier name
        { duration = 4 } -- kv
    )
    tracker:PlayTrackingProjectile( info )
    
    info.EffectName = nil
    if not info.ExtraData then info.ExtraData = {} end
    info.ExtraData.tracker = tempTable:AddATValue( tracker )

    return info
end

function lich_chain_frost_custom:StopProjectile( kv )
    local tracker = tempTable:RetATValue( kv.tracker )
    if tracker and not tracker:IsNull() then tracker:Destroy() end
end

modifier_lich_chain_frost_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_lich_chain_frost_custom:IsHidden()
    return false
end

function modifier_lich_chain_frost_custom:IsDebuff()
    return true
end

function modifier_lich_chain_frost_custom:IsStunDebuff()
    return false
end

function modifier_lich_chain_frost_custom:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_lich_chain_frost_custom:OnCreated( kv )
    -- references
    self.as_slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed" ) -- special value
    self.ms_slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" ) -- special value
end

function modifier_lich_chain_frost_custom:OnRefresh( kv )
    -- references
    self.as_slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed" ) -- special value
    self.ms_slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" ) -- special value   
end

function modifier_lich_chain_frost_custom:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_lich_chain_frost_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }

    return funcs
end
function modifier_lich_chain_frost_custom:GetModifierMoveSpeedBonus_Percentage()
    return self.ms_slow
end
function modifier_lich_chain_frost_custom:GetModifierAttackSpeedBonus_Constant()
    return self.as_slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_lich_chain_frost_custom:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end

modifier_lich_chain_frost_custom_thinker = class({})
local tempTable = require( "libraries/tempTable" )

--------------------------------------------------------------------------------
-- Classifications
function modifier_lich_chain_frost_custom_thinker:IsHidden()
    return false
end

function modifier_lich_chain_frost_custom_thinker:IsPurgable()
    return false
end

function modifier_lich_chain_frost_custom_thinker:RemoveOnDeath()
    return false
end

function modifier_lich_chain_frost_custom_thinker:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_lich_chain_frost_custom_thinker:OnCreated( kv )
    if IsServer() then
        self.key = kv.key
    end
end

function modifier_lich_chain_frost_custom_thinker:OnRefresh( kv )
    
end

function modifier_lich_chain_frost_custom_thinker:OnDestroy( kv )
    if IsServer() then
        local castTable = tempTable:GetATValue( self.key )

        -- update values
        if self:GetParent():GetUnitName() ~= "npc_dota_lich_ice_spire_custom" then
            castTable.jump = castTable.jump + 1

            if self:GetCaster():HasScepter() then
                local damageIncrease = castTable.damage * (1 + (self:GetAbility():GetSpecialValueFor("damage_increase_per_spire_jump")/100))
                castTable.damage = damageIncrease
            end
        end

        if castTable.jump>castTable.jumps then
            -- stop bouncing
            castTable = tempTable:RetATValue( self.key )
            return
        end

        -- add temporary FOV
        AddFOWViewer( castTable.projectile.iVisionTeamNumber, self:GetParent():GetOrigin(), castTable.projectile.iVisionRadius, 0.3, false)

        -- find enemies
        local enemies = FindUnitsInRadius(
            self:GetCaster():GetTeamNumber(),   -- int, your team number
            self:GetParent():GetOrigin(),   -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            castTable.jump_range,   -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_BOTH,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            0,  -- int, flag filter
            0,  -- int, order filter
            false   -- bool, can grow cache
        )

        -- get random enemy
        local target = nil
        for _,enemy in pairs(enemies) do
            local pass = true

            if enemy:GetTeamNumber() == self:GetCaster():GetTeamNumber() and enemy:GetUnitName() ~= "npc_dota_lich_ice_spire_custom" then pass = false end
            if not self:GetCaster():CanEntityBeSeenByMyTeam(enemy) then pass = false end

            if enemy~=self:GetParent() and pass then
                target = enemy
                break
            end
        end

        if not target then
            -- stop bouncing
            castTable = tempTable:RetATValue( self.key )
            return
        end

        -- bounce to enemy
        castTable.projectile.Target = target
        castTable.projectile.Source = self:GetParent()
        castTable.projectile.EffectName = "particles/units/heroes/hero_lich/lich_chain_frost.vpcf"
        
        castTable.projectile = self:PlayProjectile( castTable.projectile )
        ProjectileManager:CreateTrackingProjectile( castTable.projectile )
    end
end

--------------------------------------------------------------------------------
-- Graphics & Effects
function modifier_lich_chain_frost_custom_thinker:PlayProjectile( info )
    local tracker = info.Target:AddNewModifier(
        info.Source, -- player source
        self:GetAbility(), -- ability source
        "modifier_generic_tracking_projectile", -- modifier name
        { duration = 4 } -- kv
    )
    local effect_cast = tracker:PlayTrackingProjectile( info )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        info.Source,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    info.EffectName = nil
    if not info.ExtraData then info.ExtraData = {} end
    info.ExtraData.tracker = tempTable:AddATValue( tracker )

    return info
end