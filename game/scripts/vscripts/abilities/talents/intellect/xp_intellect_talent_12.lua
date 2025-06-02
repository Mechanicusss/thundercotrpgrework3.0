LinkLuaModifier("modifier_xp_intellect_talent_12", "abilities/talents/intellect/xp_intellect_talent_12", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_12 = class(ItemBaseClass)
modifier_xp_intellect_talent_12 = class(xp_intellect_talent_12)
-------------
function xp_intellect_talent_12:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_12"
end
-------------
function modifier_xp_intellect_talent_12:OnCreated()
end

function modifier_xp_intellect_talent_12:OnDestroy()
end

function modifier_xp_intellect_talent_12:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE  
    }
end

function modifier_xp_intellect_talent_12:GetModifierTotalPercentageManaRegen()
    local parent = self:GetParent()
    local remainingHpPct = (parent:GetMaxHealth() - parent:GetHealth())/parent:GetMaxHealth()

    if 1-remainingHpPct <= 0.5 then
        return 1 * self:GetStackCount()
    end
end