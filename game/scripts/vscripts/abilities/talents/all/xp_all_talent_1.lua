LinkLuaModifier("modifier_xp_all_talent_1", "abilities/talents/all/xp_all_talent_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_all_talent_1 = class(ItemBaseClass)
modifier_xp_all_talent_1 = class(xp_all_talent_1)
-------------
function xp_all_talent_1:GetIntrinsicModifierName()
    return "modifier_xp_all_talent_1"
end
-------------
function modifier_xp_all_talent_1:OnCreated()
end

function modifier_xp_all_talent_1:OnDestroy()
end

function modifier_xp_all_talent_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS    
    }
end

function modifier_xp_all_talent_1:GetModifierMagicalResistanceBonus()
    return 1 * self:GetStackCount()
end