doom_eternal_fire = class({})
modifier_doom_eternal_fire_thinker = class({})
modifier_doom_eternal_fire_damage_thinker = class({})

LinkLuaModifier( "modifier_doom_eternal_fire", "heroes/hero_doom/doom_eternal_fire", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_doom_eternal_fire_thinker", "heroes/hero_doom/doom_eternal_fire", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_doom_eternal_fire_damage_thinker", "heroes/hero_doom/doom_eternal_fire", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function doom_eternal_fire:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local point = self:GetCursorPosition()

    caster:AddNewModifier(caster, self, "modifier_doom_eternal_fire_thinker", {
        duration = self:GetSpecialValueFor("active_duration")
    })

    if caster:GetUnitName() == "npc_dota_doom_infernal_servant" then return end

    local existingGolems = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,existingGolem in ipairs(existingGolems) do
        if existingGolem:GetUnitName() == "npc_dota_doom_infernal_servant" then
            local golemFlames = existingGolem:FindAbilityByName("doom_eternal_fire")
            if golemFlames ~= nil and golemFlames:GetLevel() > 0 then
                golemFlames:OnSpellStart()
            end
        end
    end

end

function doom_eternal_fire:GetBehavior()
    if self:GetCaster():GetUnitName() == "npc_dota_doom_infernal_servant" then
        return DOTA_ABILITY_BEHAVIOR_PASSIVE
    end

    return bit.bor(DOTA_ABILITY_BEHAVIOR_NO_TARGET, DOTA_ABILITY_BEHAVIOR_IMMEDIATE)
end

function doom_eternal_fire:GetManaCost()
    if self:GetCaster():GetUnitName() == "npc_dota_doom_infernal_servant" then return 0 end

    return self.BaseClass.GetManaCost(self, -1) or 0
end
--------------------------------------------------------------------------------
-- Projectile
function doom_eternal_fire:OnProjectileHit( target, location )
    if not target then return end

    -- load data
    local strength = 0

    if self:GetCaster():GetUnitName() == "npc_dota_doom_infernal_servant" then
        strength = self:GetCaster():GetOwner():GetStrength()
    else
        strength = self:GetCaster():GetStrength()
    end

    local damage = self:GetSpecialValueFor("damage") + (strength * (self:GetSpecialValueFor("strength_to_damage")/100))
    local duration = self:GetSpecialValueFor( "duration" )

    local damageSource = self:GetCaster()
    if damageSource:GetUnitName() == "npc_dota_doom_infernal_servant" then
        damageSource = damageSource:GetOwner()
    end

    -- damage
    local damageTable = {
        victim = target,
        attacker = damageSource,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }
    ApplyDamage(damageTable)

    -- debuff
    target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_doom_eternal_fire", -- modifier name
        { duration = duration } -- kv
    )

    target:AddNewModifier(
        self:GetCaster(),
        self,
        "modifier_doom_eternal_fire_damage_thinker",
        { duration = duration }
    )
end

modifier_doom_eternal_fire = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_doom_eternal_fire:IsHidden()
    return false
end

function modifier_doom_eternal_fire:IsDebuff()
    return true
end

function modifier_doom_eternal_fire:IsStunDebuff()
    return false
end

function modifier_doom_eternal_fire:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_doom_eternal_fire:OnCreated( kv )
    -- references
    self.reduction = self:GetAbility():GetSpecialValueFor( "reduction" )
end

function modifier_doom_eternal_fire:OnRefresh( kv )
    -- references
    self.reduction = self:GetAbility():GetSpecialValueFor( "reduction" )    
end

function modifier_doom_eternal_fire:OnRemoved()
end

function modifier_doom_eternal_fire:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_doom_eternal_fire:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
    }

    return funcs
end

function modifier_doom_eternal_fire:GetModifierDamageOutgoing_Percentage()
    return self.reduction
end
---------
--
function modifier_doom_eternal_fire_thinker:IsHidden()
    return false
end

function modifier_doom_eternal_fire_thinker:IsDebuff()
    return false
end

function modifier_doom_eternal_fire_thinker:IsStunDebuff()
    return false
end

function modifier_doom_eternal_fire_thinker:IsPurgable()
    return true
end

function modifier_doom_eternal_fire_thinker:OnCreated()
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.interval = self.ability:GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(self.interval)
end

function modifier_doom_eternal_fire_thinker:OnIntervalThink()
    self:CreateFlameProjectile()
end

function modifier_doom_eternal_fire_thinker:CreateFlameProjectile()
    -- unit target just indicates point
    local point = self.caster:GetAbsOrigin() + self.caster:GetForwardVector()
    
    -- load projectile
    local projectile_name = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf"
    local projectile_distance = self.ability:GetSpecialValueFor( "range" )
    local projectile_start_radius = self.ability:GetSpecialValueFor( "start_radius" )
    local projectile_end_radius = self.ability:GetSpecialValueFor( "end_radius" )
    local projectile_speed = self.ability:GetSpecialValueFor( "speed" )
    local projectile_direction = point - self.caster:GetOrigin()
    projectile_direction.z = 0
    projectile_direction = projectile_direction:Normalized()

    -- create projectile
    local info = {
        Source = self.caster,
        Ability = self.ability,
        vSpawnOrigin = self.caster:GetAbsOrigin(),
        
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
    EmitSoundOn( sound_cast, self.caster )
end
---------
--
function modifier_doom_eternal_fire_damage_thinker:IsHidden()
    return false
end

function modifier_doom_eternal_fire_damage_thinker:IsDebuff()
    return true
end

function modifier_doom_eternal_fire_damage_thinker:IsStunDebuff()
    return false
end

function modifier_doom_eternal_fire_damage_thinker:IsPurgable()
    return true
end

function modifier_doom_eternal_fire_damage_thinker:OnCreated()
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.interval = self.ability:GetSpecialValueFor("interval")

    self:StartIntervalThink(self.interval)
end

function modifier_doom_eternal_fire_damage_thinker:OnIntervalThink()
    local strength = 0

    if self.caster:GetUnitName() == "npc_dota_doom_infernal_servant" then
        strength = self.caster:GetOwner():GetStrength()
    else
        strength = self.caster:GetStrength()
    end

    local missingHpDamage = (100 - self:GetParent():GetHealthPercent()) * self.ability:GetSpecialValueFor("damage_missing_hp")
    local damage = ((self.ability:GetSpecialValueFor("damage_tick")) + (strength * (self.ability:GetSpecialValueFor("strength_to_damage")/100))) * missingHpDamage

    local damageSource = self:GetCaster()
    if damageSource:GetUnitName() == "npc_dota_doom_infernal_servant" then
        damageSource = damageSource:GetOwner()
    end
    
    local damageTable = {
        victim = self:GetParent(),
        attacker = damageSource,
        damage = damage,
        damage_type = self.ability:GetAbilityDamageType(),
        ability = self.ability, --Optional.
    }
    ApplyDamage(damageTable)
end