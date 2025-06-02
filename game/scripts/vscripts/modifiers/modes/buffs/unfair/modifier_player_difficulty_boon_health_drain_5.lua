LinkLuaModifier("modifier_player_difficulty_boon_health_drain_5", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_health_drain_5", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_health_drain_5 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_health_drain_5 = class(ItemBaseClass)

function player_difficulty_boon_health_drain_5:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_health_drain_5"
end

function modifier_player_difficulty_boon_health_drain_5:GetTexture() return "wtf" end
-------------

function modifier_player_difficulty_boon_health_drain_5:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_player_difficulty_boon_health_drain_5:OnIntervalThink()
    local parent = self:GetParent()
    if parent:IsMagicImmune() or parent:IsInvulnerable() then return end
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetParent(),
        damage = (self:GetParent():GetHealth() * 0.03),
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
    })
end