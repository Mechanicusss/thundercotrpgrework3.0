
local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_elemental_ailment_arcane_immunity = class(BaseClass)
----------------------------------------------------------------
function modifier_elemental_ailment_arcane_immunity:OnCreated()
end