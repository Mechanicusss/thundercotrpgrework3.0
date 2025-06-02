omniknight_guardian_angel_custom = class({})
LinkLuaModifier( "modifier_omniknight_guardian_angel_custom", "heroes/hero_omniknight/omniknight_guardian_angel_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function omniknight_guardian_angel_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()

    -- load data
    local buffDuration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")
    local targets = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC

    if caster:HasScepter() then
        buffDuration = self:GetSpecialValueFor("duration_scepter")
        radius = FIND_UNITS_EVERYWHERE
        targets = DOTA_UNIT_TARGET_ALL
    end

    -- Find Units in Radius
    local allies = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(),   -- int, your team number
        caster:GetOrigin(), -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_FRIENDLY, -- int, team filter
        targets,    -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,ally in pairs(allies) do
        -- Add modifier
        ally:AddNewModifier(
            caster, -- player source
            self, -- ability source
            "modifier_omniknight_guardian_angel_custom", -- modifier name
            { duration = buffDuration } -- kv
        )
    end

    -- Play Effects
    local sound_cast = "Hero_Omniknight.GuardianAngel.Cast"
    EmitSoundOn( sound_cast, caster )
end

modifier_omniknight_guardian_angel_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_omniknight_guardian_angel_custom:IsHidden()
    return false
end

function modifier_omniknight_guardian_angel_custom:IsDebuff()
    return false
end

function modifier_omniknight_guardian_angel_custom:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_omniknight_guardian_angel_custom:OnCreated( kv )
    if IsServer() then
        self:PlayEffects()
    end
end

function modifier_omniknight_guardian_angel_custom:OnRefresh( kv )
    if IsServer() then
        self:PlayEffects()
    end
end

function modifier_omniknight_guardian_angel_custom:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_omniknight_guardian_angel_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    }

    return funcs
end

function modifier_omniknight_guardian_angel_custom:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_omniknight_guardian_angel_custom:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("outgoing_damage_increase")
end

--------------------------------------------------------------------------------
-- Graphics & Animations
-- function modifier_omniknight_guardian_angel_custom:GetEffectName()
--  if self:GetParent()~=self:GetCaster() then
--      return "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf"
--  end
-- end

-- function modifier_omniknight_guardian_angel_custom:GetEffectAttachType()
--  if self:GetParent()~=self:GetCaster() then
--      return PATTACH_ABSORIGIN_FOLLOW
--  end
-- end

function modifier_omniknight_guardian_angel_custom:PlayEffects()
    local sound_cast = "Hero_Omniknight.GuardianAngel"
    EmitSoundOn( sound_cast, self:GetParent() )

    local particle_cast = "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf"
    if self:GetParent()==self:GetCaster() then
        particle_cast = "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_omni.vpcf"
    end

    -- create particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        5,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        self:GetParent():GetOrigin(), -- unknown
        true -- unknown, true
    )

    self:AddParticle(
        effect_cast,
        false,
        false,
        -1,
        false,
        false
    )
end