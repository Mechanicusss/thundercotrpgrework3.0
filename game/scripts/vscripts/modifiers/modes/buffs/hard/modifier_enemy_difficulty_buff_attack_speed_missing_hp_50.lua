LinkLuaModifier("modifier_enemy_difficulty_buff_attack_speed_missing_hp_50", "modifiers/modes/buffs/hard/modifier_enemy_difficulty_buff_attack_speed_missing_hp_50", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_attack_speed_missing_hp_50 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_attack_speed_missing_hp_50 = class(ItemBaseClass)

function enemy_difficulty_buff_attack_speed_missing_hp_50:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_attack_speed_missing_hp_50"
end

function modifier_enemy_difficulty_buff_attack_speed_missing_hp_50:GetTexture() return "arena/kadash_survival_skills" end
-------------
function modifier_enemy_difficulty_buff_attack_speed_missing_hp_50:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,  
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_enemy_difficulty_buff_attack_speed_missing_hp_50:OnTakeDamage(event)
    if event.unit ~= self:GetParent() then return end

    self:OnRefresh()
end

function modifier_enemy_difficulty_buff_attack_speed_missing_hp_50:OnCreated()
    self.aps = 0

    self:OnRefresh()
end

function modifier_enemy_difficulty_buff_attack_speed_missing_hp_50:OnRefresh()
    local currentPct = self:GetParent():GetHealthPercent()
    local bonus = 25 * ((100 - currentPct) / 10)

    self.aps = bonus
end

function modifier_enemy_difficulty_buff_attack_speed_missing_hp_50:GetModifierAttackSpeedBonus_Constant()
    return self.aps
end