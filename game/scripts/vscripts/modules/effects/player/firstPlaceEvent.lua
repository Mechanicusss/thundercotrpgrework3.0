LinkLuaModifier("modifier_effect_event_first", "modules/effects/player/firstPlaceEvent", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_event_first then modifier_effect_event_first = class({}) end

FIRST_PLACE_EVENT_PRIVATE_IDS = {
}

function modifier_effect_event_first:IsHidden()
    return false
end

function modifier_effect_event_first:GetEffectName()
  return "particles/econ/events/ti9/ti9_emblem_effect.vpcf"
end

function modifier_effect_event_first:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_event_first:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_event_first:GetTexture()
      return "medal1"
end

function modifier_effect_event_first:AllowIllusionDuplicate() return true end

function modifier_effect_event_first:GetPriority()
    return 10002
end