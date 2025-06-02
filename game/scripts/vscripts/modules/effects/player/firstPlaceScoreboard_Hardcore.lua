LinkLuaModifier("modifier_effect_scoreboard_first_hardcore", "modules/effects/player/firstPlaceScoreboard_Hardcore", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_scoreboard_first_hardcore then modifier_effect_scoreboard_first_hardcore = class({}) end

FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_HARDCORE = {
    "76561199635008250",
    "76561198346207311", -- Mechanicuss
}

function modifier_effect_scoreboard_first_hardcore:IsHidden()
    return false
end

function modifier_effect_scoreboard_first_hardcore:GetEffectName()
  return "particles/econ/events/fall_2022/_2player/fall_2022_emblem_effect_player_base.vpcf"
end

function modifier_effect_scoreboard_first_hardcore:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_scoreboard_first_hardcore:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_scoreboard_first_hardcore:GetTexture()
      return "diff_hardcore"
end

function modifier_effect_scoreboard_first_hardcore:AllowIllusionDuplicate() return true end

function modifier_effect_scoreboard_first_hardcore:GetPriority()
    return 99999
end

function modifier_effect_scoreboard_first_hardcore:OnCreated()
    if not IsServer() then return end 

    self.vfx = ParticleManager:CreateParticle( "particles/econ/items/centaur/centaur_2022_immortal/centaur_2022_immortal_stampede_gold__2overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( self.vfx, 0, self:GetParent():GetAbsOrigin() )

    self:GetParent():SetBonusDropRate(self:GetParent():GetBonusDropRate() + 5)
end

function modifier_effect_scoreboard_first_hardcore:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, --GetModifierTotalDamageOutgoing_Percentage
        MODIFIER_PROPERTY_GOLD_RATE_BOOST, --GetModifierPercentageGoldRateBoost
        MODIFIER_PROPERTY_EXP_RATE_BOOST, --GetModifierPercentageExpRateBoost
    }
end

function modifier_effect_scoreboard_first_hardcore:GetModifierTotalDamageOutgoing_Percentage()
    return 20
end

function modifier_effect_scoreboard_first_hardcore:GetModifierPercentageExpRateBoost()
    return 20
end

function modifier_effect_scoreboard_first_hardcore:GetModifierPercentageGoldRateBoost()
    return 20
end