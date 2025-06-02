LinkLuaModifier("modifier_enchantress_untouchable_custom", "creeps/untouchable", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enchantress_untouchable_custom_debuff", "creeps/untouchable", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    Isdebuff = function(self) return true end,
}

enchantress_untouchable_custom = class(ItemBaseClass)
modifier_enchantress_untouchable_custom = class(enchantress_untouchable_custom)
modifier_enchantress_untouchable_custom_debuff = class(ItemBaseClassDebuff)
-------------
function enchantress_untouchable_custom:GetIntrinsicModifierName()
    return "modifier_enchantress_untouchable_custom"
end


function modifier_enchantress_untouchable_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK 
    }
    return funcs
end

function modifier_enchantress_untouchable_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_enchantress_untouchable_custom:OnAttack(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if victim ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()
    
    unit:AddNewModifier(parent, ability, "modifier_enchantress_untouchable_custom_debuff", {
        duration = ability:GetSpecialValueFor("slow_duration")
    })
end
---
function modifier_enchantress_untouchable_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE 
    }

    return funcs
end

function modifier_enchantress_untouchable_custom_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("slow_attack_speed_pct")
end