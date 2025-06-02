LinkLuaModifier("modifier_talent_lina_2", "heroes/hero_lina/talents/talent_lina_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_lina_2_dragon_slave_debuff", "heroes/hero_lina/talents/talent_lina_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

talent_lina_2 = class(ItemBaseClass)
modifier_talent_lina_2 = class(talent_lina_2)
modifier_talent_lina_2_dragon_slave_debuff = class(ItemBaseClassDebuff)
-------------
function talent_lina_2:GetIntrinsicModifierName()
    return "modifier_talent_lina_2"
end
-------------
function modifier_talent_lina_2:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_talent_lina_2:GetModifierTotalDamageOutgoing_Percentage(event)
    local parent = self:GetParent()

    if event.attacker ~= parent then return end
    if not event.inflictor then return end

    local ability = self:GetAbility()
    local target = event.target

    if event.inflictor:GetAbilityName() == "lina_light_strike_array_custom" then
        local chance = ability:GetSpecialValueFor("chance_to_stun_vs_non_heroes")
        if RollPercentage(chance) then
            target:AddNewModifier(parent, nil, "modifier_stunned", {
                duration = ability:GetSpecialValueFor("stun_duration")
            })
        end
    end

    if event.inflictor:GetAbilityName() == "lina_dragon_slave_custom" then
        local debuff = target:FindModifierByName("modifier_talent_lina_2_dragon_slave_debuff")
        if not debuff then
            debuff = target:AddNewModifier(parent, ability, "modifier_talent_lina_2_dragon_slave_debuff", {
                duration = ability:GetSpecialValueFor("debuff_duration")
            })
        end

        if debuff then
            debuff:ForceRefresh()
        end

        return ability:GetSpecialValueFor("bonus_dmg_vs_non_heroes_pct")
    end
end
------------
function modifier_talent_lina_2_dragon_slave_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE  
    }
end

function modifier_talent_lina_2_dragon_slave_debuff:GetModifierIncomingDamage_Percentage(event)
    local ability = self:GetAbility()
    
    return ability:GetSpecialValueFor("debuff_dmg_increase_pct")
end