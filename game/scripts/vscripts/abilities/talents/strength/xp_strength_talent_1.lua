LinkLuaModifier("modifier_xp_strength_talent_1", "abilities/talents/strength/xp_strength_talent_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_strength_talent_1 = class(ItemBaseClass)
modifier_xp_strength_talent_1 = class(xp_strength_talent_1)
-------------
function xp_strength_talent_1:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_1"
end
-------------
function modifier_xp_strength_talent_1:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self:StartIntervalThink(0.1)
end

function modifier_xp_strength_talent_1:AddCustomTransmitterData()
    return
    {
        str = self.fStr,
    }
end

function modifier_xp_strength_talent_1:HandleCustomTransmitterData(data)
    if data.str ~= nil then
        self.fStr = tonumber(data.str)
    end
end

function modifier_xp_strength_talent_1:InvokeBonusStr()
    if IsServer() == true then
        self.fStr = self.str

        self:SendBuffRefreshToClients()
    end
end

function modifier_xp_strength_talent_1:OnIntervalThink()
    self.str = self:GetParent():GetBaseStrength() * ((2/100) * self:GetStackCount())

    self:InvokeBonusStr()
end

function modifier_xp_strength_talent_1:OnDestroy()
end

function modifier_xp_strength_talent_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS  
    }
end

function modifier_xp_strength_talent_1:GetModifierBonusStats_Strength()
    return self.fStr
end