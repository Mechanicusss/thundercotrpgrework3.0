LinkLuaModifier("modifier_talent_drow_ranger_2", "heroes/hero_drow_ranger/talents/talent_drow_ranger_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_drow_ranger_2 = class(ItemBaseClass)
modifier_talent_drow_ranger_2 = class(talent_drow_ranger_2)
-------------
function talent_drow_ranger_2:GetIntrinsicModifierName()
    return "modifier_talent_drow_ranger_2"
end
-------------
function modifier_talent_drow_ranger_2:OnCreated()
end

function modifier_talent_drow_ranger_2:OnDestroy()
end