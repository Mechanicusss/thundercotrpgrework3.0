LinkLuaModifier("modifier_xp_intellect_talent_14", "abilities/talents/intellect/xp_intellect_talent_14", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_14 = class(ItemBaseClass)
modifier_xp_intellect_talent_14 = class(xp_intellect_talent_14)
-------------
function xp_intellect_talent_14:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_14"
end
-------------
function modifier_xp_intellect_talent_14:OnCreated()
end

function modifier_xp_intellect_talent_14:OnDestroy()
end

function modifier_xp_intellect_talent_14:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE    
    }
end

function modifier_xp_intellect_talent_14:GetModifierTotalDamageOutgoing_Percentage()
    local parent = self:GetParent()
    local mana = parent:GetMana()
    local maxMana = parent:GetMaxMana()

    if mana == maxMana then
        return 15 * self:GetStackCount()
    end
end