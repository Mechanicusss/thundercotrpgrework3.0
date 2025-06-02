LinkLuaModifier("modifier_talent_bristleback_1", "heroes/hero_bristleback/talents/talent_bristleback_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_bristleback_1_debuff", "heroes/hero_bristleback/talents/talent_bristleback_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

talent_bristleback_1 = class(ItemBaseClass)
modifier_talent_bristleback_1 = class(talent_bristleback_1)
modifier_talent_bristleback_1_debuff = class(ItemBaseClassDebuff)
-------------
function talent_bristleback_1:GetIntrinsicModifierName()
    return "modifier_talent_bristleback_1"
end
---------------------
function modifier_talent_bristleback_1_debuff:OnCreated(params)
    if not IsServer() then return end

    self.damage = params.damage

    self.damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        ability = self:GetAbility(),
        damage_type = DAMAGE_TYPE_MAGICAL,
    }

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    self:StartIntervalThink(interval)
end

function modifier_talent_bristleback_1_debuff:OnIntervalThink()
    if not self:GetCaster():HasModifier("modifier_talent_bristleback_1") then self:Destroy() return end

    self.damageTable.damage = self.damage * self:GetStackCount()
    
    ApplyDamage(self.damageTable)
end