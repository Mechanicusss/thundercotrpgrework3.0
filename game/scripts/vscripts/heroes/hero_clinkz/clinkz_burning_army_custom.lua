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

clinkz_burning_army_custom = class(ItemBaseClass)
-------------
function clinkz_burning_army_custom:GetAOERadius()
    return self:GetSpecialValueFor("formation_radius")
end

function clinkz_burning_army_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local count = self:GetSpecialValueFor("skeleton_count")
    local duration = self:GetSpecialValueFor("skeleton_duration")
    local formation_radius = self:GetSpecialValueFor("formation_radius")

    local forward = caster:GetForwardVector() + caster:GetAbsOrigin()

    EmitSoundOn("Hero_Clinkz.BurningArmy.Cast", caster)

    for i = 1, count do
        -- Thanks to Dota IMBA for the circle position code
        -- https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/abilities/heroes/hero_shadow_shaman#L862
        local pos = Vector(math.cos(math.rad(((360 / count) * i))), math.sin(math.rad(((360 / count) * i))), 0) * formation_radius

        self:SpawnSkeletonArcher(caster, point + pos, duration, self, forward)
    end
end

function clinkz_burning_army_custom:SpawnSkeletonArcher(owner, point, duration, ability, forward)
    local archer = CreateUnitByName(
        "npc_dota_clinkz_skeleton_archer_custom",
        point,
        true,
        owner,
        owner,
        owner:GetTeamNumber()
    )

    if archer then
        archer:AddNewModifier(owner, ability, "modifier_clinkz_skeleton_archer_custom", {
            duration = duration,
            x = forward.x,
            y = forward.y,
            z = forward.z
        })
    end
end
