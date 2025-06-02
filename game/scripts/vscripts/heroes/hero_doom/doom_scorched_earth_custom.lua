doom_scorched_earth_custom = class({})
modifier_doom_scorched_earth_custom_auto = class({})
LinkLuaModifier( "modifier_doom_scorched_earth_custom", "heroes/hero_doom/doom_scorched_earth_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_doom_scorched_earth_custom_auto", "heroes/hero_doom/doom_scorched_earth_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function doom_scorched_earth_custom:OnSpellStart()
    if not IsServer() then return end

    -- unit identifier
    local caster = self:GetCaster()

    -- load data
    local duration = self:GetSpecialValueFor( "duration" )

    -- add modifier
    caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_doom_scorched_earth_custom", -- modifier name
        { duration = duration } -- kv
    )
end

function doom_scorched_earth_custom:OnHeroCalculateStatBonus()
    if not IsServer() then return end

    local caster = self:GetCaster()
    if caster:HasModifier("modifier_doom_scorched_earth_custom_auto") and not caster:HasModifier("modifier_doom_scorched_earth_custom") then
        local scorched = caster:FindAbilityByName("doom_scorched_earth_custom")
        if scorched == nil or scorched:GetLevel() < 1 then return end

        caster:AddNewModifier(
            caster, -- player source
            self, -- ability source
            "modifier_doom_scorched_earth_custom", -- modifier name
            {} -- kv
        )
    end
end

function doom_scorched_earth_custom:GetBehavior()
    if self:GetCaster():HasModifier("modifier_doom_scorched_earth_custom_auto") or self:GetCaster():GetUnitName() == "npc_dota_doom_infernal_servant" then
        return DOTA_ABILITY_BEHAVIOR_PASSIVE
    end

    return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end

function doom_scorched_earth_custom:GetManaCost()
    if self:GetCaster():HasModifier("modifier_doom_scorched_earth_custom_auto") or self:GetCaster():GetUnitName() == "npc_dota_doom_infernal_servant" then return 0 end

    return self.BaseClass.GetManaCost(self, -1) or 0
end

modifier_doom_scorched_earth_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_doom_scorched_earth_custom:IsHidden()
    return false
end

function modifier_doom_scorched_earth_custom:IsDebuff()
    return false
end

function modifier_doom_scorched_earth_custom:IsPurgable()
    return false
end

function modifier_doom_scorched_earth_custom_auto:IsHidden()
    return true
end

function modifier_doom_scorched_earth_custom_auto:IsDebuff()
    return false
end

function modifier_doom_scorched_earth_custom_auto:IsPurgable()
    return false
end

function modifier_doom_scorched_earth_custom_auto:RemoveOnDeath()
    return true
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_doom_scorched_earth_custom:OnCreated( kv )
    -- references
    local damage = self:GetAbility():GetSpecialValueFor( "damage_per_second" )
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.ms_bonus = self:GetAbility():GetSpecialValueFor( "bonus_movement_speed_pct" )

    if not IsServer() then return end
    local interval = 0.5
    self.owner = kv.isProvidedByAura~=1

    if not self.owner then return end
    local statParent = self:GetParent()
    if statParent:GetUnitName() == "npc_dota_doom_infernal_servant" then
        statParent = statParent:GetOwner()
    end

    local strengthDamage = statParent:GetStrength() * (self:GetAbility():GetSpecialValueFor("strength_to_damage")/100)
    -- precache damage
    self.damageTable = {
        -- victim = target,
        attacker = statParent,
        damage = (damage + strengthDamage) * interval,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(), --Optional.
    }

    -- Start interval
    self:StartIntervalThink( interval )

    -- Play effects
    self:PlayEffects1()
end

function modifier_doom_scorched_earth_custom:OnRefresh( kv )
    -- references
    local damage = self:GetAbility():GetSpecialValueFor( "damage_per_second" )
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.ms_bonus = self:GetAbility():GetSpecialValueFor( "bonus_movement_speed_pct" )  

    if not IsServer() then return end
    if not self.owner then return end
    -- update damage
    self.damageTable.damage = damage
end

function modifier_doom_scorched_earth_custom:OnRemoved()
end

function modifier_doom_scorched_earth_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_doom_scorched_earth_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_doom_scorched_earth_custom:GetModifierMoveSpeedBonus_Percentage()
    return self.ms_bonus
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_doom_scorched_earth_custom:OnIntervalThink()
    -- find enemies
    local enemies = FindUnitsInRadius(
        self:GetParent():GetTeamNumber(),   -- int, your team number
        self:GetParent():GetOrigin(),   -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        -- apply damage
        self.damageTable.victim = enemy
        ApplyDamage( self.damageTable )

        -- play effects
        self:PlayEffects2( enemy )
    end
end

--------------------------------------------------------------------------------
-- Aura Effects
function modifier_doom_scorched_earth_custom:IsAura()
    return self.owner
end

function modifier_doom_scorched_earth_custom:GetModifierAura()
    return "modifier_doom_scorched_earth_custom"
end

function modifier_doom_scorched_earth_custom:GetAuraRadius()
    return self.radius
end

function modifier_doom_scorched_earth_custom:GetAuraDuration()
    return 0.5
end

function modifier_doom_scorched_earth_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_doom_scorched_earth_custom:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_doom_scorched_earth_custom:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED
end

function modifier_doom_scorched_earth_custom:GetAuraEntityReject( hEntity )
    if not IsServer() then return end

    return true
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_doom_scorched_earth_custom:GetEffectName()
    return "particles/units/heroes/hero_doom_bringer/doom_bringer_scorched_earth_buff.vpcf"
end

function modifier_doom_scorched_earth_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_doom_scorched_earth_custom:PlayEffects1()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_doom_bringer/doom_scorched_earth.vpcf"
    local sound_cast = "Hero_DoomBringer.ScorchedEarthAura"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )

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
    EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_doom_scorched_earth_custom:PlayEffects2( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_doom_bringer/doom_bringer_scorched_earth_debuff.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
-----
function modifier_doom_scorched_earth_custom_auto:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = parent

    if parent:GetUnitName() == "npc_dota_doom_infernal_servant" then
        caster = parent:GetOwner()
    end

    local scorched = caster:FindAbilityByName("doom_scorched_earth_custom")
    if scorched == nil or scorched:GetLevel() < 1 then return end

    parent:AddNewModifier(
        parent, -- player source
        scorched, -- ability source
        "modifier_doom_scorched_earth_custom", -- modifier name
        {} -- kv
    )
end

function modifier_doom_scorched_earth_custom_auto:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    parent:RemoveModifierByName("modifier_doom_scorched_earth_custom")
end