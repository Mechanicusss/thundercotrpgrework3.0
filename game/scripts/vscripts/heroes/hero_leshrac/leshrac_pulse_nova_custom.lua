leshrac_pulse_nova_custom = class({})
LinkLuaModifier( "modifier_leshrac_pulse_nova_custom", "heroes/hero_leshrac/leshrac_pulse_nova_custom.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function leshrac_pulse_nova_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()

    -- load data

    -- logic
end

--------------------------------------------------------------------------------
-- Ability Toggle
function leshrac_pulse_nova_custom:OnToggle(  )
    -- unit identifier
    local caster = self:GetCaster()

    -- load data
    local toggle = self:GetToggleState()

    if toggle then
        -- add modifier
        self.modifier = caster:AddNewModifier(
            caster, -- player source
            self, -- ability source
            "modifier_leshrac_pulse_nova_custom", -- modifier name
            {  } -- kv
        )
    else
        if self.modifier and not self.modifier:IsNull() then
            self.modifier:Destroy()
        end
        self.modifier = nil
    end
end

modifier_leshrac_pulse_nova_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_leshrac_pulse_nova_custom:IsHidden()
    return false
end

function modifier_leshrac_pulse_nova_custom:IsDebuff()
    return false
end

function modifier_leshrac_pulse_nova_custom:IsPurgable()
    return false
end

function modifier_leshrac_pulse_nova_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT 
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_leshrac_pulse_nova_custom:OnCreated( kv )
    if not IsServer() then return end
    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.manacost = self:GetParent():GetMaxMana() * (self:GetAbility():GetSpecialValueFor( "mana_cost_per_second" )/100)
    local damage = self.manacost
    local intervalMin = self:GetAbility():GetSpecialValueFor( "interval_min" )
    local intervalMax = self:GetAbility():GetSpecialValueFor( "interval_max" )
    
    self.interval = 1 / self:GetParent():GetAttacksPerSecond(false)

    if self.interval > intervalMin then
        self.interval = intervalMin
    end

    if self.interval < intervalMax then
        self.interval = intervalMax
    end

    -- precache
    self.parent = self:GetParent()
    self.damageTable = {
        -- victim = target,
        attacker = self:GetParent(),
        damage = damage,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility(), --Optional.
    }
    -- ApplyDamage(damageTable)

    -- Start interval
    self:Burn()
    self:StartIntervalThink( self.interval )

    -- play effects
    local sound_loop = "Hero_Leshrac.Pulse_Nova"
    EmitSoundOn( sound_loop, self.parent )
end

function modifier_leshrac_pulse_nova_custom:OnRefresh( kv )
end

function modifier_leshrac_pulse_nova_custom:OnRemoved()
end

function modifier_leshrac_pulse_nova_custom:OnDestroy()
    if not IsServer() then return end
    local sound_loop = "Hero_Leshrac.Pulse_Nova"
    StopSoundOn( sound_loop, self.parent )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_leshrac_pulse_nova_custom:OnIntervalThink()
    -- check mana
    local mana = self.parent:GetMana()
    if mana < self.manacost then
        -- turn off
        if self:GetAbility():GetToggleState() then
            self:GetAbility():ToggleAbility()
        end
        return
    end

    -- damage
    self:Burn()
end

function modifier_leshrac_pulse_nova_custom:Burn()
    -- spend mana
    self.parent:SpendMana( self.manacost * self.interval, self:GetAbility() )

    -- find enemies
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),    -- int, your team number
        self.parent:GetOrigin(),    -- point, center point
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
        self:PlayEffects( enemy )

        -- Check for scepter --
        if self.parent:HasScepter() and RollPercentage(self:GetAbility(), self:GetAbility():GetSpecialValueFor("lightning_storm_chance")) then
            local lightningStorm = self.parent:FindAbilityByName("leshrac_lightning_storm_custom")
            if lightningStorm ~= nil and lightningStorm:GetLevel() > 0 then
                SpellCaster:Cast(lightningStorm, enemy, false)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_leshrac_pulse_nova_custom:GetEffectName()
    return "particles/units/heroes/hero_leshrac/leshrac_pulse_nova_ambient.vpcf"
end

function modifier_leshrac_pulse_nova_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_leshrac_pulse_nova_custom:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_leshrac/leshrac_pulse_nova.vpcf"
    local sound_cast = "Hero_Leshrac.Pulse_Nova_Strike"

    -- radius
    local radius = 100

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector(radius,0,0) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- -- buff particle
    -- self:AddParticle(
    --  effect_cast,
    --  false, -- bDestroyImmediately
    --  false, -- bStatusEffect
    --  -1, -- iPriority
    --  false, -- bHeroEffect
    --  false -- bOverheadEffect
    -- )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end