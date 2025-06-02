LinkLuaModifier("modifier_item_monkey_king_bar_custom", "items/item_monkey_king_bar_custom/item_monkey_king_bar_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_monkey_king_bar_custom = class(ItemBaseClass)
item_monkey_king_bar_custom2 = item_monkey_king_bar_custom
item_monkey_king_bar_custom3 = item_monkey_king_bar_custom
item_monkey_king_bar_custom4 = item_monkey_king_bar_custom
item_monkey_king_bar_custom5 = item_monkey_king_bar_custom
item_monkey_king_bar_custom6 = item_monkey_king_bar_custom
item_monkey_king_bar_custom7 = item_monkey_king_bar_custom
modifier_item_monkey_king_bar_custom = class(item_monkey_king_bar_custom)
-------------
function item_monkey_king_bar_custom:GetIntrinsicModifierName()
    return "modifier_item_monkey_king_bar_custom"
end

function modifier_item_monkey_king_bar_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }
    return funcs
end

function modifier_item_monkey_king_bar_custom:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_MISS] = true
    }
end

function modifier_item_monkey_king_bar_custom:GetModifierAttackRangeBonus()
    if self:GetParent():IsRangedAttacker() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_melee_range")
end

function modifier_item_monkey_king_bar_custom:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_monkey_king_bar_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_monkey_king_bar_custom:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()
    
    if not RollPercentage(ability:GetSpecialValueFor("bonus_chance")) then return end

    local damage = unit:GetAverageTrueAttackDamage(unit) * (ability:GetSpecialValueFor("bonus_chance_damage")/100)

    ApplyDamage({
        victim = victim,
        attacker = unit,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, damage, nil)

    EmitSoundOn("DOTA_Item.MKB.Minibash", victim)
end