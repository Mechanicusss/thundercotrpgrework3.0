LinkLuaModifier("modifier_happy_new_year", "modifier/modifier_happy_new_year", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_hallowen then modifier_effect_hallowen = class({}) end

function modifier_effect_hallowen:IsHidden()
    return false
end


function modifier_effect_hallowen:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_hallowen:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_hallowen:GetTexture()
    return "diff_hardcore"
end

function modifier_effect_hallowen:AllowIllusionDuplicate() return true end

function modifier_effect_hallowen:GetPriority()
    return 99999
end

function modifier_effect_hallowen:OnCreated()
    if not IsServer() then return end 

    self.vfx = ParticleManager:CreateParticle("particles/econ/events/diretide_2020/emblem/fall20_emblem_effect.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.vfx, 0, self:GetParent():GetAbsOrigin())

    self:GetParent():SetBonusDropRate(self:GetParent():GetBonusDropRate() + 5)
end

function modifier_effect_hallowen:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, --GetModifierTotalDamageOutgoing_Percentage
        MODIFIER_PROPERTY_GOLD_RATE_BOOST, --GetModifierPercentageGoldRateBoost
        MODIFIER_PROPERTY_EXP_RATE_BOOST, --GetModifierPercentageExpRateBoost
    }
end

function modifier_effect_hallowen:GetModifierTotalDamageOutgoing_Percentage()
    return 20
end

function modifier_effect_hallowen:GetModifierPercentageExpRateBoost()
    return 20
end

function modifier_effect_hallowen:GetModifierPercentageGoldRateBoost()
    return 20
end

