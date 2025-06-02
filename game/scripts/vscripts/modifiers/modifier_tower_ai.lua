LinkLuaModifier("modifier_tower_ai", "modifiers/modifier_tower_ai", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

tower_ai = class(BaseClass)
modifier_tower_ai = class(tower_ai)
-------------
function tower_ai:GetIntrinsicModifierName()
    return "modifier_tower_ai"
end

function modifier_tower_ai:OnCreated()
    if not IsServer() then return end

    self.unit = self:GetParent()

    self.target = nil

    self:StartIntervalThink(0.1)
end

function modifier_tower_ai:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH 
    }
end

function modifier_tower_ai:OnDeath(event)
    if self.unit ~= event.attacker then return end

    self.target =  nil
end

function modifier_tower_ai:OnIntervalThink()
    print("think")
    if self.target == nil then
        print("searching")
        local enemies = FindUnitsInRadius(self.unit:GetTeam(), self.unit:GetAbsOrigin(), nil,
            self.unit:Script_GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        print(#enemies)

        if #enemies > 0 then
            self.target = enemies[1]
        end
    end

    self.unit:SetForceAttackTarget(self.target)
end

function modifier_tower_ai:DeclareFunctions()
    local funcs = { 
        MODIFIER_STATE_PROVIDES_VISION 
    }
    return funcs
end

function modifier_tower_ai:GetModifierProvidesFOWVision()
    return 1
end