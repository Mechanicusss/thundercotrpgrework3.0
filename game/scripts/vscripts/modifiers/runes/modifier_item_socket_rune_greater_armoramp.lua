LinkLuaModifier("modifier_item_socket_rune_greater_armoramp", "modifiers/runes/modifier_item_socket_rune_greater_armoramp", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_greater_armoramp = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_greater_armoramp:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }

    return funcs
end

function modifier_item_socket_rune_greater_armoramp:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_item_socket_rune_greater_armoramp:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
    }
end

function modifier_item_socket_rune_greater_armoramp:HandleCustomTransmitterData(data)
    if data.armor ~= nil then
        self.fArmor = tonumber(data.armor)
    end
end

function modifier_item_socket_rune_greater_armoramp:InvokeBonus()
    if IsServer() == true then
        self.fArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_socket_rune_greater_armoramp:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end
    
    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_item_socket_rune_greater_armoramp:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local armor = 16 * self:GetStackCount()

    self.armor = parent:GetPhysicalArmorBaseValue() * (armor/100)

    self:InvokeBonus()
end