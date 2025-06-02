LinkLuaModifier("modifier_razor_unstable_current_custom", "heroes/hero_razor/razor_unstable_current_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

razor_unstable_current_custom = class(ItemBaseClass)
modifier_razor_unstable_current_custom = class(razor_unstable_current_custom)
-------------
function razor_unstable_current_custom:GetIntrinsicModifierName()
    return "modifier_razor_unstable_current_custom"
end
------------
function modifier_razor_unstable_current_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)
    
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.damage = 0
    self.checkPoint = parent:GetAbsOrigin()
    self.distanceMoved = 0 

    self:StartIntervalThink(0.1)
end

function modifier_razor_unstable_current_custom:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()

    local speed = parent:GetIdealSpeedNoSlows()

    self.damage = speed * (self:GetAbility():GetSpecialValueFor("distance_to_damage")/100)
    self:InvokeBonusDamage()
end

function modifier_razor_unstable_current_custom:OnIntervalThink()
    local parent = self:GetParent()

    --if not parent:IsMoving() then return end

    --local speed = parent:GetIdealSpeedNoSlows()

    --local distance = (parent:GetAbsOrigin() - self.checkPoint):Length2D()
    --if distance > 10 then
    --    self.checkPoint = parent:GetAbsOrigin()
    --    self.distanceMoved = self.distanceMoved + 10
    --end

    self:OnRefresh()
end

function modifier_razor_unstable_current_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_razor_unstable_current_custom:GetModifierDamageOutgoing_Percentage()
    return self.fDamage
end

function modifier_razor_unstable_current_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end

function modifier_razor_unstable_current_custom:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_razor_unstable_current_custom:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_razor_unstable_current_custom:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end