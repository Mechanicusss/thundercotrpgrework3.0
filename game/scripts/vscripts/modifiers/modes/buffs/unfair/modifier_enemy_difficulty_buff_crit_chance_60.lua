LinkLuaModifier("modifier_enemy_difficulty_buff_crit_chance_60", "modifiers/modes/buffs/unfair/modifier_enemy_difficulty_buff_crit_chance_60", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_crit_chance_60 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_crit_chance_60 = class(ItemBaseClass)

function enemy_difficulty_buff_crit_chance_60:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_crit_chance_60"
end

function modifier_enemy_difficulty_buff_crit_chance_60:GetTexture() return "critstrike" end
-------------
function modifier_enemy_difficulty_buff_crit_chance_60:OnCreated( kv )
    -- references
    self.crit_chance = 30
    self.crit_bonus = 150
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
end

function modifier_enemy_difficulty_buff_crit_chance_60:OnRefresh( kv )
    -- references
    self.crit_chance = 30
    self.crit_bonus = 150
end

function modifier_enemy_difficulty_buff_crit_chance_60:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }

    return funcs
end

function modifier_enemy_difficulty_buff_crit_chance_60:GetModifierPreAttack_CriticalStrike( params )
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        local cc = self.crit_chance


        if RollPercentage(cc) then
            self.record = params.record
            return self.crit_bonus
        end
    end
end

function modifier_enemy_difficulty_buff_crit_chance_60:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end
end