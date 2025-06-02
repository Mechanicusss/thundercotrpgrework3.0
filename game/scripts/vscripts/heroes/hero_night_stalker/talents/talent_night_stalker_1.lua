LinkLuaModifier("modifier_talent_night_stalker_1", "heroes/hero_night_stalker/talents/talent_night_stalker_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_night_stalker_1 = class(ItemBaseClass)
modifier_talent_night_stalker_1 = class(talent_night_stalker_1)
-------------
function talent_night_stalker_1:GetIntrinsicModifierName()
    return "modifier_talent_night_stalker_1"
end
-------------
function modifier_talent_night_stalker_1:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(FrameTime())
end

function modifier_talent_night_stalker_1:OnIntervalThink()
    if self:GetAbility():GetLevel() > 1 then
        GameRules:BeginNightstalkerNight(1)
    end
end

function modifier_talent_night_stalker_1:OnDestroy()
    if not IsServer() then return end

    if GameRules:IsNightstalkerNight() then
        GameRules:BeginNightstalkerNight(1)
    end
end