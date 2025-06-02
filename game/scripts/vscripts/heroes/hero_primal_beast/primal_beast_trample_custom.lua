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

primal_beast_trample_custom = class({})
LinkLuaModifier( "modifier_primal_beast_trample_custom", "heroes/hero_primal_beast/primal_beast_trample_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_primal_beast_trample_custom_talent_debuff", "heroes/hero_primal_beast/primal_beast_trample_custom", LUA_MODIFIER_MOTION_NONE )

modifier_primal_beast_trample_custom_talent_debuff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})
--------------------------------------------------------------------------------
-- Init Abilities
function primal_beast_trample_custom:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_primal_beast.vsndevts", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_primal_beast/primal_beast_trample.vpcf", context )
end

--------------------------------------------------------------------------------
-- Ability Start
function primal_beast_trample_custom:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self

    if self:GetToggleState() then
        caster:AddNewModifier(
            caster, -- player source
            self, -- ability source
            "modifier_primal_beast_trample_custom", -- modifier name
            {} -- kv
        )
    else
        caster:RemoveModifierByNameAndCaster("modifier_primal_beast_trample_custom", caster)
    end
end
--------------------------------------------------------------------------------
modifier_primal_beast_trample_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_primal_beast_trample_custom:IsHidden()
    return false
end

function modifier_primal_beast_trample_custom:IsDebuff()
    return false
end

function modifier_primal_beast_trample_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_primal_beast_trample_custom:OnCreated( kv )
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "effect_radius" )
    self.step_distance = self:GetAbility():GetSpecialValueFor( "step_distance" )
    self.base_damage = self:GetAbility():GetSpecialValueFor( "base_damage" )
    self.attack_damage = self:GetAbility():GetSpecialValueFor( "attack_damage" )/100
    self.strength_multiplier = self:GetAbility():GetSpecialValueFor( "strength_multiplier" )/100

    if not IsServer() then return end

    -- ability properties
    self.abilityDamageType = self:GetAbility():GetAbilityDamageType()

    self.talent = self.parent:FindAbilityByName("talent_primal_beast_2")
    if self.talent ~= nil and self.talent:GetLevel() > 0 then
        self.abilityDamageType = DAMAGE_TYPE_PHYSICAL
    end

    -- init data
    self.distance = 0
    self.treshold = 500
    self.currentpos = self.parent:GetOrigin()

    self.hasResetForTalent = 0

    local interval = 0.1

    if self.talent ~= nil and self.talent:GetLevel() > 1 then
        interval = self.talent:GetSpecialValueFor("trample_interval")
    end

    -- Start interval
    self:StartIntervalThink( interval )

    -- Trample
    self:Trample()
end

function modifier_primal_beast_trample_custom:OnRefresh( kv )
    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "effect_radius" )
    self.distance = self:GetAbility():GetSpecialValueFor( "step_distance" )
    self.base_damage = self:GetAbility():GetSpecialValueFor( "base_damage" )
    self.attack_damage = self:GetAbility():GetSpecialValueFor( "attack_damage" )/100
    self.strength_multiplier = self:GetAbility():GetSpecialValueFor( "strength_multiplier" )/100
    
end

function modifier_primal_beast_trample_custom:OnRemoved()
end

function modifier_primal_beast_trample_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_primal_beast_trample_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
    }

    return funcs
end

function modifier_primal_beast_trample_custom:GetActivityTranslationModifiers()
    if self.talent ~= nil and self.talent:GetLevel() > 1 then
        return
    end
    return "heavy_steps"
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_primal_beast_trample_custom:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }

    if self.talent ~= nil and self.talent:GetLevel() > 0 then
        state[MODIFIER_STATE_DISARMED] = false
    end

    return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_primal_beast_trample_custom:OnIntervalThink()
    local pos = self.parent:GetOrigin()
    local dist = (pos-self.currentpos):Length2D()
    self.currentpos = pos

    -- destroy trees
    GridNav:DestroyTreesAroundPoint( pos, self.radius, false )

    if self.talent ~= nil and self.talent:GetLevel() > 1 and not self.parent:IsMoving() then
        self:Trample()
        return
    end

    if self.talent == nil or (self.talent ~= nil and self.talent:GetLevel() < 2) then
        -- ignore if moving too fast, like blink
        if dist>self.treshold then return end

        self.distance = self.distance + dist
        if self.distance > self.step_distance then
            self:Trample()
            self.distance = 0
        end
    end
end

