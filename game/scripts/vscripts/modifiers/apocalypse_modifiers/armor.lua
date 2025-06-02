LinkLuaModifier("modifier_apocalypse_armor", "modifiers/apocalypse_modifiers/armor", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_armor = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_armor = class(ItemBaseClass)

function modifier_apocalypse_armor:GetIntrinsicModifierName()
    return "modifier_apocalypse_armor"
end

function modifier_apocalypse_armor:GetTexture() return "shield" end
-------------
function modifier_apocalypse_armor:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,  
    }

    return funcs
end

function modifier_apocalypse_armor:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()
end

function modifier_apocalypse_armor:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    local multiplier = 0.3

    self.armor = parent:GetPhysicalArmorBaseValue() * multiplier

    self:InvokeBonus()
end

function modifier_apocalypse_armor:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_apocalypse_armor:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
    }
end

function modifier_apocalypse_armor:HandleCustomTransmitterData(data)
    if data.armor ~= nil then
        self.fArmor = tonumber(data.armor)
    end
end

function modifier_apocalypse_armor:InvokeBonus()
    if IsServer() == true then
        self.fArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end