LinkLuaModifier("modifier_effect_thirdplace_rank", "modules/effects/player/firstPlaceScoreboard", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_thirdplace_rank then modifier_effect_thirdplace_rank = class({}) end

THIRD_PLACE_RANK_PRIVATE_IDS = {
}

function modifier_effect_thirdplace_rank:IsHidden()
    return false
end

function modifier_effect_thirdplace_rank:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_thirdplace_rank:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_thirdplace_rank:GetTexture()
      return "medal1"
end

function modifier_effect_thirdplace_rank:AllowIllusionDuplicate() return true end

function modifier_effect_thirdplace_rank:GetPriority()
    return 99998
end

function modifier_effect_thirdplace_rank:OnCreated()
    if not IsServer() then return end 

    self:GetParent():SetBonusDropRate(self:GetParent():GetBonusDropRate() + 5)
end

