LinkLuaModifier("modifier_talent_elder_titan_1", "heroes/hero_asan/talents/talent_elder_titan_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_elder_titan_1 = class(ItemBaseClass)
modifier_talent_elder_titan_1 = class(talent_elder_titan_1)
-------------
function talent_elder_titan_1:GetIntrinsicModifierName()
    return "modifier_talent_elder_titan_1"
end
-------------
function modifier_talent_elder_titan_1:OnCreated()
end

function modifier_talent_elder_titan_1:OnDestroy()
end