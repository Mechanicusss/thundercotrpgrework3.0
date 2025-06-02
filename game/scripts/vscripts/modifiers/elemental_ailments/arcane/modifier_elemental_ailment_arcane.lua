
local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

modifier_elemental_ailment_arcane = class(BaseClass)
----------------------------------------------------------------
--[[
function modifier_elemental_ailment_arcane:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(0.1)
end

function modifier_elemental_ailment_arcane:OnIntervalThink()
    local parent = self:GetParent()

    local mana = (parent:GetMaxMana()*0.001*0.1*self:GetStackCount())

    parent:SpendMana(mana, nil)
end

function modifier_elemental_ailment_arcane:GetEffectName()
    return "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot_slow_debuff.vpcf"
end

function modifier_elemental_ailment_arcane:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE    
    }
end

function modifier_elemental_ailment_arcane:GetModifierPercentageCooldown()
    return -1 * self:GetStackCount()
end
--]]