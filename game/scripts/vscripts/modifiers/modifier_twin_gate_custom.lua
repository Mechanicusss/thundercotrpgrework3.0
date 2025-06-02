-- Custom Twin Gate implementation requires use of the order filter
LinkLuaModifier("modifier_twin_gate_custom", "modifiers/modifier_twin_gate_custom", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_twin_gate_custom = class(BaseClass)
modifier_twin_gate_custom = class(modifier_twin_gate_custom)
-------------
function modifier_twin_gate_custom:GetIntrinsicModifierName()
    return "modifier_twin_gate_custom"
end

function modifier_twin_gate_custom:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_invulnerable")
end

function modifier_twin_gate_custom:CheckState()
    return {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    }
end

function modifier_twin_gate_custom:CanParentBeAutoAttacked()
    return false
end