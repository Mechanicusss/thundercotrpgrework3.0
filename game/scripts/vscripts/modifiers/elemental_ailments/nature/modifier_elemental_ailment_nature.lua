
local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

modifier_elemental_ailment_nature = class(BaseClass)
----------------------------------------------------------------
function modifier_elemental_ailment_nature:OnCreated()
    if not IsServer() then return end 
end

function modifier_elemental_ailment_nature:GetEffectName()
    return "particles/units/heroes/hero_furion/furion_sprout_damage.vpcf"
end

function modifier_elemental_ailment_nature:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE  
    }
end

function modifier_elemental_ailment_nature:GetModifierDamageOutgoing_Percentage()
    return -0.25 * self:GetStackCount()
end