LinkLuaModifier("modifier_faceless_void_chronosphere_custom", "faceless_void_chronosphere_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_faceless_void_chronosphere_custom_thinker", "faceless_void_chronosphere_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_faceless_void_chronosphere_custom_debuff", "faceless_void_chronosphere_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
}

faceless_void_chronosphere_custom = class(ItemBaseClass)
modifier_faceless_void_chronosphere_custom_thinker = class(ItemBaseClass)
modifier_faceless_void_chronosphere_custom = class(faceless_void_chronosphere_custom)
modifier_faceless_void_chronosphere_custom_debuff = class(ItemBaseClassDebuff)
-------------
function faceless_void_chronosphere_custom:GetIntrinsicModifierName()
    return "modifier_faceless_void_chronosphere_custom"
end

function faceless_void_chronosphere_custom:OnSpellStart()
    local ability = self
    local caster = self:GetCaster()
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    local point = caster:GetAbsOrigin()

    self:CreateChronosphere(radius, point, duration)
end

function faceless_void_chronosphere_custom:CreateChronosphere(radius, point, duration)
    local caster = self:GetCaster()
    local ability = self

    --local vision = ability:GetLevelSpecialValueFor("vision_radius", (ability:GetLevel() - 1))

    self.thinker = CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_faceless_void_chronosphere_custom_thinker", -- modifier name
        { duration = duration, radius = radius }, -- kv
        point,
        caster:GetTeamNumber(),
        false
    )

    self.thinker = self.thinker:FindModifierByName("modifier_faceless_void_chronosphere_custom_thinker")

    -- create fov
    AddFOWViewer(caster:GetTeamNumber(), point, radius, duration, false)
end

function modifier_faceless_void_chronosphere_custom:DeclareFunctions()
    local funcs = {
    }
    return funcs
end

function modifier_faceless_void_chronosphere_custom:OnCreated()
    self.parent = self:GetParent()
end
-----

function modifier_faceless_void_chronosphere_custom_thinker:OnCreated( kv )
    -- references
    --self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.radius = kv.radius

    if IsServer() then
        self:PlayEffects()
    end
end

function modifier_faceless_void_chronosphere_custom_thinker:OnRefresh( kv )
    
end

function modifier_faceless_void_chronosphere_custom_thinker:OnRemoved()
end

function modifier_faceless_void_chronosphere_custom_thinker:OnDestroy()
    if IsServer() then
        UTIL_Remove( self:GetParent() )
    end
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_faceless_void_chronosphere_custom_thinker:CheckState()
    local state = {
        [MODIFIER_STATE_FROZEN] = true,
    }

    return state
end

--------------------------------------------------------------------------------
-- Aura Effects
function modifier_faceless_void_chronosphere_custom_thinker:IsAura()
    return true
end

function modifier_faceless_void_chronosphere_custom_thinker:GetModifierAura()
    return "modifier_faceless_void_chronosphere_custom_debuff"
end

function modifier_faceless_void_chronosphere_custom_thinker:GetAuraRadius()
    return self.radius
end

function modifier_faceless_void_chronosphere_custom_thinker:GetAuraDuration()
    return 0.01
end

function modifier_faceless_void_chronosphere_custom_thinker:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_faceless_void_chronosphere_custom_thinker:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_faceless_void_chronosphere_custom_thinker:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_faceless_void_chronosphere_custom_thinker:GetAuraEntityReject( hEntity )
    if IsServer() then
        -- -- reject if owner
        -- if hEntity==self:GetCaster() then return true end

        -- -- reject if owner controlled
        -- if hEntity:GetPlayerOwnerID()==self:GetCaster():GetPlayerOwnerID() then return true end

        -- reject if unit is named faceless void
        if hEntity:GetUnitName()=="npc_dota_faceless_void" then return true end
    end

    return false
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_faceless_void_chronosphere_custom_thinker:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_faceless_void/faceless_void_chronosphere.vpcf"
    local sound_cast = "Hero_FacelessVoid.Chronosphere"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, self:GetParent() )

    ParticleManager:SetParticleControl(effect_cast, 0, self:GetParent():GetOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, Vector( self.radius, self.radius, self.radius ))
    ParticleManager:SetParticleControl(effect_cast, 4, self:GetParent():GetOrigin())
    ParticleManager:SetParticleControl(effect_cast, 6, self:GetParent():GetOrigin())
    ParticleManager:SetParticleControl(effect_cast, 10, self:GetParent():GetOrigin())

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
-------
function modifier_faceless_void_chronosphere_custom_debuff:IsHidden()
    return false
