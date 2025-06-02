LinkLuaModifier("modifier_item_primal_spire", "items/item_primal_spire/item_primal_spire", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_primal_spire = class(ItemBaseClass)
item_primal_spire_2 = item_primal_spire
item_primal_spire_3 = item_primal_spire
item_primal_spire_4 = item_primal_spire
item_primal_spire_5 = item_primal_spire
item_primal_spire_6 = item_primal_spire
item_primal_spire_7 = item_primal_spire
modifier_item_primal_spire = class(item_primal_spire)
-------------
function item_primal_spire:GetIntrinsicModifierName()
    return "modifier_item_primal_spire"
end

function modifier_item_primal_spire:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
    }

    return funcs
end

function modifier_item_primal_spire:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.attribute = self:GetParent():GetPrimaryAttribute()

    self.strength = self:GetParent():GetStrength()
    self.agility = self:GetParent():GetAgility()
    self.intellect = self:GetParent():GetBaseIntellect()

    self:InvokeAttribute()

    self:StartIntervalThink(0.1)
end

function modifier_item_primal_spire:OnIntervalThink()
    if self.attribute == DOTA_ATTRIBUTE_STRENGTH then
        if self:GetParent():GetStrength() > self.strength then
            self.strength = self:GetParent():GetStrength()
            self:InvokeAttribute()
        end
    else
        if self:GetParent():GetStrength() < self.strength then
            self.strength = self:GetParent():GetStrength()
            self:InvokeAttribute()
        end
    end

    if self.attribute == DOTA_ATTRIBUTE_AGILITY then
        if self:GetParent():GetAgility() > self.agility then
            self.agility = self:GetParent():GetAgility()
            self:InvokeAttribute()
        end
    else
        if self:GetParent():GetAgility() < self.agility then
            self.agility = self:GetParent():GetAgility()
            self:InvokeAttribute()
        end
    end

    if self.attribute == DOTA_ATTRIBUTE_INTELLECT then
        if self:GetParent():GetBaseIntellect() > self.intellect then
            self.intellect = self:GetParent():GetBaseIntellect()
            self:InvokeAttribute()
        end
    else
        if self:GetParent():GetBaseIntellect() < self.intellect then
            self.intellect = self:GetParent():GetBaseIntellect()
            self:InvokeAttribute()
        end
    end
end

function modifier_item_primal_spire:GetModifierBonusStats_Strength()
    if self.attribute == DOTA_ATTRIBUTE_STRENGTH then
        return self.fStrength
    elseif self.fStrength ~= nil then
        return math.abs(self.fStrength)*-1
    end
end

function modifier_item_primal_spire:GetModifierBonusStats_Agility()
    if self.attribute == DOTA_ATTRIBUTE_AGILITY then
        return self.fAgility
    elseif self.fAgility ~= nil then
        return math.abs(self.fAgility)*-1
    end
end

function modifier_item_primal_spire:GetModifierBonusStats_Intellect()
    if self.attribute == DOTA_ATTRIBUTE_INTELLECT then
        return self.fIntellect
    elseif self.fIntellect ~= nil then
        return math.abs(self.fIntellect)*-1
    end
end

function modifier_item_primal_spire:AddCustomTransmitterData()
    return
    {
        attribute = self.fAttribute,
        strength = self.fStrength,
        agility = self.fAgility,
        intellect = self.fIntellect,
    }
end

function modifier_item_primal_spire:HandleCustomTransmitterData(data)
    if data.attribute ~= nil and data.strength ~= nil and data.agility ~= nil and data.intellect ~= nil then
        self.fAttribute = tonumber(data.attribute)
        self.fStrength = tonumber(data.strength)
        self.fAgility = tonumber(data.agility)
        self.fIntellect = tonumber(data.intellect)
    end
end

function modifier_item_primal_spire:InvokeAttribute()
    if IsServer() == true then
        self.fAttribute = self.attribute
        self.fStrength = self.strength
        self.fAgility = self.agility
        self.fIntellect = self.intellect

        self:SendBuffRefreshToClients()
    end
end