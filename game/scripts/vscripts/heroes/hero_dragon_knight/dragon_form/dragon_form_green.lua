LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_green", "heroes/hero_dragon_knight/dragon_form/dragon_form_green", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_green_poison_debuff", "heroes/hero_dragon_knight/dragon_form/dragon_form_green", LUA_MODIFIER_MOTION_NONE)

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

modifier_dragon_knight_dragon_form_custom_green = class(ItemBaseClassDragon)
modifier_dragon_knight_dragon_form_custom_green_poison_debuff = class(ItemBaseClassDebuff)

function modifier_dragon_knight_dragon_form_custom_green:DeclareFunctions()
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

function modifier_dragon_knight_dragon_form_custom_green:CheckState()
    return {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }
end

function modifier_dragon_knight_dragon_form_custom_green:GetModifierModelScale()
    return self.scale
end

function modifier_dragon_knight_dragon_form_custom_green:GetAttackSound()
    return self.attack_sound
end

function modifier_dragon_knight_dragon_form_custom_green:GetModifierProjectileName()
    return self.projectile
end

function modifier_dragon_knight_dragon_form_custom_green:GetModifierProjectileSpeedBonus()
    return 900
end

function modifier_dragon_knight_dragon_form_custom_green:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end

function modifier_dragon_knight_dragon_form_custom_green:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

function modifier_dragon_knight_dragon_form_custom_green:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)

    self.scale = 50
    self.attack_sound = "Hero_DragonKnight.ElderDragonShoot1.Attack"
    self.projectile = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_corrosive.vpcf"
    self.transform = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_green.vpcf"

    self:StartIntervalThink(0.03)

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( self.transform, PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_DragonKnight.ElderDragonForm", parent)
end

function modifier_dragon_knight_dragon_form_custom_green:OnIntervalThink()
    local parent = self:GetParent()

    parent:SetSkin(0)
end

function modifier_dragon_knight_dragon_form_custom_green:GetModifierModelChange()
    return "models/heroes/dragon_knight/dragon_knight_dragon.vmdl"
end

function modifier_dragon_knight_dragon_form_custom_green:GetModifierProcAttack_Feedback(event)
    if event.target:GetTeamNumber() == self:GetParent():GetTeamNumber() or event.attacker ~= self:GetParent() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local duration = ability:GetSpecialValueFor("poison_drake_debuff_duration")

    local debuffName = "modifier_dragon_knight_dragon_form_custom_green_poison_debuff"
    local debuff = event.target:FindModifierByName(debuffName)
    if debuff == nil then
        debuff = event.target:AddNewModifier(parent, ability, debuffName, {
            duration = duration
        })
    end

    if debuff ~= nil then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("poison_drake_debuff_max_stacks") then
            debuff:IncrementStackCount()
        end
        debuff:ForceRefresh()
    end

    EmitSoundOn("Hero_DragonKnight.ProjectileImpact", event.target)
end
------------
function modifier_dragon_knight_dragon_form_custom_green_poison_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_dragon_knight_dragon_form_custom_green_poison_debuff:OnCreated()
    if not IsServer() then return end

    local interval = self:GetAbility():GetSpecialValueFor("poison_drake_debuff_interval")
    local damageFromAttack = self:GetAbility():GetSpecialValueFor("poison_drake_debuff_damage_from_attack")

    self.damage = self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster()) * (damageFromAttack/100) * interval

    self.damageTable = {
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    }

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_dragon_knight_dragon_form_custom_green_poison_debuff:OnRefresh()
    if not IsServer() then return end

    local interval = self:GetAbility():GetSpecialValueFor("poison_drake_debuff_interval")
    local damageFromAttack = self:GetAbility():GetSpecialValueFor("poison_drake_debuff_damage_from_attack")

    self.damage = self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster()) * (damageFromAttack/100) * interval
end

function modifier_dragon_knight_dragon_form_custom_green_poison_debuff:OnIntervalThink()
    local damage = self.damage * self:GetStackCount()
    self.damageTable.damage = damage
    ApplyDamage(self.damageTable)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), damage, nil)
end

function modifier_dragon_knight_dragon_form_custom_green_poison_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_poison_viper.vpcf"
end