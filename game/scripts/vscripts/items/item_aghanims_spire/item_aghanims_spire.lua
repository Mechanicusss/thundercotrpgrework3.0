LinkLuaModifier("modifier_item_aghanims_spire", "items/item_aghanims_spire/item_aghanims_spire", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_aghanims_spire = class(ItemBaseClass)
modifier_item_aghanims_spire = class(item_aghanims_spire)
-------------
function item_aghanims_spire:GetIntrinsicModifierName()
    return "modifier_item_aghanims_spire"
end
-----------------
function modifier_item_aghanims_spire:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_item_aghanims_spire:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    
end