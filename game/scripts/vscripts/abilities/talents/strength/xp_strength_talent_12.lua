LinkLuaModifier("modifier_xp_strength_talent_12", "abilities/talents/strength/xp_strength_talent_12", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}


xp_strength_talent_12 = class(ItemBaseClass)
modifier_xp_strength_talent_12 = class(xp_strength_talent_12)
-------------
function xp_strength_talent_12:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_12"
end
-------------
function modifier_xp_strength_talent_12:OnCreated()
    self.proc = false
end

function modifier_xp_strength_talent_12:OnDestroy()
end

function modifier_xp_strength_talent_12:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_REINCARNATION   
    }
end

function modifier_xp_strength_talent_12:ReincarnateTime()
    if self.proc == false then
        self.proc = true
        return 5
    end
end