LinkLuaModifier("modifier_enemy_difficulty_buff_extra_attack_10", "modifiers/modes/buffs/normal/modifier_enemy_difficulty_buff_extra_attack_10", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_extra_attack_10 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_extra_attack_10 = class(ItemBaseClass)

function enemy_difficulty_buff_extra_attack_10:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_extra_attack_10"
end

function modifier_enemy_difficulty_buff_extra_attack_10:GetTexture() return "mirrorblade" end
-------------
function modifier_enemy_difficulty_buff_extra_attack_10:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,  
    }

    return funcs
end

function modifier_enemy_difficulty_buff_extra_attack_10:OnCreated()
    if not IsServer() then return end

    self.cooldown = false
end

function modifier_enemy_difficulty_buff_extra_attack_10:OnAttackLanded(event)
    if event.attacker ~= self:GetParent() then return end

    local attacker = event.attacker
    local unit = event.target

    if self.cooldown then return end

    Timers:CreateTimer(0.1, function()
        attacker:PerformAttack(
            unit,
            true,
            true,
            true,
            true,
            attacker:IsRangedAttacker(),
            false,
            false
        )
    end)

    Timers:CreateTimer(10, function()
        self.cooldown = false
    end)
    self.cooldown = true
end