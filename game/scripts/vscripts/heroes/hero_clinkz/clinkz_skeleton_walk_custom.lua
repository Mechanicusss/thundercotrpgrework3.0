LinkLuaModifier("modifier_clinkz_skeleton_walk_custom", "heroes/hero_clinkz/clinkz_skeleton_walk_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_skeleton_walk_custom_invis", "heroes/hero_clinkz/clinkz_skeleton_walk_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_skeleton_archer_custom", "heroes/hero_clinkz/modifier_clinkz_skeleton_archer_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

clinkz_skeleton_walk_custom = class(ItemBaseClass)
modifier_clinkz_skeleton_walk_custom = class(clinkz_skeleton_walk_custom)
modifier_clinkz_skeleton_walk_custom_invis = class(ItemBaseClassBuff)
-------------
function clinkz_skeleton_walk_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local pos = caster:GetAbsOrigin()

    local left = Vector(pos.x-150, pos.y, pos.z)
    local right = Vector(pos.x+150, pos.y, pos.z)

    local duration = self:GetSpecialValueFor("duration")

    ProjectileManager:ProjectileDodge(caster)

    caster:AddNewModifier(caster, self, "modifier_clinkz_skeleton_walk_custom_invis", {
        duration = self:GetSpecialValueFor("invis_duration")
    })

    local archer_1 = CreateUnitByName(
        "npc_dota_clinkz_skeleton_archer_custom",
        left,
        true,
        caster,
        caster,
        caster:GetTeamNumber()
    )

    if archer_1 then
        archer_1:AddNewModifier(caster, self, "modifier_clinkz_skeleton_archer_custom", {
            duration = duration,
        })
    end

    local archer_2 = CreateUnitByName(
        "npc_dota_clinkz_skeleton_archer_custom",
        right,
        true,
        caster,
        caster,
        caster:GetTeamNumber()
    )

    if archer_2 then
        archer_2:AddNewModifier(caster, self, "modifier_clinkz_skeleton_archer_custom", {
            duration = duration
        })
    end

    self:PlayEffects(caster)
end

function clinkz_skeleton_walk_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_clinkz/clinkz_windwalk.vpcf"
    local sound_cast = "Hero_Clinkz.WindWalk"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(effect_cast)

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end
------------------
function modifier_clinkz_skeleton_walk_custom_invis:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function modifier_clinkz_skeleton_walk_custom_invis:CheckState()
    local state = {
        [MODIFIER_STATE_INVISIBLE] = self:GetModifierInvisibilityLevel() == 1.0
    }

    return state
end

function modifier_clinkz_skeleton_walk_custom_invis:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("invis_speed")
end

function modifier_clinkz_skeleton_walk_custom_invis:GetModifierInvisibilityLevel(params)
    return math.min(self:GetElapsedTime() / 0.3, 1.0)
end

function modifier_clinkz_skeleton_walk_custom_invis:OnAbilityExecuted(event)
    if event.unit == self:GetParent() then
        self:Destroy()
    end
end

function modifier_clinkz_skeleton_walk_custom_invis:OnAttack(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if attacker ~= parent then
        return
    end

    self:Destroy()
end