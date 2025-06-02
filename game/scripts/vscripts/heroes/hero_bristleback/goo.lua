bristleback_viscous_nasal_goo_custom = class({})
LinkLuaModifier( "modifier_bristleback_viscous_nasal_goo_custom", "heroes/hero_bristleback/goo", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_bristleback_viscous_nasal_goo_custom_autocast", "heroes/hero_bristleback/goo", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_bristleback_viscous_nasal_goo_custom_autocast = class(ItemBaseClass)

function modifier_bristleback_viscous_nasal_goo_custom_autocast:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self:StartIntervalThink(0.1)
end

function modifier_bristleback_viscous_nasal_goo_custom_autocast:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent() -- Получаем родительский объект
    local ability = self:GetAbility()
    if not parent:IsAlive() and ability:GetAutoCastState() then
        ability:ToggleAutoCast()
    end

    self:StartIntervalThink(-1)
end

function modifier_bristleback_viscous_nasal_goo_custom_autocast:IsHidden()
    return true
end

function modifier_bristleback_viscous_nasal_goo_custom_autocast:RemoveOnDeath()
    return true
end

function modifier_bristleback_viscous_nasal_goo_custom_autocast:OnIntervalThink()
    if self:GetParent():IsChanneling() then return end
    
    if self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() and self:GetAbility():IsCooldownReady() then
        self:GetAbility():CastAbility()
    end
end

function bristleback_viscous_nasal_goo_custom:GetBehavior()
    local behavior = DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        behavior = DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING + DOTA_ABILITY_BEHAVIOR_AUTOCAST
    end
    return behavior
end

--------------------------------------------------------------------------------
-- Ability Start
function bristleback_viscous_nasal_goo_custom:OnSpellStart()
    -- unit identifier
    caster = self:GetCaster()
    target = self:GetCursorTarget()

    -- load data
    local projectile_name = "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf"
    local projectile_speed = self:GetSpecialValueFor("goo_speed")

    local info = {
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
    }
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        -- Find Units in Radius
        local radius = self:GetSpecialValueFor("radius_scepter")
        local enemies = FindUnitsInRadius(
            self:GetCaster():GetTeamNumber(),   -- int, your team number
            self:GetCaster():GetOrigin(),   -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, -- int, flag filter
            0,  -- int, order filter
            false   -- bool, can grow cache
        )

        for _,enemy in pairs(enemies) do
            info.Target = enemy
            ProjectileManager:CreateTrackingProjectile(info)
        end
    else
        info.Target = target
        -- Create Projectile
        ProjectileManager:CreateTrackingProjectile(info)
    end

    self:PlayEffects1()
end

function bristleback_viscous_nasal_goo_custom:OnProjectileHit( hTarget, vLocation )
    -- cancel if got linken
    if hTarget == nil or hTarget:IsInvulnerable() then
        return
    end

    if not self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        if hTarget:TriggerSpellAbsorb( self ) then
            return
        end
    end

    local stack_duration = self:GetSpecialValueFor("goo_duration")

    -- Add modifier
    hTarget:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_bristleback_viscous_nasal_goo_custom", -- modifier name
        { duration = stack_duration } -- kv
    )

    self:PlayEffects2( hTarget )
end

function bristleback_viscous_nasal_goo_custom:PlayEffects1()
    local sound_cast = "Hero_Bristleback.ViscousGoo.Cast"

    EmitSoundOn( sound_cast, self:GetCaster() )
end

function bristleback_viscous_nasal_goo_custom:PlayEffects2( target )
    local sound_cast = "Hero_Bristleback.ViscousGoo.Target"

    EmitSoundOn( sound_cast, target )
end

modifier_bristleback_viscous_nasal_goo_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_bristleback_viscous_nasal_goo_custom:IsHidden()
    return false
end

function modifier_bristleback_viscous_nasal_goo_custom:IsDebuff()
    return true
end

function modifier_bristleback_viscous_nasal_goo_custom:IsStunDebuff()
    return false
end

function modifier_bristleback_viscous_nasal_goo_custom:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_bristleback_viscous_nasal_goo_custom:OnCreated( kv )
    -- references
    self.armor_stack = self:GetAbility():GetSpecialValueFor( "armor_per_stack" )
    self.slow_base = self:GetAbility():GetSpecialValueFor( "base_move_slow" )
    self.slow_stack = self:GetAbility():GetSpecialValueFor( "move_slow_per_stack" )

    if IsServer() then
        self:SetStackCount(1)
    end
end

function modifier_bristleback_viscous_nasal_goo_custom:OnRefresh( kv )
    -- references
    self.armor_stack = self:GetAbility():GetSpecialValueFor( "armor_per_stack" )
    self.slow_base = self:GetAbility():GetSpecialValueFor( "base_move_slow" )
    self.slow_stack = self:GetAbility():GetSpecialValueFor( "move_slow_per_stack" )
    local max_stack = self:GetAbility():GetSpecialValueFor( "stack_limit" )

    if IsServer() then
        if self:GetStackCount()<max_stack then
            self:IncrementStackCount()
        end
    end
end

function modifier_bristleback_viscous_nasal_goo_custom:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_bristleback_viscous_nasal_goo_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end
function modifier_bristleback_viscous_nasal_goo_custom:GetModifierPhysicalArmorBonus()
    return -self.armor_stack * self:GetStackCount()
end
function modifier_bristleback_viscous_nasal_goo_custom:GetModifierMoveSpeedBonus_Percentage()
    return -(self.slow_base + self.slow_stack * self:GetStackCount())
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_bristleback_viscous_nasal_goo_custom:GetEffectName()
    return "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf"
end

function modifier_bristleback_viscous_nasal_goo_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end