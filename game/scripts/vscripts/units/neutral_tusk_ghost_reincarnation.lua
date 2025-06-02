LinkLuaModifier("modifier_neutral_tusk_ghost_reincarnation", "units/neutral_tusk_ghost_reincarnation", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

neutral_tusk_ghost_reincarnation = class(ItemBaseClass)
modifier_neutral_tusk_ghost_reincarnation = class(neutral_tusk_ghost_reincarnation)
-------------
function neutral_tusk_ghost_reincarnation:GetIntrinsicModifierName()
    return "modifier_neutral_tusk_ghost_reincarnation"
end


function modifier_neutral_tusk_ghost_reincarnation:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_neutral_tusk_ghost_reincarnation:OnCreated()
    self.parent = self:GetParent()
end

function modifier_neutral_tusk_ghost_reincarnation:OnDeath(event)
    if self:GetParent() ~= event.unit then return end

    CreateUnitByNameAsync("npc_dota_wave_neutral_tusk_skeleton_ghost", event.unit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS, function(unit)
        unit:AddNewModifier(nil, nil, "modifier_phased", { duration = 0.2 })
        unit:CreatureLevelUp(event.unit:GetLevel())

        unit:AddNewModifier(unit, nil, "modifier_wave_ai", {})
        self:PlayEffects(unit)
    end)
end

function modifier_neutral_tusk_ghost_reincarnation:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_skeletonking/wraith_king_ghosts_spirits_copy.vpcf"

    -- Get Data
    local forward = (target:GetOrigin()-self.parent:GetOrigin()):Normalized()

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
    ParticleManager:SetParticleControl( effect_cast, 4, target:GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 0, forward )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end