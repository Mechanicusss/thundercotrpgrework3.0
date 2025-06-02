LinkLuaModifier("modifier_player_difficulty_boon_random_speed_debuffs_30_60", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_random_speed_debuffs_30_60", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_difficulty_boon_random_speed_debuffs_30_60_debuff", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_random_speed_debuffs_30_60", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_random_speed_debuffs_30_60 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_random_speed_debuffs_30_60_debuff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})


modifier_player_difficulty_boon_random_speed_debuffs_30_60 = class(ItemBaseClass)

function player_difficulty_boon_random_speed_debuffs_30_60:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_random_speed_debuffs_30_60"
end

function modifier_player_difficulty_boon_random_speed_debuffs_30_60:GetTexture() return "wtf1" end
function modifier_player_difficulty_boon_random_speed_debuffs_30_60_debuff:GetTexture() return "wtf1" end
-------------

function modifier_player_difficulty_boon_random_speed_debuffs_30_60:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(5.0)
end

function modifier_player_difficulty_boon_random_speed_debuffs_30_60:OnIntervalThink()
    if not RollPercentage(30) then return end

    local parent = self:GetParent()
    if parent:IsMagicImmune() or parent:IsInvulnerable() then return end

    if parent:HasModifier("modifier_player_difficulty_boon_random_speed_debuffs_30_60_debuff") then return end

    parent:AddNewModifier(parent, nil, "modifier_player_difficulty_boon_random_speed_debuffs_30_60_debuff", { duration = 2.0 })
end
--

function modifier_player_difficulty_boon_random_speed_debuffs_30_60_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT
    }

    return funcs
end

function modifier_player_difficulty_boon_random_speed_debuffs_30_60_debuff:GetModifierAttackSpeedPercentage()
    return -60
end

function modifier_player_difficulty_boon_random_speed_debuffs_30_60_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -60
end

function modifier_player_difficulty_boon_random_speed_debuffs_30_60_debuff:GetModifierMoveSpeed_Limit()
    return 100
end