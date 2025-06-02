
local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

modifier_elemental_ailment_lightning = class(BaseClass)
modifier_elemental_ailment_lightning_shock = class(BaseClass)
----------------------------------------------------------------
function modifier_elemental_ailment_lightning:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(1)
end

function modifier_elemental_ailment_lightning:OnIntervalThink()
    local parent = self:GetParent()

    parent:AddNewModifier(self:GetCaster(), nil, "modifier_elemental_ailment_lightning_shock", { duration = 0.25 })
    
    EmitSoundOn("Hero_Zuus.StaticField", parent)
end
----------------------------------------------------------------
function modifier_elemental_ailment_lightning_shock:GetEffectName()
    return "particles/econ/items/disruptor/disruptor_2022_immortal/disruptor_2022_immortal_static_storm_hero_debuff.vpcf"
end

function modifier_elemental_ailment_lightning_shock:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end