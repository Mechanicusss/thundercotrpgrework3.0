LinkLuaModifier("modifier_apocalypse_magic_resistance", "modifiers/apocalypse_modifiers/magic_resistance", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_magic_resistance = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_magic_resistance = class(ItemBaseClass)

function modifier_apocalypse_magic_resistance:GetIntrinsicModifierName()
    return "modifier_apocalypse_magic_resistance"
end

function modifier_apocalypse_magic_resistance:GetTexture() return "magicres" end
-------------
function modifier_apocalypse_magic_resistance:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS ,  
    }

    return funcs
end

function modifier_apocalypse_magic_resistance:GetModifierMagicalResistanceBonus()
    return 30
end