--------------------------------------------------------------------------------
-- Helper
function modifier_primal_beast_trample_custom:Trample()
    local pos = self.parent:GetOrigin()
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),    -- int, your team number
        pos,    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    -- precache damage
    local damage = self.base_damage + self.parent:GetAverageTrueAttackDamage(self.parent)*self.attack_damage + (self.parent:GetStrength()*self.strength_multiplier)
    local damageTable = {
        -- victim = target,
        attacker = self.parent,
        damage = damage,
        damage_type = self.abilityDamageType,
        ability = self.ability, --Optional.
    }

    local maxEnemies = 4
    local i = 0

    for _,enemy in pairs(enemies) do
        damageTable.victim = enemy
        ApplyDamage(damageTable)

        if self.talent ~= nil and self.talent:GetLevel() > 0 then
            if self.talent:GetLevel() > 2 then
                enemy:AddNewModifier(self.parent, self:GetAbility(), "modifier_primal_beast_trample_custom_talent_debuff", {
                    duration = self.talent:GetSpecialValueFor("debuff_duration")
                })
            end

            if i < maxEnemies then
                self.parent:PerformAttack(
                    enemy,
                    true,
                    true,
                    true,
                    false,
                    false,
                    false,
                    true
                )
            end

            i = i + 1
        end

        SendOverheadEventMessage(
            nil,
            OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
            enemy,
            damage,
            nil
        )
    end

    self:PlayEffects()

    -- Scepter 
    if not self.parent:HasScepter() then return end
    if not RollPercentage(self:GetAbility():GetSpecialValueFor("chance")) then return end

    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),    -- int, your team number
        pos,    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self:GetAbility():GetSpecialValueFor("search_radius"),    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    local maxTargets = self:GetAbility():GetSpecialValueFor("max_split_targets")
    local i = 0

    for _,enemy in ipairs(enemies) do
        if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() then
            if i < maxTargets then
                local spawnOrigin = self.parent:GetAbsOrigin()
                local point = enemy:GetAbsOrigin()
                local collision_radius = 225
                local vision_distance = 300
                local travel_speed = 1222
                local distance = (point - spawnOrigin):Length2D()
                local direction = (point - spawnOrigin):Normalized()
                local velocity = direction * travel_speed

                local projectile =  {
                    EffectName          = "particles/units/heroes/hero_primal_beast/primal_beast_rock_throw.vpcf",
                    Ability             = self:GetAbility(),
                    vSpawnOrigin        = spawnOrigin,
                    fDistance           = distance,
                    fStartRadius        = collision_radius,
                    fEndRadius          = collision_radius,
                    Source              = self.parent,
                    bProvidesVision     = true,
                    iVisionTeamNumber   = self.parent:GetTeam(),
                    iVisionRadius       = vision_distance,
                    bDrawsOnMinimap     = false,
                    bVisibleToEnemies   = true, 
                    iUnitTargetTeam     = DOTA_UNIT_TARGET_TEAM_ENEMY,
                    iUnitTargetFlags    = DOTA_UNIT_TARGET_FLAG_NONE,
                    iUnitTargetType     = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                    vVelocity           = velocity,
                    iMoveSpeed = travel_speed,
                    Target = enemy,
                    ExtraData = {
                        split = 0
                    }
                }               

                ProjectileManager:CreateTrackingProjectile(projectile)

                EmitSoundOn("Hero_PrimalBeast.RockThrow.Projectile", hTarget)
            else
                return
            end

            i = i + 1
        end
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_primal_beast_trample_custom:GetEffectName()
    if self.talent ~= nil and self.talent:GetLevel() > 0 then
        return
    end

    return "particles/units/heroes/hero_primal_beast/primal_beast_disarm.vpcf"
end

function modifier_primal_beast_trample_custom:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_primal_beast_trample_custom:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_primal_beast/primal_beast_trample.vpcf"
    local sound_cast = "Hero_PrimalBeast.Trample"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, self.parent )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )

    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self.parent )
end
--------
function primal_beast_trample_custom:OnProjectileHit_ExtraData(hTarget, hLoc, extraData)
    if not hTarget then return end

    local caster = self:GetCaster()

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_primal_beast/primal_beast_rock_throw_impact.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, hTarget:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 3, hTarget:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_PrimalBeast.RockThrow.Impact", hTarget)

    local damage = caster:GetStrength() * (self:GetSpecialValueFor("rock_strength_damage")/100)
    if extraData.split == 1 then
        damage = damage * (self:GetSpecialValueFor("split_damage_pct")/100)
    end

    ApplyDamage({
        attacker = caster,
        victim = hTarget,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
    })

    if extraData.split == 1 then return end

    local maxTargets = self:GetSpecialValueFor("max_split_targets")
    local i = 0

    local victims = FindUnitsInRadius(caster:GetTeam(), hTarget:GetAbsOrigin(), nil,
            self:GetSpecialValueFor("split_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and enemy ~= hTarget then
            if i < maxTargets then
                local spawnOrigin = hTarget:GetAbsOrigin()
                local point = enemy:GetAbsOrigin()
                local collision_radius = 225
                local vision_distance = 300
                local travel_speed = 1058
                local distance = (point - spawnOrigin):Length2D()
                local direction = (point - spawnOrigin):Normalized()
                local velocity = direction * travel_speed

                local projectile =  {
                    EffectName          = "particles/units/heroes/hero_primal_beast/primal_beast_rock_throw_arc.vpcf",
                    Ability             = self,
                    vSpawnOrigin        = spawnOrigin,
                    fDistance           = distance,
                    fStartRadius        = collision_radius,
                    fEndRadius          = collision_radius,
                    Source              = hTarget,
                    bProvidesVision     = true,
                    iVisionTeamNumber   = caster:GetTeam(),
                    iVisionRadius       = vision_distance,
                    bDrawsOnMinimap     = false,
                    bVisibleToEnemies   = true, 
                    iUnitTargetTeam     = DOTA_UNIT_TARGET_TEAM_ENEMY,
                    iUnitTargetFlags    = DOTA_UNIT_TARGET_FLAG_NONE,
                    iUnitTargetType     = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                    vVelocity           = velocity,
                    iMoveSpeed = travel_speed,
                    Target = enemy,
                    ExtraData = {
                        split = 1
                    }
                }               

                ProjectileManager:CreateTrackingProjectile(projectile)

                EmitSoundOn("Hero_PrimalBeast.RockThrow.Projectile", hTarget)
            else
                return
            end

            i = i + 1
        end
    end
end
----------------
function modifier_primal_beast_trample_custom_talent_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_primal_beast_trample_custom_talent_debuff:GetModifierPhysicalArmorBonus()
    local talent = self:GetCaster():FindAbilityByName("talent_primal_beast_2")
    if talent ~= nil and talent:GetLevel() > 1 then
        return self:GetParent():GetPhysicalArmorBaseValue() * (talent:GetSpecialValueFor("armor_debuff_pct")/100)
    end
end