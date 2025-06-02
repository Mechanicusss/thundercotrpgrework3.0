LinkLuaModifier("modifier_player_difficulty_buff_gold_10", "modifiers/modes/buffs/normal/modifier_player_difficulty_buff_gold_10", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

player_difficulty_buff_gold_10 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_buff_gold_10 = class(ItemBaseClass)

function player_difficulty_buff_gold_10:GetIntrinsicModifierName()
    return "modifier_player_difficulty_buff_gold_10"
end

function modifier_player_difficulty_buff_gold_10:GetTexture() return "greed" end
-------------
function modifier_player_difficulty_buff_gold_10:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,  
    }

    return funcs
end

function modifier_player_difficulty_buff_gold_10:OnDeath(event)
    if event.attacker ~= self:GetParent() then return end

    local attacker = event.attacker
    local victim = event.unit

    if attacker == victim then return end

    local gold = victim:GetGoldBounty() * 0.1

    attacker:ModifyGold(gold, true, DOTA_ModifyGold_CreepKill) 

    self:PlayEffect(victim, gold)
end

function modifier_player_difficulty_buff_gold_10:PlayEffect(target, gold)
    local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas_b.vpcf", PATTACH_OVERHEAD_FOLLOW, target)   
    ParticleManager:SetParticleControlEnt(midas_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
    ParticleManager:ReleaseParticleIndex(midas_particle)
    target:EmitSound("DOTA_Item.Hand_Of_Midas")
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, target, gold, nil)
end