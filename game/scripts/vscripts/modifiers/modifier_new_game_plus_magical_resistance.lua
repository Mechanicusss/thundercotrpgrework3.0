LinkLuaModifier("modifier_new_game_plus_magical_resistance", "modifiers/modifier_new_game_plus_magical_resistance", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

new_game_plus_magical_resistance = class(ItemBaseClass)
modifier_new_game_plus_magical_resistance = class(new_game_plus_magical_resistance)

-----------------
function new_game_plus_magical_resistance:GetIntrinsicModifierName()
    return "modifier_new_game_plus_magical_resistance"
end
-----------------
function modifier_new_game_plus_magical_resistance:AddCustomTransmitterData()
    return
    {
        magicResistance = self.fMagicResistance,
    }
end

function modifier_new_game_plus_magical_resistance:HandleCustomTransmitterData(data)
    if data.magicResistance ~= nil then
        self.fMagicResistance = tonumber(data.magicResistance)
    end
end

function modifier_new_game_plus_magical_resistance:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.magicResistance = self:GetParent():Script_GetMagicalArmorValue() * (NEW_GAME_PLUS_SCALING_MULTIPLIER^_G.NewGamePlusCounter)

    self:InvokeMagicResistance()
end

function modifier_new_game_plus_magical_resistance:OnRemoved()
    self.magicResistance = 0

    self:InvokeMagicResistance()
end

function modifier_new_game_plus_magical_resistance:InvokeMagicResistance()
    if IsServer() == true then
        self.fMagicResistance = self.magicResistance

        self:SendBuffRefreshToClients()
    end
end

function modifier_new_game_plus_magical_resistance:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function modifier_new_game_plus_magical_resistance:GetModifierMagicalResistanceBonus()
    return self.fMagicResistance
end
