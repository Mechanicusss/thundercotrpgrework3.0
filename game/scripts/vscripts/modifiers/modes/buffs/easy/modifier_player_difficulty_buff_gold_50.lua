LinkLuaModifier("modifier_player_difficulty_buff_gold_50", "modifiers/modes/buffs/easy/modifier_player_difficulty_buff_gold_50", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

player_difficulty_buff_gold_50 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_buff_gold_50 = class(ItemBaseClass)

function player_difficulty_buff_gold_50:GetIntrinsicModifierName()
    return "modifier_player_difficulty_buff_gold_50"
end

function modifier_player_difficulty_buff_gold_50:GetTexture() return "greed" end
-------------
function modifier_player_difficulty_buff_gold_50:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,  
    }

    return funcs
end

function modifier_player_difficulty_buff_gold_50:OnDeath(event)
    if event.attacker ~= self:GetParent() then return end

    local attacker = event.attacker
    local victim = event.unit

    if attacker == victim then return end

    local gold = victim:GetGoldBounty() * 0.5

    attacker:ModifyGold(gold, true, DOTA_ModifyGold_CreepKill) 

    self:PlayEffect(victim, gold)
end

function modifier_player_difficulty_buff_gold_50:PlayEffect(target, gold)
    local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas_b.vpcf", PATTACH_OVERHEAD_FOLLOW, target)   
    ParticleManager:SetParticleControlEnt(midas_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
    ParticleManager:ReleaseParticleIndex(midas_particle)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, target, gold, nil)
end