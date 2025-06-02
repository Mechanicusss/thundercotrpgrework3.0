underlord_pit_of_malice_custom = class({})
LinkLuaModifier( "modifier_underlord_pit_of_malice_custom", "heroes/hero_underlord/underlord_pit_of_malice_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_underlord_pit_of_malice_custom_cooldown", "heroes/hero_underlord/underlord_pit_of_malice_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_underlord_pit_of_malice_custom_thinker", "heroes/hero_underlord/underlord_pit_of_malice_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function underlord_pit_of_malice_custom:GetAOERadius()
    return self:GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------
-- Ability Phase Start
function underlord_pit_of_malice_custom:OnAbilityPhaseStart()
    -- create effects
    local point = self:GetCursorPosition()
    self:PlayEffects( point )

    return true -- if success
end
function underlord_pit_of_malice_custom:OnAbilityPhaseInterrupted()
    -- kill effect
    ParticleManager:DestroyParticle( self.effect_cast, true )
    ParticleManager:ReleaseParticleIndex( self.effect_cast )

end

--------------------------------------------------------------------------------
-- Ability Start
function underlord_pit_of_malice_custom:OnSpellStart()
    -- release cast effect
    ParticleManager:ReleaseParticleIndex( self.effect_cast )

    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- load data
    local duration = self:GetSpecialValueFor( "pit_duration" )

    -- create thinker
    CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_underlord_pit_of_malice_custom_thinker", -- modifier name
        { duration = duration }, -- kv
        point,
        caster:GetTeamNumber(),
        false
    )

end

--------------------------------------------------------------------------------
function underlord_pit_of_malice_custom:PlayEffects( point )
    -- Get Resources
    local particle_cast = "particles/units/heroes/heroes_underlord/underlord_pitofmalice_pre.vpcf"
    local sound_cast = "Hero_AbyssalUnderlord.PitOfMalice.Start"

    -- Get Data
    local radius = self:GetSpecialValueFor( "radius" )

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticleForTeam( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster(), self:GetCaster():GetTeamNumber() )
    ParticleManager:SetParticleControl( self.effect_cast, 0, point )
    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( radius, 1, 1 ) )
    -- ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOnLocationForAllies( point, sound_cast, self:GetCaster() )
end



modifier_underlord_pit_of_malice_custom_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_underlord_pit_of_malice_custom_thinker:IsHidden()
    return false
end

function modifier_underlord_pit_of_malice_custom_thinker:IsDebuff()
    return false
end

function modifier_underlord_pit_of_malice_custom_thinker:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_underlord_pit_of_malice_custom_thinker:OnCreated( kv )
    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.pit_damage = self:GetAbility():GetSpecialValueFor( "pit_damage" )
    self.duration = self:GetAbility():GetSpecialValueFor( "ensnare_duration" )

    if not IsServer() then return end
    self.caster = self:GetCaster()
    self.parent = self:GetParent()

    -- start interval
    self:StartIntervalThink( 0.033 )
    self:OnIntervalThink()

    -- play effects
    self:PlayEffects()

end

function modifier_underlord_pit_of_malice_custom_thinker:OnRefresh( kv )
    
end

function modifier_underlord_pit_of_malice_custom_thinker:OnRemoved()

end

