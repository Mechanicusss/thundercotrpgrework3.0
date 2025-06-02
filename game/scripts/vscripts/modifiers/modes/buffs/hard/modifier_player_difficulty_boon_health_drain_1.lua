LinkLuaModifier("modifier_player_difficulty_boon_health_drain_1", "modifiers/modes/buffs/hard/modifier_player_difficulty_boon_health_drain_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_health_drain_1 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_health_drain_1 = class(ItemBaseClass)

function player_difficulty_boon_health_drain_1:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_health_drain_1"
end

function modifier_player_difficulty_boon_health_drain_1:GetTexture() return "wtf" end
-------------

function modifier_player_difficulty_boon_health_drain_1:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_player_difficulty_boon_health_drain_1:OnIntervalThink()
    if self:GetParent():IsMagicImmune() or self:GetParent():IsInvulnerable() then return end
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetParent(),
        damage = (self:GetParent():GetHealth() * 0.01) * 0.1,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
    })
end