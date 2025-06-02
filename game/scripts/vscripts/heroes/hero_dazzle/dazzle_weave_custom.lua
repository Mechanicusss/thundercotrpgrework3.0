dazzle_weave_custom = class({})
LinkLuaModifier( "modifier_dazzle_weave_custom", "heroes/hero_dazzle/dazzle_weave_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function dazzle_weave_custom:GetAOERadius()
    return self:GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------
-- Ability Start
function dazzle_weave_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- load data
    local radius = self:GetSpecialValueFor("radius")
    local bDuration = self:GetSpecialValueFor("duration")
    local visionDuration = 3

    -- Find Units in Radius
    local heroes = FindUnitsInRadius(
        caster:GetTeamNumber(), -- int, your team number
        point,  -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_BOTH, -- int, team filter
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC),  -- int, type filter
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,    -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,hero in pairs(heroes) do
        -- Add modifier
        hero:AddNewModifier(
            caster, -- player source
            self, -- ability source
            "modifier_dazzle_weave_custom", -- modifier name
            { duration = bDuration } -- kv
        )
    end

    -- Add viewer
    AddFOWViewer( caster:GetTeamNumber(), point, radius, visionDuration, true )

    -- Play effects
    self:PlayEffects( point )
end

--------------------------------------------------------------------------------
-- Ability Considerations
function dazzle_weave_custom:AbilityConsiderations()
    -- Scepter
    local bScepter = caster:HasScepter()

    -- Linken & Lotus
    local bBlocked = target:TriggerSpellAbsorb( self )

    -- Break
    local bBroken = caster:PassivesDisabled()

    -- Advanced Status
    local bInvulnerable = target:IsInvulnerable()
    local bInvisible = target:IsInvisible()
    local bHexed = target:IsHexed()
    local bMagicImmune = target:IsMagicImmune()

    -- Illusion Copy
    local bIllusion = target:IsIllusion()
end

--------------------------------------------------------------------------------
function dazzle_weave_custom:PlayEffects( point )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_dazzle/dazzle_weave.vpcf"
    local sound_cast = "Hero_Dazzle.Weave"

    -- Get Data
    local radius = self:GetSpecialValueFor("radius")

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, point )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn(sound_cast, self:GetCaster() )
end

modifier_dazzle_weave_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_dazzle_weave_custom:IsHidden()
    return false
end

function modifier_dazzle_weave_custom:IsDebuff()
    return not self.buff
end

function modifier_dazzle_weave_custom:IsStunDebuff()
    return false
end

function modifier_dazzle_weave_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_dazzle_weave_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_dazzle_weave_custom:OnCreated( kv )
    self:SetHasCustomTransmitterData(true)

    -- references
    self.armor_per_second = self:GetAbility():GetSpecialValueFor( "armor_per_second" ) -- special value

    -- generate data
    self.buff = self:GetParent():GetTeamNumber()==self:GetCaster():GetTeamNumber()
    self.armor = self:GetParent():GetPhysicalArmorBaseValue() * (self:GetAbility():GetSpecialValueFor("armor_per_second_pct")/100)
    self.tick = 1
    self.count = 0

    if not self.buff then
        self.armor_per_second = -self.armor_per_second
    end
    
    self:StartIntervalThink( self.tick )
    self:InvokeArmor()
end

function modifier_dazzle_weave_custom:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
    }
end

function modifier_dazzle_weave_custom:HandleCustomTransmitterData(data)
    if data.armor ~= nil then
        self.fArmor = tonumber(data.armor)
    end
end

function modifier_dazzle_weave_custom:InvokeArmor()
    if IsServer() == true then
        self.fArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end

function modifier_dazzle_weave_custom:OnRefresh( kv )
    self.armor = self:GetParent():GetPhysicalArmorBaseValue() * (self:GetAbility():GetSpecialValueFor("armor_per_second_pct")/100)
    self:InvokeArmor()
end

function modifier_dazzle_weave_custom:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_dazzle_weave_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }

    return funcs
end

function modifier_dazzle_weave_custom:GetModifierPhysicalArmorBonus()
    return (self.count * self.armor_per_second) + (self.count * self.fArmor)
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_dazzle_weave_custom:OnIntervalThink()
    self.count = self.count + 1
    self:OnRefresh()
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_dazzle_weave_custom:GetEffectName()
    if self.buff then
        return "particles/units/heroes/hero_dazzle/dazzle_armor_friend.vpcf"
    else
        return "particles/units/heroes/hero_dazzle/dazzle_armor_enemy.vpcf"
    end
end

function modifier_dazzle_weave_custom:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end