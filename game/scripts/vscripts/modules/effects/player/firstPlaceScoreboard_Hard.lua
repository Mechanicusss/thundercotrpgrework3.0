LinkLuaModifier("modifier_effect_scoreboard_first_hard", "modules/effects/player/firstPlaceScoreboard_Hard", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_scoreboard_first_hard then modifier_effect_scoreboard_first_hard = class({}) end

FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_HARD = {
}

function modifier_effect_scoreboard_first_hard:IsHidden()
    return false
end

function modifier_effect_scoreboard_first_hard:GetEffectName()
  return "particles/econ/events/fall_2022/_2player/fall_2022_emblem_effect_player_base.vpcf"
end

function modifier_effect_scoreboard_first_hard:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_scoreboard_first_hard:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_scoreboard_first_hard:GetTexture()
      return "diff_hard"
end

function modifier_effect_scoreboard_first_hard:AllowIllusionDuplicate() return true end

function modifier_effect_scoreboard_first_hard:GetPriority()
    return 99999
end

function modifier_effect_scoreboard_first_hard:OnCreated()
    if not IsServer() then return end 

    self.vfx = ParticleManager:CreateParticle( "particles/econ/items/centaur/centaur_2022_immortal/centaur_2022_immortal_stampede_gold__2overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( self.vfx, 0, self:GetParent():GetAbsOrigin() )

    self:GetParent():SetBonusDropRate(self:GetParent():GetBonusDropRate() + 5)
end

function modifier_effect_scoreboard_first_hard:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, --GetModifierTotalDamageOutgoing_Percentage
        MODIFIER_PROPERTY_GOLD_RATE_BOOST, --GetModifierPercentageGoldRateBoost
        MODIFIER_PROPERTY_EXP_RATE_BOOST, --GetModifierPercentageExpRateBoost
    }
end

function modifier_effect_scoreboard_first_hard:GetModifierTotalDamageOutgoing_Percentage()
    return 5
end

function modifier_effect_scoreboard_first_hard:GetModifierPercentageExpRateBoost()
    return 5
end

function modifier_effect_scoreboard_first_hard:GetModifierPercentageGoldRateBoost()
    return 5
end