LinkLuaModifier("modifier_item_witchbane_custom", "items/item_witchbane_custom/item_witchbane_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_witchbane_custom = class(ItemBaseClass)
item_witchbane_custom_2 = item_witchbane_custom
item_witchbane_custom_3 = item_witchbane_custom
item_witchbane_custom_4 = item_witchbane_custom
item_witchbane_custom_5 = item_witchbane_custom
item_witchbane_custom_6 = item_witchbane_custom
item_witchbane_custom_7 = item_witchbane_custom
item_witchbane_custom_8 = item_witchbane_custom
item_witchbane_custom_9 = item_witchbane_custom
modifier_item_witchbane_custom = class(item_witchbane_custom)
-------------
function item_witchbane_custom:GetIntrinsicModifierName()
    return "modifier_item_witchbane_custom"
end

function modifier_item_witchbane_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    }
end

function modifier_item_witchbane_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    if IsServer() then
        local parent = self:GetParent()

        local ability = self:GetAbility()

        if event.target ~= event.attacker and event.attacker == parent and event.inflictor ~= self:GetAbility() then
            if event.damage_type == DAMAGE_TYPE_MAGICAL and ability:IsCooldownReady() then
                ApplyDamage({
                    attacker = parent,
                    victim = event.target,
                    damage = parent:GetMaxMana() * (ability:GetSpecialValueFor("bonus_damage_from_max_mana")/100),
                    damage_type = DAMAGE_TYPE_PURE,
                    ability = ability
                })

                ability:UseResources(false, false, false, true)
            end
            
            if event.target:GetHealthPercent() <= ability:GetSpecialValueFor("bonus_damage_hp_threshold") then
                return ability:GetSpecialValueFor("bonus_damage_pct")
            end
        end
    end
end

function modifier_item_witchbane_custom:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_witchbane_custom:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_witchbane_custom:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_witchbane_custom:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_witchbane_custom:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end