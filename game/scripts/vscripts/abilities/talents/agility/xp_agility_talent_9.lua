LinkLuaModifier("modifier_xp_agility_talent_9", "abilities/talents/agility/xp_agility_talent_9", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_agility_talent_9 = class(ItemBaseClass)
modifier_xp_agility_talent_9 = class(xp_agility_talent_9)
-------------
function xp_agility_talent_9:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_9"
end
-------------
function modifier_xp_agility_talent_9:OnCreated()
end

function modifier_xp_agility_talent_9:OnDestroy()
end

function modifier_xp_agility_talent_9:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
    }

    return funcs
end

function modifier_xp_agility_talent_9:GetModifierMoveSpeed_Limit()
    return 2000
end

function modifier_xp_agility_talent_9:GetModifierIgnoreMovespeedLimit()
    return 1
end


function modifier_xp_agility_talent_9:GetPriority()
    return 99999
end