modifier_garbage_collector_fix = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

function modifier_garbage_collector_fix:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_RESPAWN  
    }
end

function modifier_garbage_collector_fix:OnRespawn(event)
    print("respawned (no check):", event.unit:GetUnitName())

    if event.unit ~= self:GetParent() then return end 

    print("respawned:", event.unit:GetUnitName())
end