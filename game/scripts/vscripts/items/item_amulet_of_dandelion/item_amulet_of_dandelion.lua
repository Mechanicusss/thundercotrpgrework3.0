LinkLuaModifier("modifier_item_amulet_of_dandelion", "items/item_amulet_of_dandelion/item_amulet_of_dandelion", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_amulet_of_dandelion = class(ItemBaseClass)
modifier_item_amulet_of_dandelion = class(item_amulet_of_dandelion)
-------------
function item_amulet_of_dandelion:GetIntrinsicModifierName()
    return "modifier_item_amulet_of_dandelion"
end
-------------
function modifier_item_amulet_of_dandelion:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
        MODIFIER_PROPERTY_EXTRA_MANA_PERCENTAGE,
        MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE 
    }
end

function modifier_item_amulet_of_dandelion:GetModifierMagical_ConstantBlock()
    if IsServer() then
        local ability = self:GetAbility()

        if ability:IsCooldownReady() then
            ability:UseResources(false, false, false, true)
            return self:GetParent():GetMaxMana() * (self:GetAbility():GetSpecialValueFor("max_mana_to_block_pct")/100)
        end
    end
end

function modifier_item_amulet_of_dandelion:GetModifierExtraManaPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_max_mana_pct")
end

function modifier_item_amulet_of_dandelion:GetModifierTotalPercentageManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen_pct")
end