LinkLuaModifier("modifier_apocalypse_magic_attacks", "modifiers/apocalypse_modifiers/magic_attacks", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_magic_attacks = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_magic_attacks = class(ItemBaseClass)

function modifier_apocalypse_magic_attacks:GetIntrinsicModifierName()
    return "modifier_apocalypse_magic_attacks"
end

function modifier_apocalypse_magic_attacks:GetTexture() return "magicdmg" end
-------------
function modifier_apocalypse_magic_attacks:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    local multiplier = 0.15

    self.damage = ((parent:GetBaseDamageMax()+parent:GetBaseDamageMin())/2) * multiplier

    self.damageTable = {
        attacker = parent,
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
    }
end

function modifier_apocalypse_magic_attacks:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
    return funcs
end

function modifier_apocalypse_magic_attacks:GetModifierDamageOutgoing_Percentage()
    return -15
end

function modifier_apocalypse_magic_attacks:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.target:IsMagicImmune() or event.target:IsInvulnerable() then return end
        
    self.damageTable.victim = event.target

    ApplyDamage(self.damageTable)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, event.target, self.damage, nil)
end
---