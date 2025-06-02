LinkLuaModifier("modifier_apocalypse_attack_range", "modifiers/apocalypse_modifiers/attack_range", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_attack_range = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_attack_range = class(ItemBaseClass)

function modifier_apocalypse_attack_range:GetIntrinsicModifierName()
    return "modifier_apocalypse_attack_range"
end

function modifier_apocalypse_attack_range:GetTexture() return "dragonlance" end
-------------
function modifier_apocalypse_attack_range:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,  
    }

    return funcs
end

function modifier_apocalypse_attack_range:GetModifierAttackRangeBonus()
    return 300
end