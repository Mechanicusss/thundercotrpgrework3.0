
local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

modifier_elemental_ailment_necrotic = class(BaseClass)
----------------------------------------------------------------
function modifier_elemental_ailment_necrotic:OnCreated()
    if not IsServer() then return end 
end

function modifier_elemental_ailment_necrotic:GetEffectName()
    return "particles/units/heroes/hero_abaddon/abaddon_curse_frostmourne_debuff.vpcf"
end

function modifier_elemental_ailment_necrotic:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE   
    }
end

function modifier_elemental_ailment_necrotic:GetModifierExtraHealthPercentage()
    return -20
end