LinkLuaModifier("modifier_lava_drake_skin", "creeps/lava_drake_skin", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

lava_drake_skin = class(ItemBaseClass)
modifier_lava_drake_skin = class(lava_drake_skin)
-------------
function lava_drake_skin:GetIntrinsicModifierName()
    return "modifier_lava_drake_skin"
end
-------------
function modifier_lava_drake_skin:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_lava_drake_skin:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_reduction_pct")
end