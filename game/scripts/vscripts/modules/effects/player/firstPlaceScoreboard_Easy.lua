LinkLuaModifier("modifier_effect_scoreboard_first_easy", "modules/effects/player/firstPlaceScoreboard_Easy", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_scoreboard_first_easy then modifier_effect_scoreboard_first_easy = class({}) end

FIRST_PLACE_SCOREBOARD_PRIVATE_IDS_EASY = {
}

function modifier_effect_scoreboard_first_easy:IsHidden()
    return false
end

function modifier_effect_scoreboard_first_easy:GetEffectName()
  return "particles/econ/events/fall_2022/_2player/fall_2022_emblem_effect_player_base.vpcf"
end

function modifier_effect_scoreboard_first_easy:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_scoreboard_first_easy:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_scoreboard_first_easy:GetTexture()
      return "diff_easy"
end

function modifier_effect_scoreboard_first_easy:AllowIllusionDuplicate() return true end

function modifier_effect_scoreboard_first_easy:GetPriority()
    return 99999
end

function modifier_effect_scoreboard_first_easy:OnCreated()
    if not IsServer() then return end 

    self.vfx = ParticleManager:CreateParticle( "particles/econ/items/centaur/centaur_2022_immortal/centaur_2022_immortal_stampede_gold__2overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( self.vfx, 0, self:GetParent():GetAbsOrigin() )

    self:GetParent():SetBonusDropRate(self:GetParent():GetBonusDropRate() + 5)
end

function modifier_effect_scoreboard_first_easy:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXP_RATE_BOOST, --GetModifierPercentageExpRateBoost
    }
end

function modifier_effect_scoreboard_first_easy:GetModifierPercentageExpRateBoost()
    return 5
end