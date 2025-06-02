LinkLuaModifier("modifier_player_buffs_attack_sacrifice", "modifiers/player_buffs/modifier_player_buffs_attack_sacrifice", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_attack_sacrifice = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_attack_sacrifice = class(ItemBaseClass)

function modifier_player_buffs_attack_sacrifice:GetIntrinsicModifierName()
    return "modifier_player_buffs_attack_sacrifice"
end

function modifier_player_buffs_attack_sacrifice:GetTexture() return "player_buffs/modifier_player_buffs_attack_sacrifice" end
-------------
function modifier_player_buffs_attack_sacrifice:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK, 
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, 
    }

    return funcs
end

function modifier_player_buffs_attack_sacrifice:GetModifierDamageOutgoing_Percentage()
    return 50
end

function modifier_player_buffs_attack_sacrifice:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local damage = parent:GetHealth() * 0.025

    ApplyDamage({
        attacker = parent,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NON_LETHAL,
    })
end