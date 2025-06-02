LinkLuaModifier("modifier_apocalypse_evasion", "modifiers/apocalypse_modifiers/evasion", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_evasion = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_evasion = class(ItemBaseClass)

function modifier_apocalypse_evasion:GetIntrinsicModifierName()
    return "modifier_apocalypse_evasion"
end

function modifier_apocalypse_evasion:GetTexture() return "butterfly" end
-------------
function modifier_apocalypse_evasion:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_EVASION_CONSTANT ,  
    }

    return funcs
end

function modifier_apocalypse_evasion:GetModifierEvasion_Constant()
    return 30
end