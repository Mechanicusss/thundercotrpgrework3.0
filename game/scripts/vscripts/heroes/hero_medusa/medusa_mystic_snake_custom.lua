LinkLuaModifier("modifier_mystic_snake_custom", "heroes/hero_medusa/medusa_mystic_snake_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mystic_snake_custom_petrify_cd", "heroes/hero_medusa/medusa_mystic_snake_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

medusa_mystic_snake_custom = class(ItemBaseClass)
modifier_mystic_snake_custom = class(medusa_mystic_snake_custom)
modifier_mystic_snake_custom_petrify_cd = class(ItemBaseClassDebuff)
-------------
function medusa_mystic_snake_custom:GetIntrinsicModifierName()
    return "modifier_mystic_snake_custom"
end

function modifier_mystic_snake_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }
    return funcs
end

function modifier_mystic_snake_custom:OnAttack(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    -- We don't want split shot to trigger multiple snakes --
    if event.inflictor ~= nil or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if not unit:IsRealHero() or unit:IsIllusion() or (not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim)) then return end

    local ability = self:GetAbility()

    local snake = unit:FindAbilityByName("medusa_mystic_snake_custom")
    if snake ~= nil and snake:GetLevel() > 0 and snake:IsCooldownReady() and (unit:GetMana() >= snake:GetManaCost(-1)) then
        SpellCaster:Cast(snake, victim, true)
    end
end
--------------------------------------------------------------------------------
-- Ability Start
function medusa_mystic_snake_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    -- load data
    local jumps = self:GetSpecialValueFor( "snake_jumps" )
    local radius = self:GetSpecialValueFor( "radius" )
    local base_damage = self:GetSpecialValueFor( "snake_damage" )
    local mult_damage = self:GetSpecialValueFor( "snake_scale" )/100

    local base_stun = 0
    local mult_stun = 0

    local projectile_name = "particles/units/heroes/hero_medusa/medusa_mystic_snake_projectile.vpcf"
    local projectile_speed = self:GetSpecialValueFor( "initial_speed" )
    local projectile_vision = 100

    -- get unique identifier
    local index = self:GetUniqueInt()

    -- create projectile
    local info = {
        Target = target,
        Source = caster,
        Ability = self, 
        
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bDodgeable = false,                           -- Optional
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
    
        bDrawsOnMinimap = false,                          -- Optional
        bVisibleToEnemies = true,                         -- Optional
        bProvidesVision = true,                           -- Optional
        iVisionRadius = projectile_vision,                              -- Optional
        iVisionTeamNumber = caster:GetTeamNumber(),        -- Optional

        ExtraData = {
            index = index,
        }
    }
    ProjectileManager:CreateTrackingProjectile(info)

    -- register projectile
    local data = {}
    data.jump = 0
    data.isReturning = false
    data.hit_units = {}

    data.jumps = jumps
    data.radius = radius
    data.base_damage = base_damage
    data.mult_damage = mult_damage
    data.base_stun = base_stun
    data.mult_stun = mult_stun
    data.projectile_info = info

    self.projectiles[index] = data

    -- play effects
    local sound_cast = "Hero_Medusa.MysticSnake.Cast"
    EmitSoundOn( sound_cast, caster )
