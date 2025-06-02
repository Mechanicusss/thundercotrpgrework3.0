LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_blue", "heroes/hero_dragon_knight/dragon_form/dragon_form_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_blue_slow_debuff", "heroes/hero_dragon_knight/dragon_form/dragon_form_blue", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClassDragon = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_dragon_knight_dragon_form_custom_blue = class(ItemBaseClassDragon)
modifier_dragon_knight_dragon_form_custom_blue_slow_debuff = class(ItemBaseClassDebuff)

function modifier_dragon_knight_dragon_form_custom_blue:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, 
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK
    }
end

function modifier_dragon_knight_dragon_form_custom_blue:CheckState()
    return {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }
end

function modifier_dragon_knight_dragon_form_custom_blue:GetModifierModelScale()
    return self.scale
end

function modifier_dragon_knight_dragon_form_custom_blue:GetAttackSound()
    return self.attack_sound
end

function modifier_dragon_knight_dragon_form_custom_blue:GetModifierProjectileName()
    return self.projectile
end

function modifier_dragon_knight_dragon_form_custom_blue:GetModifierProjectileSpeedBonus()
    return 900
end

function modifier_dragon_knight_dragon_form_custom_blue:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end

function modifier_dragon_knight_dragon_form_custom_blue:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

function modifier_dragon_knight_dragon_form_custom_blue:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)

    self.scale = 50
    self.attack_sound = "Hero_DragonKnight.ElderDragonShoot3.Attack"
    self.projectile = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_frost.vpcf"
    self.transform = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_blue.vpcf"

    self.debuffDuration = self:GetAbility():GetSpecialValueFor("ice_drake_debuff_duration")

    self:StartIntervalThink(0.03)

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( self.transform, PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_DragonKnight.ElderDragonForm", parent)
end

function modifier_dragon_knight_dragon_form_custom_blue:OnIntervalThink()
    local parent = self:GetParent()

    parent:SetSkin(2)
end

function modifier_dragon_knight_dragon_form_custom_blue:GetModifierModelChange()
    return "models/heroes/dragon_knight/dragon_knight_dragon.vmdl"
end

function modifier_dragon_knight_dragon_form_custom_blue:GetModifierProcAttack_Feedback(event)
    local target = event.target

    if target:GetTeamNumber() == self:GetParent():GetTeamNumber() or event.attacker ~= self:GetParent() then return end

    target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dragon_knight_dragon_form_custom_blue_slow_debuff", {
        duration = self.debuffDuration
    })

    EmitSoundOn("Hero_DragonKnight.ProjectileImpact", target)
end
------------------
function modifier_dragon_knight_dragon_form_custom_blue_slow_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }
end

function modifier_dragon_knight_dragon_form_custom_blue_slow_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("ice_drake_debuff_movement_slow_pct")
end

function modifier_dragon_knight_dragon_form_custom_blue_slow_debuff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("ice_drake_debuff_attack_slow")
end

function modifier_dragon_knight_dragon_form_custom_blue_slow_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end