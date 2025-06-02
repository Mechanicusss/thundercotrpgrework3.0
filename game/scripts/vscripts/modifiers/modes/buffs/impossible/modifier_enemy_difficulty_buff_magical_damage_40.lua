LinkLuaModifier("modifier_enemy_difficulty_buff_magical_damage_40", "modifiers/modes/buffs/impossible/modifier_enemy_difficulty_buff_magical_damage_40", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_magical_damage_40 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_magical_damage_40 = class(ItemBaseClass)


function enemy_difficulty_buff_magical_damage_40:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_magical_damage_40"
end

function modifier_enemy_difficulty_buff_magical_damage_40:GetTexture() return "magicdmg" end
-------------
function modifier_enemy_difficulty_buff_magical_damage_40:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    
    self.damage = parent:GetAverageTrueAttackDamage(parent) * 0.05

    self.damageTable = {
        attacker = parent,
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
    }
end

function modifier_enemy_difficulty_buff_magical_damage_40:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_enemy_difficulty_buff_magical_damage_40:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.target:IsMagicImmune() or event.target:IsInvulnerable() then return end
        
    self.damageTable.victim = event.target

    ApplyDamage(self.damageTable)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, event.target, self.damage, nil)
end
---