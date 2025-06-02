LinkLuaModifier("modifier_xp_agility_talent_15", "abilities/talents/agility/xp_agility_talent_15", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_agility_talent_15 = class(ItemBaseClass)
modifier_xp_agility_talent_15 = class(xp_agility_talent_15)
-------------
function xp_agility_talent_15:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_15"
end
-------------
function modifier_xp_agility_talent_15:OnCreated()
end

function modifier_xp_agility_talent_15:OnDestroy()
end

function modifier_xp_agility_talent_15:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS  
    }
end

function modifier_xp_agility_talent_15:GetModifierBonusStats_Agility()
    return 0.1 * self:GetParent():GetLevel() * self:GetStackCount()
end