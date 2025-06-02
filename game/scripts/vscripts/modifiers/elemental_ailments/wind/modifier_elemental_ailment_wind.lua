
local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

modifier_elemental_ailment_wind = class(BaseClass)
----------------------------------------------------------------
function modifier_elemental_ailment_wind:OnCreated()
    if not IsServer() then return end 
end

function modifier_elemental_ailment_wind:GetEffectName()
    return "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf"
end

function modifier_elemental_ailment_wind:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE   
    }
end

function modifier_elemental_ailment_wind:GetModifierExtraHealthPercentage()
    return -20
end