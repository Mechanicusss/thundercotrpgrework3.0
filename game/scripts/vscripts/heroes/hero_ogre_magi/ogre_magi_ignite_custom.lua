ogre_magi_ignite_custom = class({})
LinkLuaModifier( "modifier_ogre_magi_ignite_custom", "heroes/hero_ogre_magi/ogre_magi_ignite_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function ogre_magi_ignite_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    -- load data
    local projectile_name = "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite.vpcf"
    local projectile_speed = self:GetSpecialValueFor( "projectile_speed" )

    -- create projectile
    local info = {
        Target = target,
        Source = caster,
        Ability = self, 
        
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bDodgeable = true,                           -- Optional
    }
    ProjectileManager:CreateTrackingProjectile(info)

    -- find secondary target
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(), -- int, your team number
        caster:GetOrigin(), -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self:GetCastRange( target:GetOrigin(), target ),    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    local target_2 = nil
    for _,enemy in pairs(enemies) do
        -- only target those who does not have debuff
        if enemy~=target and ( not enemy:HasModifier("modifier_ogre_magi_ignite_custom") ) then
            target_2 = enemy
            break
        end
    end

    -- create secondary projectile
    if target_2 then
        info.Target = target_2
        ProjectileManager:CreateTrackingProjectile(info)
    end

    -- play effects
    local sound_cast = "Hero_OgreMagi.Ignite.Cast"
    EmitSoundOn( sound_cast, caster )
end

--------------------------------------------------------------------------------
-- Projectile
function ogre_magi_ignite_custom:OnProjectileHit( target, location )
    if not target then return end

    -- cancel if linken
    if target:TriggerSpellAbsorb(self) then return end

    local victims = FindUnitsInRadius(target:GetTeam(), target:GetAbsOrigin(), nil,
            150, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        -- load data
        local duration = self:GetSpecialValueFor("duration")

        -- add debuff
        local debuff = victim:FindModifierByName("modifier_ogre_magi_ignite_custom")
        if not debuff then
            debuff = victim:AddNewModifier(
                self:GetCaster(), -- player source
                self, -- ability source
                "modifier_ogre_magi_ignite_custom", -- modifier name
                { duration = duration } -- kv
            )
        end

        if debuff then
            if debuff:GetStackCount() < self:GetSpecialValueFor("max_stacks") then
                debuff:IncrementStackCount()
            end
            debuff:ForceRefresh()
        end
    end

    -- play effects
    local sound_cast = "Hero_OgreMagi.Ignite.Target"
    EmitSoundOn( sound_cast, self:GetCaster() )
end

modifier_ogre_magi_ignite_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ogre_magi_ignite_custom:IsHidden()
    return false
end

function modifier_ogre_magi_ignite_custom:IsDebuff()
    return true
end

function modifier_ogre_magi_ignite_custom:IsStunDebuff()
    return false
end

function modifier_ogre_magi_ignite_custom:IsPurgable()
    return true
end

function modifier_ogre_magi_ignite_custom:IsStackable()
    return true
end

function modifier_ogre_magi_ignite_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_ogre_magi_ignite_custom:OnCreated( kv )
    -- references
    self.slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed_pct" )

    if not IsServer() then return end

    local interval = 0.5

    -- precache damage
    self.damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(), --Optional.
    }
    -- ApplyDamage(damageTable)

    -- Start interval
    self:StartIntervalThink( interval )
end

function modifier_ogre_magi_ignite_custom:OnRefresh( kv )
    -- references
    self.slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed_pct" )
    local damage = self:GetAbility():GetSpecialValueFor( "burn_damage" ) + (self:GetCaster():GetBaseIntellect()*(self:GetAbility():GetSpecialValueFor("int_to_damage")/100))
    
    
    if not IsServer() then return end
    -- update damage
    self.damageTable.damage = damage * self:GetStackCount() * 0.5
end

function modifier_ogre_magi_ignite_custom:OnRemoved()
end

function modifier_ogre_magi_ignite_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ogre_magi_ignite_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP,

    }

    return funcs
end

function modifier_ogre_magi_ignite_custom:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

function modifier_ogre_magi_ignite_custom:OnTooltip()
    return (self:GetAbility():GetSpecialValueFor("burn_damage")+((self:GetCaster():GetBaseIntellect()*(self:GetAbility():GetSpecialValueFor("int_to_damage")/100))))*self:GetStackCount()
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ogre_magi_ignite_custom:OnIntervalThink()
    local damage = self:GetAbility():GetSpecialValueFor( "burn_damage" ) + (self:GetCaster():GetBaseIntellect()*(self:GetAbility():GetSpecialValueFor("int_to_damage")/100))
    self.damageTable.damage = damage * self:GetStackCount() * 0.5,
    -- apply damage
    ApplyDamage( self.damageTable )

    -- play effects
    local sound_cast = "Hero_OgreMagi.Ignite.Damage"
    EmitSoundOn( sound_cast, self:GetParent() )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ogre_magi_ignite_custom:GetEffectName()
    return "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf"
end

function modifier_ogre_magi_ignite_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end