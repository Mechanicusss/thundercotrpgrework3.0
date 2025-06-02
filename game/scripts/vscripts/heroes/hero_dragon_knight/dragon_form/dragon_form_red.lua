LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_red", "heroes/hero_dragon_knight/dragon_form/dragon_form_red", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_red_magic_debuff", "heroes/hero_dragon_knight/dragon_form/dragon_form_red", LUA_MODIFIER_MOTION_NONE)

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

modifier_dragon_knight_dragon_form_custom_red = class(ItemBaseClassDragon)
modifier_dragon_knight_dragon_form_custom_red_magic_debuff = class(ItemBaseClassDebuff)

function modifier_dragon_knight_dragon_form_custom_red:DeclareFunctions()
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

function modifier_dragon_knight_dragon_form_custom_red:CheckState()
    return {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }
end

function modifier_dragon_knight_dragon_form_custom_red:GetModifierModelScale()
    return self.scale
end

function modifier_dragon_knight_dragon_form_custom_red:GetAttackSound()
    return self.attack_sound
end

function modifier_dragon_knight_dragon_form_custom_red:GetModifierProjectileName()
    return self.projectile
end

function modifier_dragon_knight_dragon_form_custom_red:GetModifierProjectileSpeedBonus()
    return 900
end

function modifier_dragon_knight_dragon_form_custom_red:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end

function modifier_dragon_knight_dragon_form_custom_red:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

function modifier_dragon_knight_dragon_form_custom_red:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)

    self.scale = 50
    self.attack_sound = "Hero_DragonKnight.ElderDragonShoot2.Attack"
    self.projectile = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_fire.vpcf"
    self.transform = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_red.vpcf"

    self.splash_radius = self:GetAbility():GetSpecialValueFor("fire_drake_splash_radius")
    self.splash_pct = self:GetAbility():GetSpecialValueFor("fire_drake_splash_damage")
    self.debuffDuration = self:GetAbility():GetSpecialValueFor("fire_drake_debuff_duration")

    self:StartIntervalThink(0.03)

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( self.transform, PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_DragonKnight.ElderDragonForm", parent)
end

function modifier_dragon_knight_dragon_form_custom_red:OnIntervalThink()
    local parent = self:GetParent()

    parent:SetSkin(1)
end

function modifier_dragon_knight_dragon_form_custom_red:GetModifierModelChange()
    return "models/heroes/dragon_knight/dragon_knight_dragon.vmdl"
end

function modifier_dragon_knight_dragon_form_custom_red:GetModifierProcAttack_Feedback(event)
    local target = event.target

    if target:GetTeamNumber() == self:GetParent():GetTeamNumber() or event.attacker ~= self:GetParent() then return end

    local damage = self:GetParent():GetAverageTrueAttackDamage(self:GetParent())

    local enemies = FindUnitsInRadius(
        self:GetParent():GetTeamNumber(),    -- int, your team number
        target:GetOrigin(), -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.splash_radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        if enemy~=target then
            -- apply damage
            local damageTable = {
                victim = enemy,
                attacker = self:GetParent(),
                damage = damage * (self.splash_pct/100),
                damage_type = DAMAGE_TYPE_PHYSICAL,
                ability = self:GetAbility(), --Optional.
                -- damage_category = DOTA_DAMAGE_CATEGORY_ATTACK, --Optional.
            }

            ApplyDamage(damageTable)
        end

        enemy:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dragon_knight_dragon_form_custom_red_magic_debuff", {
            duration = self.debuffDuration
        })
    end

    EmitSoundOn("Hero_DragonKnight.ProjectileImpact", target)
end
------------------
function modifier_dragon_knight_dragon_form_custom_red_magic_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_dragon_knight_dragon_form_custom_red_magic_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("fire_drake_debuff_magical_resistance_reduction")
end

function modifier_dragon_knight_dragon_form_custom_red_magic_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_burn.vpcf"
end