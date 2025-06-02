LinkLuaModifier("modifier_effect_scoreboard_first_impossible", "modules/effects/player/firstPlaceScoreboard_Impossible", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_scoreboard_first_impossible then modifier_effect_scoreboard_first_impossible = class({}) end

FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_IMPOSSIBLE = {
}

function modifier_effect_scoreboard_first_impossible:IsHidden()
    return false
end

function modifier_effect_scoreboard_first_impossible:GetEffectName()
  return "particles/econ/events/fall_2022/_2player/fall_2022_emblem_effect_player_base.vpcf"
end

function modifier_effect_scoreboard_first_impossible:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_scoreboard_first_impossible:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_scoreboard_first_impossible:GetTexture()
      return "diff_impossible"
end

function modifier_effect_scoreboard_first_impossible:AllowIllusionDuplicate() return true end

function modifier_effect_scoreboard_first_impossible:GetPriority()
    return 99999
end

function modifier_effect_scoreboard_first_impossible:OnCreated()
    if not IsServer() then return end 

    self.vfx = ParticleManager:CreateParticle( "particles/econ/items/centaur/centaur_2022_immortal/centaur_2022_immortal_stampede_gold__2overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( self.vfx, 0, self:GetParent():GetAbsOrigin() )

    self:GetParent():SetBonusDropRate(self:GetParent():GetBonusDropRate() + 5)
end

function modifier_effect_scoreboard_first_impossible:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, --GetModifierTotalDamageOutgoing_Percentage
        MODIFIER_PROPERTY_GOLD_RATE_BOOST, --GetModifierPercentageGoldRateBoost
        MODIFIER_PROPERTY_EXP_RATE_BOOST, --GetModifierPercentageExpRateBoost
    }
end

function modifier_effect_scoreboard_first_impossible:GetModifierTotalDamageOutgoing_Percentage()
    return 10
end

function modifier_effect_scoreboard_first_impossible:GetModifierPercentageExpRateBoost()
    return 10
end

function modifier_effect_scoreboard_first_impossible:GetModifierPercentageGoldRateBoost()
    return 10
end