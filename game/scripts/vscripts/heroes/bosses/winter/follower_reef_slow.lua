LinkLuaModifier("modifier_follower_reef_slow", "heroes/bosses/winter/follower_reef_slow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_follower_reef_slow_debuff", "heroes/bosses/winter/follower_reef_slow", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

follower_reef_slow = class(ItemBaseClass)
modifier_follower_reef_slow = class(follower_reef_slow)
modifier_follower_reef_slow_debuff = class(ItemBaseClassDebuff)
-------------
function follower_reef_slow:GetIntrinsicModifierName()
    return "modifier_follower_reef_slow"
end

function modifier_follower_reef_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_follower_reef_slow:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end

    event.target:AddNewModifier(parent, self:GetAbility(), "modifier_follower_reef_slow_debuff", {
        duration = self:GetAbility():GetSpecialValueFor("duration")
    })
end
-------
function modifier_follower_reef_slow_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT  
    }
end

function modifier_follower_reef_slow_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_follower_reef_slow_debuff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_follower_reef_slow_debuff:GetEffectName()
    return "particles/status_fx/status_effect_drow_frost_arrow.vpcf"
end