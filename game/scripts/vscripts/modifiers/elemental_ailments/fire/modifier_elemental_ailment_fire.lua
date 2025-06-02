
local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

modifier_elemental_ailment_fire = class(BaseClass)
----------------------------------------------------------------
function modifier_elemental_ailment_fire:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local caster = self:GetCaster()

    self.damageTable = {
        attacker = caster,
        victim = parent,
        damage_type = DAMAGE_TYPE_MAGICAL,
    }

    self:StartIntervalThink(1)
end

function modifier_elemental_ailment_fire:OnIntervalThink()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local caster = self:GetCaster()
    
    self.damageTable.damage = (parent:GetHealth() * 0.02) * self:GetStackCount()

    ApplyDamage(self.damageTable)
end

function modifier_elemental_ailment_fire:GetEffectName()
    return "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf"
end