LinkLuaModifier("modifier_creature_pitlord_adaptation", "creeps/creature_pitlord_pitofmalice/creature_pitlord_adaptation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_max_movement_speed", "modifiers/modifier_max_movement_speed", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

creature_pitlord_adaptation = class(ItemBaseClass)
modifier_creature_pitlord_adaptation = class(creature_pitlord_adaptation)
-------------
function creature_pitlord_adaptation:GetIntrinsicModifierName()
    return "modifier_creature_pitlord_adaptation"
end

function modifier_creature_pitlord_adaptation:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }
end

function modifier_creature_pitlord_adaptation:GetModifierMoveSpeedBonus_Constant()
    return self.fDamage
end

function modifier_creature_pitlord_adaptation:GetModifierAttackSpeedBonus_Constant()
    return self.fDamage
end

function modifier_creature_pitlord_adaptation:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:AddNewModifier(parent, nil, "modifier_max_movement_speed", {})

    self.damage = 0

    self:StartIntervalThink(1)
end

function modifier_creature_pitlord_adaptation:OnIntervalThink()
    self.damage = self.damage + self:GetAbility():GetSpecialValueFor("movespeed_increase")

    self:InvokeBonusDamage()
end

function modifier_creature_pitlord_adaptation:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_creature_pitlord_adaptation:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_creature_pitlord_adaptation:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end