end

function modifier_faceless_void_chronosphere_custom_debuff:IsDebuff()
    return not self:NotAffected()
end

function modifier_faceless_void_chronosphere_custom_debuff:IsStunDebuff()
    return not self:NotAffected()
end

function modifier_faceless_void_chronosphere_custom_debuff:IsPurgable()
    return false
end

function modifier_faceless_void_chronosphere_custom_debuff:GetPriority()
    return MODIFIER_PRIORITY_ULTRA
end

function modifier_faceless_void_chronosphere_custom_debuff:NotAffected()
    -- true owner
    if self:GetParent()==self:GetCaster() then return true end

    -- true if owner controlled
    if self:GetParent():GetPlayerOwnerID()==self:GetCaster():GetPlayerOwnerID() then return true end

    --only do this with talent
    local caster = self:GetCaster()
    local runeChronosphere = caster:FindModifierByName("modifier_item_socket_rune_legendary_faceless_void_chronosphere")
    if runeChronosphere then
        if self:GetParent():GetTeamNumber()==self:GetCaster():GetTeamNumber() then return true end
    end
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_faceless_void_chronosphere_custom_debuff:OnCreated( kv )
    self.speed = 1000

    if IsServer() then
        if not self:NotAffected() then
            self:GetParent():InterruptMotionControllers( false )
        else
            self:PlayEffects()
        end
    end
end

function modifier_faceless_void_chronosphere_custom_debuff:OnRefresh( kv )
    
end

function modifier_faceless_void_chronosphere_custom_debuff:OnRemoved()
end

function modifier_faceless_void_chronosphere_custom_debuff:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_faceless_void_chronosphere_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE  
    }

    return funcs
end

function modifier_faceless_void_chronosphere_custom_debuff:GetModifierMoveSpeed_AbsoluteMin()
    if self:NotAffected() then return self.speed end
end

function modifier_faceless_void_chronosphere_custom_debuff:GetModifierDamageOutgoing_Percentage(event)
    if self:NotAffected() and IsServer() then
        local caster = self:GetCaster()
        local runeChronosphere = caster:FindModifierByName("modifier_item_socket_rune_legendary_faceless_void_chronosphere")
        if runeChronosphere then
            return runeChronosphere.damageIncrease
        end
    end
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_faceless_void_chronosphere_custom_debuff:CheckState()
    local state1 = {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }

    local state2 = {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
        [MODIFIER_STATE_INVISIBLE] = false,
    }

    if self:NotAffected() then return state1 else return state2 end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
-- function modifier_faceless_void_chronosphere_custom_debuff:GetEffectName()
--  return "particles/units/heroes/hero_faceless_void/faceless_void_chrono_speed.vpcf"
-- end

-- function modifier_faceless_void_chronosphere_custom_debuff:GetEffectAttachType()
--  return PATTACH_ABSORIGIN_FOLLOW
-- end

-- function modifier_faceless_void_chronosphere_custom_debuff:GetStatusEffectName()
--  return "status/effect/here.vpcf"
-- end

function modifier_faceless_void_chronosphere_custom_debuff:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_faceless_void/faceless_void_chrono_speed.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    -- ParticleManager:SetParticleControl( effect_cast, iControlPoint, vControlVector )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetParent(),
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )
end

function modifier_faceless_void_chronosphere_custom_debuff:GetTexture()
    return "faceless_void_chronosphere"
end