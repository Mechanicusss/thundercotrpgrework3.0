LinkLuaModifier("boss_skeleton_king_mortal_strike_modifier", "heroes/bosses/skeleton_king/boss_skeleton_king_mortal_strike", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local ItemSelfBuffBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
}

boss_skeleton_king_mortal_strike = class(BaseClass)
boss_skeleton_king_mortal_strike_modifier = class(BaseClass)

function boss_skeleton_king_mortal_strike:GetIntrinsicModifierName()
    return "boss_skeleton_king_mortal_strike_modifier"
end
----------------------------------------------------
function boss_skeleton_king_mortal_strike_modifier:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
        MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
    }
end

function boss_skeleton_king_mortal_strike_modifier:GetModifierPreAttack_CriticalStrike(params)
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        local ability = self:GetAbility()

        if ability:IsCooldownReady() then
            self.record = params.record

            local vfx = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_weapon_blur_critical.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
            ParticleManager:SetParticleControl(vfx, 0, self:GetParent():GetAbsOrigin())
            ParticleManager:ReleaseParticleIndex(vfx)

            self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_3)

            return ability:GetSpecialValueFor("crit_mult")
        end
    end
end

function boss_skeleton_king_mortal_strike_modifier:GetModifierProcAttack_Feedback(params)
    if IsServer() then
        if self.record then
            EmitSoundOn("Hero_SkeletonKing.CriticalStrike", params.target)
            self:GetAbility():UseResources(false, false, false, true)
            self.record = nil
        end
    end
end

function boss_skeleton_king_mortal_strike_modifier:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_MISS] = self:GetAbility():IsCooldownReady()
    }
end