LinkLuaModifier("modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75", "modifiers/modes/buffs/impossible/modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_reduced_healing_75 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75 = class(ItemBaseClass)

function player_difficulty_boon_reduced_healing_75:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75"
end

function modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75:GetTexture() return "wtf_drain" end

function modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }

    return funcs
end

function modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75:OnIntervalThink()
    if self:GetParent():IsMagicImmune() or self:GetParent():IsInvulnerable() then return end

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetParent(),
        damage = (self:GetParent():GetHealth() * 0.05) * 0.1,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
    })
end

function modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75:GetModifierHealAmplify_PercentageTarget()
    return -75
end

function modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75:GetModifierHPRegenAmplify_Percentage()
    return -75
end

function modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75:GetModifierLifestealRegenAmplify_Percentage()
    return -75
end

function modifier_player_difficulty_boon_reduced_healing_and_health_drain_5_75:GetModifierSpellLifestealRegenAmplify_Percentage()
    return -75
end
-------------