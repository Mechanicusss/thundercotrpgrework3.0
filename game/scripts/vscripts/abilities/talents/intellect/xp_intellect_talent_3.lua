LinkLuaModifier("modifier_xp_intellect_talent_3", "abilities/talents/intellect/xp_intellect_talent_3", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_3 = class(ItemBaseClass)
modifier_xp_intellect_talent_3 = class(xp_intellect_talent_3)
-------------
function xp_intellect_talent_3:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_3"
end
-------------
function modifier_xp_intellect_talent_3:OnCreated()
end

function modifier_xp_intellect_talent_3:OnDestroy()
end

function modifier_xp_intellect_talent_3:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT   
    }
end

function modifier_xp_intellect_talent_3:GetModifierConstantManaRegen()
    return 1 * self:GetStackCount()
end