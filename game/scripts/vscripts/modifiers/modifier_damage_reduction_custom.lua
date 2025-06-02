LinkLuaModifier("modifier_damage_reduction_custom", "modifiers/modifier_damage_reduction_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
}

damage_reduction_custom = class(ItemBaseClass)
modifier_damage_reduction_custom = class(damage_reduction_custom)
-------------
function damage_reduction_custom:GetIntrinsicModifierName()
    return "modifier_damage_reduction_custom"
end

function modifier_damage_reduction_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local parent = self:GetParent()

    local id = parent:GetPlayerID()
    if id == nil or not id then return end
    self.accountID = PlayerResource:GetSteamAccountID(id)
    if self.accountID == nil or not self.accountID then return end

    self:OnIntervalThink()

    self:StartIntervalThink(0.1)
end

function modifier_damage_reduction_custom:OnIntervalThink()
    self.num = GetPlayerDamageReduction(self.accountID)
    
    self:Invoke()
end

function modifier_damage_reduction_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, --GetModifierIncomingDamage_Percentage
    }

    return funcs
end

function modifier_damage_reduction_custom:GetModifierIncomingDamage_Percentage(event)
    if event.target ~= self:GetParent() or bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return end

    local reduction = self.fNum

    if reduction ~= nil and reduction > 98 then
        reduction = 98
    end

    return reduction
end

function modifier_damage_reduction_custom:AddCustomTransmitterData()
    return
    {
        num = self.fNum,
    }
end

function modifier_damage_reduction_custom:HandleCustomTransmitterData(data)
    if data.num ~= nil then
        self.fNum = tonumber(data.num)
    end
end

function modifier_damage_reduction_custom:Invoke()
    if IsServer() == true then
        self.fNum = self.num

        self:SendBuffRefreshToClients()
    end
end