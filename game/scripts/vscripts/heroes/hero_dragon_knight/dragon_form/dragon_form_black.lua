LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_black", "heroes/hero_dragon_knight/dragon_form/dragon_form_black", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_black_armor_debuff", "heroes/hero_dragon_knight/dragon_form/dragon_form_black", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
}

modifier_dragon_knight_dragon_form_custom_black = class(ItemBaseClassDragon)
modifier_dragon_knight_dragon_form_custom_black_armor_debuff = class(ItemBaseClassDebuff)

function modifier_dragon_knight_dragon_form_custom_black:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, 
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_dragon_knight_dragon_form_custom_black:CheckState()
    return {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }
end

function modifier_dragon_knight_dragon_form_custom_black:GetModifierModelScale()
    return self.scale
end

function modifier_dragon_knight_dragon_form_custom_black:GetAttackSound()
    return self.attack_sound
end

function modifier_dragon_knight_dragon_form_custom_black:GetModifierProjectileName()
    return self.projectile
end

function modifier_dragon_knight_dragon_form_custom_black:GetModifierProjectileSpeedBonus()
    return 900
end

function modifier_dragon_knight_dragon_form_custom_black:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end

function modifier_dragon_knight_dragon_form_custom_black:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

function modifier_dragon_knight_dragon_form_custom_black:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("black_drake_bonus_damage_pct")
end

function modifier_dragon_knight_dragon_form_custom_black:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)

    self.scale = 50
    self.attack_sound = "Hero_DragonKnight.ElderDragonShoot3.Attack"
    self.projectile = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_attack_black.vpcf"
    self.transform = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_black.vpcf"

    self.debuffDuration = self:GetAbility():GetSpecialValueFor("black_drake_debuff_duration")
    self.critChance = self:GetAbility():GetSpecialValueFor("black_drake_crit_chance")
    self.critBonus = self:GetAbility():GetSpecialValueFor("black_drake_crit_multiplier")

    self:StartIntervalThink(0.03)

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( self.transform, PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 1, parent:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_DragonKnight.ElderDragonForm", parent)
end

function modifier_dragon_knight_dragon_form_custom_black:OnIntervalThink()
    local parent = self:GetParent()

    parent:SetSkin(3)
end

function modifier_dragon_knight_dragon_form_custom_black:GetModifierModelChange()
    return "models/heroes/dragon_knight/dragon_knight_dragon.vmdl"
end

function modifier_dragon_knight_dragon_form_custom_black:GetModifierPreAttack_CriticalStrike(event)
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        local cc = self.critChance

        if RollPercentage(cc) then
            self.record = event.record
            return self.critBonus
        end
    end
end

function modifier_dragon_knight_dragon_form_custom_black:GetModifierProcAttack_Feedback(event)
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end

    if event.target:GetTeamNumber() == self:GetParent():GetTeamNumber() or event.attacker ~= self:GetParent() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local debuffName = "modifier_dragon_knight_dragon_form_custom_black_armor_debuff"
    local debuff = event.target:FindModifierByName(debuffName)
    if debuff == nil then
        debuff = event.target:AddNewModifier(parent, ability, debuffName, {
            duration = self.debuffDuration
        })
    end

    if debuff ~= nil then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("black_drake_debuff_max_stacks") then
            debuff:IncrementStackCount()
        end
        debuff:ForceRefresh()
    end

    EmitSoundOn("Hero_DragonKnight.ProjectileImpact", event.target)
end
------------------
function modifier_dragon_knight_dragon_form_custom_black_armor_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function modifier_dragon_knight_dragon_form_custom_black_armor_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("black_drake_debuff_armor_reduction") * self:GetStackCount()
end

function modifier_dragon_knight_dragon_form_custom_black_armor_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