function modifier_underlord_pit_of_malice_custom_thinker:OnDestroy()
    if not IsServer() then return end
    UTIL_Remove( self:GetParent() )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_underlord_pit_of_malice_custom_thinker:OnIntervalThink()
    -- Using aura's sticky duration doesn't allow it to be purged, so here we are

    -- find enemies
    local enemies = FindUnitsInRadius(
        self.caster:GetTeamNumber(),    -- int, your team number
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
        -- check if not cooldown
        local modifier = enemy:FindModifierByNameAndCaster( "modifier_underlord_pit_of_malice_custom_cooldown", self:GetCaster() )
        if not modifier then
            -- apply modifier
            enemy:AddNewModifier(
                self.caster, -- player source
                self:GetAbility(), -- ability source
                "modifier_underlord_pit_of_malice_custom", -- modifier name
                { duration = self.duration } -- kv
            )
        end
    end
end

-- --------------------------------------------------------------------------------
-- -- Aura Effects
-- function modifier_underlord_pit_of_malice_custom_thinker:IsAura()
--  return true
-- end

-- function modifier_underlord_pit_of_malice_custom_thinker:GetModifierAura()
--  return "modifier_underlord_pit_of_malice_custom"
-- end

-- function modifier_underlord_pit_of_malice_custom_thinker:GetAuraRadius()
--  return self.radius
-- end

-- function modifier_underlord_pit_of_malice_custom_thinker:GetAuraDuration()
--  return self.duration
-- end

-- function modifier_underlord_pit_of_malice_custom_thinker:GetAuraSearchTeam()
--  return DOTA_UNIT_TARGET_TEAM_ENEMY
-- end

-- function modifier_underlord_pit_of_malice_custom_thinker:GetAuraSearchType()
--  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
-- end

-- function modifier_underlord_pit_of_malice_custom_thinker:GetAuraSearchFlags()
--  return 0
-- end

-- function modifier_underlord_pit_of_malice_custom_thinker:GetAuraEntityReject( hEntity )
--  if not IsServer() then return false end

--  -- reject if cooldown
--  if hEntity:FindModifierByNameAndCaster( "modifier_underlord_pit_of_malice_custom_cooldown", self:GetCaster() ) then
--      return true
--  end

--  return false
-- end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_underlord_pit_of_malice_custom_thinker:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/heroes_underlord/underlord_pitofmalice.vpcf"
    local sound_cast = "Hero_AbyssalUnderlord.PitOfMalice"

    -- Get Data
    local parent = self:GetParent()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControl( effect_cast, 0, parent:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 1, 1 ) )
    ParticleManager:SetParticleControl( effect_cast, 2, Vector( self:GetDuration(), 0, 0 ) )

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
    EmitSoundOn( sound_cast, parent )
end

modifier_underlord_pit_of_malice_custom_cooldown = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_underlord_pit_of_malice_custom_cooldown:IsHidden()
    return true
end

function modifier_underlord_pit_of_malice_custom_cooldown:IsDebuff()
    return true
end

function modifier_underlord_pit_of_malice_custom_cooldown:IsPurgable()
    return false
end

function modifier_underlord_pit_of_malice_custom_cooldown:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE 
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_underlord_pit_of_malice_custom_cooldown:OnCreated( kv )

end

function modifier_underlord_pit_of_malice_custom_cooldown:OnRefresh( kv )
    
end

function modifier_underlord_pit_of_malice_custom_cooldown:OnRemoved()
end

function modifier_underlord_pit_of_malice_custom_cooldown:OnDestroy()
end

modifier_underlord_pit_of_malice_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_underlord_pit_of_malice_custom:IsHidden()
    return false
end

function modifier_underlord_pit_of_malice_custom:IsDebuff()
    return true
end

function modifier_underlord_pit_of_malice_custom:IsStunDebuff()
    return false
end

function modifier_underlord_pit_of_malice_custom:IsPurgable()
    return true
end

function modifier_underlord_pit_of_malice_custom:GetPriority()
    return MODIFIER_PRIORITY_HIGH
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_underlord_pit_of_malice_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_underlord_pit_of_malice_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_underlord_pit_of_malice_custom:GetModifierIncomingDamage_Percentage(event)
    if event.attacker == self:GetCaster() then
        return self:GetAbility():GetSpecialValueFor("incoming_damage")
    end
end

function modifier_underlord_pit_of_malice_custom:OnCreated( kv )
    -- references
    local interval = self:GetAbility():GetSpecialValueFor( "pit_interval" )

    if not IsServer() then return end

    -- create cooldown modifier
    self:GetParent():AddNewModifier(
        self:GetCaster(), -- player source
        self:GetAbility(), -- ability source
        "modifier_underlord_pit_of_malice_custom_cooldown", -- modifier name
        {
            duration = interval,
        } -- kv
    )

    -- play effects
    local hero = self:GetParent():IsHero()
    local sound_cast = "Hero_AbyssalUnderlord.Pit.TargetHero"
    if not hero then
        sound_cast = "Hero_AbyssalUnderlord.Pit.Target"
    end

    EmitSoundOn( sound_cast, self:GetParent() )

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self:GetAbility():GetSpecialValueFor("damage") + (self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("str_to_damage")/100)),
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility()

    })
end

function modifier_underlord_pit_of_malice_custom:OnRefresh( kv )
    
end

function modifier_underlord_pit_of_malice_custom:OnRemoved()
end

function modifier_underlord_pit_of_malice_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_underlord_pit_of_malice_custom:CheckState()
    local state = {
        [MODIFIER_STATE_INVISIBLE] = false,
        --[MODIFIER_STATE_ROOTED] = true,
    }

    return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_underlord_pit_of_malice_custom:GetEffectName()
    return "particles/units/heroes/heroes_underlord/abyssal_underlord_pitofmalice_stun.vpcf"
end

function modifier_underlord_pit_of_malice_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end