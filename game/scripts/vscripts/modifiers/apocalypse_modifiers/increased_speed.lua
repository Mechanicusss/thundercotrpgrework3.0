LinkLuaModifier("modifier_apocalypse_increased_speed", "modifiers/apocalypse_modifiers/increased_speed", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_increased_speed = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_increased_speed = class(ItemBaseClass)

function modifier_apocalypse_increased_speed:GetIntrinsicModifierName()
    return "modifier_apocalypse_increased_speed"
end

function modifier_apocalypse_increased_speed:GetTexture() return "speed" end
-------------
function modifier_apocalypse_increased_speed:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,  
    }

    return funcs
end

function modifier_apocalypse_increased_speed:GetModifierMoveSpeedBonus_Percentage()
    return 50
end