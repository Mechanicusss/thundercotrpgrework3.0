LinkLuaModifier("modifier_movement_speed_uba", "modifiers/modifier_movement_speed_uba", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

movement_speed_uba = class(ItemBaseClass)
modifier_movement_speed_uba = class(movement_speed_uba)

-----------------
function movement_speed_uba:GetIntrinsicModifierName()
    return "modifier_movement_speed_uba"
end
-----------------
function modifier_movement_speed_uba:AddCustomTransmitterData()
    return
    {
        speed = self.fBonusSpeed,
    }
end

function modifier_movement_speed_uba:HandleCustomTransmitterData(data)
    if data.speed ~= nil then
        self.fBonusSpeed = tonumber(data.speed)
    end
end

function modifier_movement_speed_uba:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    self.speed = params.speed

    self:InvokeBonusSpeed()
end

function modifier_movement_speed_uba:OnRemoved(params)
    self.speed = 0

    self:InvokeBonusSpeed()
end

function modifier_movement_speed_uba:InvokeBonusSpeed()
    if IsServer() == true then
        self.fBonusSpeed = self.speed

        self:SendBuffRefreshToClients()
    end
end

function modifier_movement_speed_uba:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT
    }

    return funcs
end

function modifier_movement_speed_uba:GetModifierMoveSpeedBonus_Constant()
    return self.fBonusSpeed
end
