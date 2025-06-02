LinkLuaModifier("modifier_xp_agility_talent_3", "abilities/talents/agility/xp_agility_talent_3", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_agility_talent_3 = class(ItemBaseClass)
modifier_xp_agility_talent_3 = class(xp_agility_talent_3)
-------------
function xp_agility_talent_3:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_3"
end
-------------
function modifier_xp_agility_talent_3:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self:StartIntervalThink(0.1)
end

function modifier_xp_agility_talent_3:AddCustomTransmitterData()
    return
    {
        agi = self.fAgi,
    }
end

function modifier_xp_agility_talent_3:HandleCustomTransmitterData(data)
    if data.agi ~= nil then
        self.fAgi = tonumber(data.agi)
    end
end

function modifier_xp_agility_talent_3:InvokeBonusAgi()
    if IsServer() == true then
        self.fAgi = self.agi

        self:SendBuffRefreshToClients()
    end
end

function modifier_xp_agility_talent_3:OnIntervalThink()
    self.agi = self:GetParent():GetBaseAgility() * ((2/100) * self:GetStackCount())

    self:InvokeBonusAgi()
end

function modifier_xp_agility_talent_3:OnDestroy()
end

function modifier_xp_agility_talent_3:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS  
    }
end

function modifier_xp_agility_talent_3:GetModifierBonusStats_Agility()
    return self.fAgi
end