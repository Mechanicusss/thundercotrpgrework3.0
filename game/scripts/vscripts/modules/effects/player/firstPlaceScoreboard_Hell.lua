LinkLuaModifier("modifier_effect_scoreboard_first_hell", "modules/effects/player/firstPlaceScoreboard_Hell", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_scoreboard_first_hell then modifier_effect_scoreboard_first_hell = class({}) end

FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_HELL = {
}

function modifier_effect_scoreboard_first_hell:IsHidden()
    return false
end

function modifier_effect_scoreboard_first_hell:GetEffectName()
  return "particles/econ/events/fall_2022/_2player/fall_2022_emblem_effect_player_base.vpcf"
end

function modifier_effect_scoreboard_first_hell:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_scoreboard_first_hell:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_scoreboard_first_hell:GetTexture()
      return "diff_hell"
end

function modifier_effect_scoreboard_first_hell:AllowIllusionDuplicate() return true end

function modifier_effect_scoreboard_first_hell:GetPriority()
    return 99999
end

function modifier_effect_scoreboard_first_hell:OnCreated()
    if not IsServer() then return end 

    self.vfx = ParticleManager:CreateParticle( "particles/econ/items/centaur/centaur_2022_immortal/centaur_2022_immortal_stampede_gold__2overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( self.vfx, 0, self:GetParent():GetAbsOrigin() )

    self:GetParent():SetBonusDropRate(self:GetParent():GetBonusDropRate() + 5)
end

function modifier_effect_scoreboard_first_hell:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, --GetModifierTotalDamageOutgoing_Percentage
        MODIFIER_PROPERTY_GOLD_RATE_BOOST, --GetModifierPercentageGoldRateBoost
        MODIFIER_PROPERTY_EXP_RATE_BOOST, --GetModifierPercentageExpRateBoost
    }
end

function modifier_effect_scoreboard_first_hell:GetModifierTotalDamageOutgoing_Percentage()
    return 15
end

function modifier_effect_scoreboard_first_hell:GetModifierPercentageExpRateBoost()
    return 15
end

function modifier_effect_scoreboard_first_hell:GetModifierPercentageGoldRateBoost()
    return 15
end