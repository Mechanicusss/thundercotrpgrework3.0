LinkLuaModifier("modifier_item_tarrasque_belt", "items/item_tarrasque_belt/item_tarrasque_belt", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_tarrasque_belt = class(ItemBaseClass)
modifier_item_tarrasque_belt = class(ItemBaseClass)
---
function item_tarrasque_belt:GetIntrinsicModifierName()
    return "modifier_item_tarrasque_belt"
end

function modifier_item_tarrasque_belt:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK, --GetModifierPhysical_ConstantBlock
    }

    return funcs
end

function modifier_item_tarrasque_belt:GetModifierHealthBonus()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_tarrasque_belt:GetModifierConstantHealthRegen()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end

function modifier_item_tarrasque_belt:GetModifierPhysical_ConstantBlock(event)
    local block = event.damage * (self:GetAbility():GetSpecialValueFor("damage_block_pct")/100)

    if block > self:GetAbility():GetSpecialValueFor("max_damage_block") then
        block = self:GetAbility():GetSpecialValueFor("max_damage_block")
    end

    return block
end