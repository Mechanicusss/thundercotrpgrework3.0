LinkLuaModifier("modifier_player_difficulty_boon_ally_proximity_debuff_1", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_ally_proximity_debuff_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_difficulty_boon_ally_proximity_debuff_1_stacks", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_ally_proximity_debuff_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_ally_proximity_debuff_1 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_ally_proximity_debuff_1_stacks = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
})

modifier_player_difficulty_boon_ally_proximity_debuff_1 = class(ItemBaseClass)

function player_difficulty_boon_ally_proximity_debuff_1:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_ally_proximity_debuff_1"
end

function modifier_player_difficulty_boon_ally_proximity_debuff_1_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_player_difficulty_boon_ally_proximity_debuff_1:GetTexture() return "arena/anakim_stats_heroes" end
function modifier_player_difficulty_boon_ally_proximity_debuff_1_stacks:GetTexture() return "arena/anakim_stats_heroes" end
-------------

function modifier_player_difficulty_boon_ally_proximity_debuff_1:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1.0)
end

function modifier_player_difficulty_boon_ally_proximity_debuff_1:OnIntervalThink()
    local caster = self:GetCaster()
    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        300, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #victims > 1  then
        local mod = caster:FindModifierByNameAndCaster("modifier_player_difficulty_boon_ally_proximity_debuff_1_stacks", caster)
        if mod == nil then
            mod = caster:AddNewModifier(caster, self:GetAbility(), "modifier_player_difficulty_boon_ally_proximity_debuff_1_stacks", { duration = 3.0 })
        else
            mod:IncrementStackCount()
            mod:ForceRefresh()
        end
    end
end
---

function modifier_player_difficulty_boon_ally_proximity_debuff_1_stacks:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_player_difficulty_boon_ally_proximity_debuff_1_stacks:OnIntervalThink()
    if self:GetParent():IsMagicImmune() or self:GetParent():IsInvulnerable() then return end
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetParent(),
        damage = ((self:GetParent():GetMaxHealth() * 0.01)) * self:GetStackCount(),
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
    })
end