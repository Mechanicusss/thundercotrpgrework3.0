--------------------------------------------------------------------------------
boss_spectre_dispersion = class({})
modifier_boss_spectre_dispersion_activated = class({})
LinkLuaModifier( "modifier_boss_spectre_dispersion", "heroes/bosses/spectre/dispersion", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_spectre_dispersion_activated", "heroes/bosses/spectre/dispersion", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Init Abilities
function boss_spectre_dispersion:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_spectre.vsndevts", context )
    PrecacheResource( "particle", "particles/econ/items/spectre/spectre_arcana/spectre_arcana_dispersion.vpcf", context )
end

function boss_spectre_dispersion:Spawn()
    if not IsServer() then return end
end

function boss_spectre_dispersion:OnSpellStart()
    if not IsServer() then return end

    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_boss_spectre_dispersion_activated", { duration = self:GetSpecialValueFor("duration") })
    EmitSoundOn("DOTA_Item.BladeMail.Activate", self:GetCaster())
end

function modifier_boss_spectre_dispersion_activated:IsHidden()
    return false
end

function modifier_boss_spectre_dispersion_activated:IsDebuff()
    return false
end

function modifier_boss_spectre_dispersion_activated:IsStunDebuff()
    return false
end

function modifier_boss_spectre_dispersion_activated:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Passive Modifier
function boss_spectre_dispersion:GetIntrinsicModifierName()
    return "modifier_boss_spectre_dispersion"
end

modifier_boss_spectre_dispersion = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_boss_spectre_dispersion:IsHidden()
    return true
end

function modifier_boss_spectre_dispersion:IsDebuff()
    return false
end

function modifier_boss_spectre_dispersion:IsStunDebuff()
    return false
end

function modifier_boss_spectre_dispersion:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_boss_spectre_dispersion:OnCreated( kv )
    self.parent = self:GetParent()

    -- references
    self.reflect = self:GetAbility():GetSpecialValueFor( "damage_reflection_pct" )
    self.reflectOriginal = self:GetAbility():GetSpecialValueFor( "damage_reflection_pct" )
    self.min_radius = self:GetAbility():GetSpecialValueFor( "min_radius" )
    self.max_radius = self:GetAbility():GetSpecialValueFor( "max_radius" )
    self.delta = self.max_radius-self.min_radius

    if not IsServer() then return end
    -- for shard
    self.attacker = {}

    -- precache damage
    self.damageTable = {
        -- victim = target,
        attacker = self.parent,
        -- damage = 500,
        -- damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(), --Optional.
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_REFLECTION, --Optional.
    }

    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_boss_spectre_dispersion:OnIntervalThink()
    local caster = self:GetCaster()

    local dispersion = self:GetAbility()

    if caster:IsAttacking() and dispersion:IsCooldownReady() then
        caster:CastAbilityImmediately(dispersion, -1)
        dispersion:UseResources(false, false, false, true)
    end
end

function modifier_boss_spectre_dispersion:OnRefresh( kv )
    self:OnCreated( kv )
end

function modifier_boss_spectre_dispersion:OnRemoved()
end

function modifier_boss_spectre_dispersion:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_boss_spectre_dispersion:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }

    return funcs
end

function modifier_boss_spectre_dispersion:GetModifierIncomingDamage_Percentage( params )
    if self.parent:PassivesDisabled() then return 0 end

    if self.parent:HasModifier("modifier_boss_spectre_dispersion_activated") then
        self.reflect = self:GetAbility():GetSpecialValueFor("active_damage_reflection_pct")
    else
        self.reflect = self.reflectOriginal
    end

    local pass = true

    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= 0 then
        pass = false
    end

    if pass then
        -- find enemies
        local enemies = FindUnitsInRadius(
            self.parent:GetTeamNumber(),    -- int, your team number
            self.parent:GetOrigin(),    -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            self.max_radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            0,  -- int, flag filter
            0,  -- int, order filter
            false   -- bool, can grow cache
        )

        for _,enemy in pairs(enemies) do
            -- get distance percentage damage
            local distance = (enemy:GetOrigin()-self.parent:GetOrigin()):Length2D()
            local pct = (self.max_radius-distance)/self.delta
            pct = math.min( pct, 1 )

            -- apply damage
            self.damageTable.victim = enemy
            self.damageTable.damage = params.damage * pct * self.reflect/100
            self.damageTable.damage_type = params.damage_type
            ApplyDamage( self.damageTable )

            -- play effects
            self:PlayEffects( enemy )
        end
    end

    return -self.reflect
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_boss_spectre_dispersion:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/econ/items/spectre/spectre_arcana/spectre_arcana_dispersion.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self.parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    -- ParticleManager:SetParticleControl( effect_cast, 1, vControlVector )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end