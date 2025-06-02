LinkLuaModifier("modifier_enemy_difficulty_buff_attack_speed_missing_hp_80", "modifiers/modes/buffs/unfair/modifier_enemy_difficulty_buff_attack_speed_missing_hp_80", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_attack_speed_missing_hp_80 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_attack_speed_missing_hp_80 = class(ItemBaseClass)

function enemy_difficulty_buff_attack_speed_missing_hp_80:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_attack_speed_missing_hp_80"
end

function modifier_enemy_difficulty_buff_attack_speed_missing_hp_80:GetTexture() return "arena/kadash_survival_skills" end
-------------
function modifier_enemy_difficulty_buff_attack_speed_missing_hp_80:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,  
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_enemy_difficulty_buff_attack_speed_missing_hp_80:OnTakeDamage(event)
    if event.unit ~= self:GetParent() then return end

    self:OnRefresh()
end

function modifier_enemy_difficulty_buff_attack_speed_missing_hp_80:OnCreated()
    self.aps = 0

    self:OnRefresh()
end

function modifier_enemy_difficulty_buff_attack_speed_missing_hp_80:OnRefresh()
    local percent = self:GetParent():GetHealthPercent()
    if percent < 80 then
        percent = 80
    end

    self.aps = percent
end

function modifier_enemy_difficulty_buff_attack_speed_missing_hp_80:GetModifierAttackSpeedPercentage()
    return self.aps
end