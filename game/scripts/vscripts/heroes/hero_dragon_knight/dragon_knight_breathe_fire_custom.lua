dragon_knight_breathe_fire_custom = class({})
LinkLuaModifier( "modifier_dragon_knight_breathe_fire_custom", "heroes/hero_dragon_knight/dragon_knight_breathe_fire_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_dragon_knight_breathe_fire_custom_self", "heroes/hero_dragon_knight/dragon_knight_breathe_fire_custom", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_dragon_knight_breathe_fire_custom_self = class(ItemBaseClass)
--------------------------------------------------------------------------------
-- Ability Start
function dragon_knight_breathe_fire_custom:GetCooldown(level)
    local ab = self:GetCaster():FindAbilityByName("special_bonus_unique_dragon_knight_4_custom")
    if ab ~= nil and ab:GetLevel() > 0 then
        return self.BaseClass.GetCooldown(self, level) - ab:GetSpecialValueFor("value")
    end

    return self.BaseClass.GetCooldown(self, level) or 0
end

function dragon_knight_breathe_fire_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local point = self:GetCursorPosition()

    -- unit target just indicates point
    if target then point = target:GetOrigin() end

    local value1 = self:GetSpecialValueFor("some_value")
    
    -- load projectile
    local projectile_name = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf"
    local projectile_distance = self:GetSpecialValueFor( "range" )
    local projectile_start_radius = self:GetSpecialValueFor( "start_radius" )
    local projectile_end_radius = self:GetSpecialValueFor( "end_radius" )
    local projectile_speed = self:GetSpecialValueFor( "speed" )
    local projectile_direction = point - caster:GetOrigin()
    projectile_direction.z = 0
    projectile_direction = projectile_direction:Normalized()

    -- create projectile
    local info = {
        Source = caster,
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin(),
        
        bDeleteOnHit = false,
        
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        
        EffectName = projectile_name,
        fDistance = projectile_distance,
        fStartRadius = projectile_start_radius,
        fEndRadius =projectile_end_radius,
        vVelocity = projectile_direction * projectile_speed,
        }
    ProjectileManager:CreateLinearProjectile(info)

    -- play effects
    local sound_cast = "Hero_DragonKnight.BreathFire"
    EmitSoundOn( sound_cast, caster )
end

function dragon_knight_breathe_fire_custom:GetIntrinsicModifierName()
    return "modifier_dragon_knight_breathe_fire_custom_self"
end

function modifier_dragon_knight_breathe_fire_custom_self:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_dragon_knight_breathe_fire_custom_self:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end

    local ability = self:GetAbility()

    if not parent:HasModifier("modifier_item_aghanims_shard") or not RollPercentage(ability:GetSpecialValueFor("chance")) or not ability:IsCooldownReady() or ability:GetManaCost(-1) > parent:GetMana() or parent:IsSilenced() then return end

    SpellCaster:Cast(ability, event.target, true)
end
--------------------------------------------------------------------------------
-- Projectile
function dragon_knight_breathe_fire_custom:OnProjectileHit( target, location )
    if not target then return end

    -- load data
    local damage = self:GetAbilityDamage() + (self:GetCaster():GetStrength()*(self:GetSpecialValueFor("str_to_damage")/100))
    local duration = self:GetSpecialValueFor( "duration" )

    -- damage
    local damageTable = {
        victim = target,
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }
    ApplyDamage(damageTable)

    -- debuff
    target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_dragon_knight_breathe_fire_custom", -- modifier name
        { duration = duration } -- kv
    )
end

modifier_dragon_knight_breathe_fire_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_dragon_knight_breathe_fire_custom:IsHidden()
    return false
end

function modifier_dragon_knight_breathe_fire_custom:IsDebuff()
    return true
end

function modifier_dragon_knight_breathe_fire_custom:IsStunDebuff()
    return false
end

function modifier_dragon_knight_breathe_fire_custom:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_dragon_knight_breathe_fire_custom:OnCreated( kv )
    -- references
    self.reduction = self:GetAbility():GetSpecialValueFor( "reduction" )
end

function modifier_dragon_knight_breathe_fire_custom:OnRefresh( kv )
    -- references
    self.reduction = self:GetAbility():GetSpecialValueFor( "reduction" )    
end

function modifier_dragon_knight_breathe_fire_custom:OnRemoved()
end

function modifier_dragon_knight_breathe_fire_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_dragon_knight_breathe_fire_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
    }

    return funcs
end

function modifier_dragon_knight_breathe_fire_custom:GetModifierDamageOutgoing_Percentage()
    return self.reduction
end