end
--------------------------------------------------------------------------------
-- Projectile
medusa_mystic_snake_custom.projectiles = {}
function medusa_mystic_snake_custom:OnProjectileHit_ExtraData( target, location, ExtraData )
    -- load data
    local data = self.projectiles[ ExtraData.index ]

    -- if returning, returns mana
    if data.isReturning then
        self:Returned( data )
        return
    end

    -- if target turns magic immune or invulnerable or somehow there is no target even though it is undisjointable, skip
    if target and (not target:IsMagicImmune()) and (not target:IsInvulnerable()) then
        -- mark as hit
        data.hit_units[target] = true

        -- damage
        local damage_type = self:GetAbilityDamageType()

        local damage = (data.base_damage + data.base_damage * data.mult_damage * data.jump) + (self:GetCaster():GetAgility() * (self:GetSpecialValueFor("agility_damage")/100))
        local damageTable = {
            victim = target,
            attacker = self:GetCaster(),
            damage = damage,
            damage_type = damage_type,
            ability = self, --Optional.
        }
        ApplyDamage(damageTable)

        -- take mana
        -- play effects
        local sound_cast = "Hero_Medusa.MysticSnake.Target"
        EmitSoundOn( sound_cast, target )

        if not self:GetCaster():HasModifier("modifier_mystic_snake_custom_petrify_cd") then
            local gaze = self:GetCaster():FindAbilityByName("medusa_stone_gaze_custom")
            if gaze ~= nil and gaze:GetLevel() > 0 then
                if not target:HasModifier("modifier_medusa_stone_gaze_custom_stone") then
                    local slow = target:AddNewModifier(self:GetCaster(), gaze, "modifier_medusa_stone_gaze_custom_stone", {
                        duration = gaze:GetSpecialValueFor("stone_duration")
                    })
                    EmitSoundOn("Hero_Medusa.StoneGaze.Stun", target)
                end
            end
        end

        -- counter
        data.jump = data.jump + 1
        if data.jump>=data.jumps then
            self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_mystic_snake_custom_petrify_cd", {
                duration = self:GetSpecialValueFor("stone_form_scepter_cd")
            })
            -- return projectile with target
            self:Returning( data, target )
            return
        end
    end

    -- jump to nearby target
    local pos = location
    if target then
        pos = target:GetOrigin()
    end

    local enemies = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(),   -- int, your team number
        pos,    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        data.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        FIND_CLOSEST,   -- int, order filter
        false   -- bool, can grow cache
    )

    -- pick next target
    local next_target = nil
    for _,enemy in pairs(enemies) do

        -- check if it is already hit
        local found = false
        for unit,_ in pairs(data.hit_units) do
            if enemy==unit then
                found = true
                break
            end
        end

        if not found then
            next_target = enemy
            break
        end
    end

    -- not found
    if not next_target then
        -- return projectile without target
        self:Returning( data, target )
        return
    end

    -- create bounce projectile
    data.projectile_info.Target = next_target
    data.projectile_info.Source = target
    ProjectileManager:CreateTrackingProjectile( data.projectile_info )
end

function medusa_mystic_snake_custom:Returning( data, target )
    if not target then
        self:Returned( data )
        return
    end

    -- set returning
    data.isReturning = true

    -- create projectile
    local projectile_name = "particles/units/heroes/hero_medusa/medusa_mystic_snake_projectile_return.vpcf"
    data.projectile_info.Target = self:GetCaster()
    data.projectile_info.Source = target
    data.projectile_info.EffectName = projectile_name
    ProjectileManager:CreateTrackingProjectile( data.projectile_info )
end

function medusa_mystic_snake_custom:Returned( data )
    -- unregister projectile
    local index = data.projectile_info.ExtraData.index
    self.projectiles[ index ] = nil
    self:DelUniqueInt( index )

    -- only do things if alive
    if not self:GetCaster():IsAlive() then return end

    -- give mana
    -- play effects
    local sound_cast = "Hero_Medusa.MysticSnake.Return"
    EmitSoundOn( sound_cast, self:GetCaster() )
end

--------------------------------------------------------------------------------
-- Helper

-- Obtain unique integer for projectile identifier
medusa_mystic_snake_custom.unique = {}
medusa_mystic_snake_custom.i = 0
medusa_mystic_snake_custom.max = 65536
function medusa_mystic_snake_custom:GetUniqueInt()
    while self.unique[ self.i ] do
        self.i = self.i + 1
        if self.i==self.max then self.i = 0 end
    end

    self.unique[ self.i ] = true
    return self.i
end
function medusa_mystic_snake_custom:DelUniqueInt( i )
    self.unique[ i ] = nil
end