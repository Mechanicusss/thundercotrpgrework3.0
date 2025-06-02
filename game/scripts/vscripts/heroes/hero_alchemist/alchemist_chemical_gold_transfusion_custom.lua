LinkLuaModifier("modifier_alchemist_chemical_gold_transfusion_custom", "heroes/hero_alchemist/alchemist_chemical_gold_transfusion_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

alchemist_chemical_gold_transfusion_custom = class(ItemBaseClass)
modifier_alchemist_chemical_gold_transfusion_custom = class(alchemist_chemical_gold_transfusion_custom)
-------------
function alchemist_chemical_gold_transfusion_custom:GetIntrinsicModifierName()
    return "modifier_alchemist_chemical_gold_transfusion_custom"
end

function alchemist_chemical_gold_transfusion_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local hasShard = caster:HasModifier("modifier_item_aghanims_shard")

    if (caster:GetLevel() < target:GetLevel()) or IsBossTCOTRPG(target) or not IsCreepTCOTRPG(target) then
        self:EndCooldown()
        return
    end

    target:Kill(self, caster)

    local targetBounty = target:GetGoldBounty()
    local goldBounty = targetBounty * self:GetSpecialValueFor("bounty_multi")
    local xpBounty = target:GetDeathXP() * self:GetSpecialValueFor("xp_multi")

    if hasShard then
        goldBounty = goldBounty * 2
        xpBounty = xpBounty * 2
    end

    caster:ModifyGoldFiltered(goldBounty, true, DOTA_ModifyGold_NeutralKill) 

    caster:AddExperience(xpBounty, 0, false, false) 
    
    local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)   
    ParticleManager:SetParticleControlEnt(midas_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), false)
    target:EmitSound("DOTA_Item.Hand_Of_Midas")
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, target, goldBounty, nil)
end