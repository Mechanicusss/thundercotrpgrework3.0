
modifier_aghanim_life_drain_thinker = class({})

-----------------------------------------------------------------------------

function modifier_aghanim_life_drain_thinker:OnCreated( kv )
    if IsServer() then
        EmitSoundOn("Hero_Pugna.LifeDrain.Cast", self:GetCaster())
        EmitSoundOn("Hero_Pugna.LifeDrain.Loop", self:GetCaster())
    end
end

function modifier_aghanim_life_drain_thinker:OnDestroy( kv )
    if IsServer() then
        StopSoundOn("Hero_Pugna.LifeDrain.Loop", self:GetCaster())
    end
end
-----------------------------------------------------------------------------

function modifier_aghanim_life_drain_thinker:IsAura()
    return true
end

function modifier_aghanim_life_drain_thinker:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_aghanim_life_drain_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_aghanim_life_drain_thinker:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("search_radius")
end

function modifier_aghanim_life_drain_thinker:GetModifierAura()
    return "modifier_aghanim_life_drain_debuff_thinker"
end

function modifier_aghanim_life_drain_thinker:GetAuraEntityReject(target)
    return target:IsMagicImmune()
end
-----------------------------------------------------------------------------