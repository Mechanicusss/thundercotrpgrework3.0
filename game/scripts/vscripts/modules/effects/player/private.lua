LinkLuaModifier("modifier_effect_private", "modules/effects/player/private", LUA_MODIFIER_MOTION_NONE)
if not modifier_effect_private then modifier_effect_private = class({}) end

PRIVATE_IDS = {
   "76561198346207311"
}

function modifier_effect_private:IsHidden()
    return false
end

function modifier_effect_private:GetPriority()
    return 10001
end

function modifier_effect_private:GetEffectName()
    local parent = self:GetParent()
    if parent:HasModifier("modifier_effect_event_first") or parent:HasModifier("modifier_effect_scoreboard_first") or parent:HasModifier("modifier_effect_thirdplace_rank") then return end
    
    return "particles/econ/events/ti10/emblem/ti10_emblem_effect.vpcf"
end

function modifier_effect_private:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_effect_private:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_effect_private:GetTexture()
      return "item_ultimate_scepter"
end

function modifier_effect_private:AllowIllusionDuplicate() return true end