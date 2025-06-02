LinkLuaModifier("modifier_xp_agility_talent_6", "abilities/talents/agility/xp_agility_talent_6", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_agility_talent_6 = class(ItemBaseClass)
modifier_xp_agility_talent_6 = class(xp_agility_talent_6)
-------------
function xp_agility_talent_6:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_6"
end
-------------
function modifier_xp_agility_talent_6:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self:StartIntervalThink(0.1)
end

function modifier_xp_agility_talent_6:AddCustomTransmitterData()
    return
    {
        speed = self.fSpeed,
    }
end

function modifier_xp_agility_talent_6:HandleCustomTransmitterData(data)
    if data.speed ~= nil then
        self.fSpeed = tonumber(data.speed)
    end
end

function modifier_xp_agility_talent_6:InvokeBonusspeed()
    if IsServer() == true then
        self.fSpeed = self.speed

        self:SendBuffRefreshToClients()
    end
end

function modifier_xp_agility_talent_6:OnIntervalThink()
    self.speed = (self:GetParent():GetEvasion() * 100) * ((3/100) * self:GetStackCount())

    self:InvokeBonusspeed()
end

function modifier_xp_agility_talent_6:OnDestroy()
end

function modifier_xp_agility_talent_6:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE    
    }
end

function modifier_xp_agility_talent_6:GetModifierMoveSpeedBonus_Percentage()
    return self.fSpeed
end