LinkLuaModifier("modifier_item_wings", "items/wings/item_wings.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_wings_active", "items/wings/item_wings.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_wings = class(ItemBaseClass)
modifier_item_wings = class(ItemBaseClass)
modifier_item_wings_active = class(ItemBaseClassActive)
-------------
function item_wings:GetIntrinsicModifierName()
    return "modifier_item_wings"
end

function item_wings:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    
    caster:AddNewModifier(caster, ability, "modifier_item_wings_active", {})
    UTIL_Remove(self)
end
---
function modifier_item_wings_active:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function modifier_item_wings_active:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  
    }

    return funcs
end

function modifier_item_wings_active:GetModifierMoveSpeedBonus_Percentage()
    return 100
end

function modifier_item_wings_active:GetEffectName()
    return "particles/econ/items/legion/legion_fallen/legion_fallen_press.vpcf"
end

function modifier_item_wings_active:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_wings_active:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING] = true
    }
    return state
end