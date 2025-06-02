LinkLuaModifier("modifier_talent_lone_druid_2", "heroes/hero_lone_druid/talents/talent_lone_druid_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_lone_druid_2 = class(ItemBaseClass)
modifier_talent_lone_druid_2 = class(talent_lone_druid_2)
-------------
function talent_lone_druid_2:GetIntrinsicModifierName()
    return "modifier_talent_lone_druid_2"
end
-------------
function modifier_talent_lone_druid_2:OnCreated()
end

function modifier_talent_lone_druid_2:OnDestroy()
    if not IsServer() then return end 

    local caster = self:GetParent()

    -- Delete Old Bears --
    local existing = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,ex in ipairs(existing) do
        if string.match(ex:GetUnitName(), "npc_dota_lone_druid_bear_custom") then
            UTIL_RemoveImmediate(ex)
        end
    end
    --

    local spiritBear = caster:FindAbilityByName("lone_druid_spirit_bear_custom")
    if spiritBear ~= nil then
        spiritBear.bearInventory = {}
    end
end