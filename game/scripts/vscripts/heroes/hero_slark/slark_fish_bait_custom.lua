LinkLuaModifier("modifier_slark_fish_bait_custom_buff", "heroes/hero_slark/slark_fish_bait_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slark_fish_bait_custom_debuff", "heroes/hero_slark/slark_fish_bait_custom", LUA_MODIFIER_MOTION_NONE)

slark_fish_bait_custom = class({})

function slark_fish_bait_custom:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    target:EmitSound("Hero_Slark.FishBait")

    if caster == target then
        caster:AddNewModifier(caster, self, "modifier_slark_fish_bait_custom_buff", {duration = self:GetSpecialValueFor("duration")})
        local heal = self:GetSpecialValueFor("base_heal") + (caster:GetMaxHealth() / 100 * self:GetSpecialValueFor("max_hp_heal"))
        caster:Heal(heal, self)

        return
    end

    local info = {
        Source = caster,
        Ability = self,
        Target = target,
        EffectName = "particles/units/heroes/hero_slark/slark_shard_fish_bait.vpcf",
        bDodgeable = false,
        iMoveSpeed = 1250
    }

    ProjectileManager:CreateTrackingProjectile(info)
end

function slark_fish_bait_custom:OnProjectileHit(target, location)
    if target == nil then return end

    local caster = self:GetCaster()

    if target:GetTeamNumber() == caster:GetTeamNumber() then
        target:AddNewModifier(caster, self, "modifier_slark_fish_bait_custom_buff", {duration = self:GetSpecialValueFor("duration")})
        
        local heal = self:GetSpecialValueFor("base_heal") + (target:GetMaxHealth() / 100 * self:GetSpecialValueFor("max_hp_heal"))
        target:Heal(heal, self)
    else
        target:AddNewModifier(caster, self, "modifier_slark_fish_bait_custom_debuff", {duration = self:GetSpecialValueFor("duration")})
        
        local damage = self:GetSpecialValueFor("damage") + (caster:GetAgility() / 100 * self:GetSpecialValueFor("agi_to_damage"))

        local damageTable = {
            victim = target,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self
        }

        ApplyDamage(damageTable)
    end
end

modifier_slark_fish_bait_custom_debuff = class({
    IsPurgable = function(self) return true end,
    IsDebuff = function(self) return true end
})

function modifier_slark_fish_bait_custom_debuff:OnCreated(keys)
    self.movespeed = -self:GetAbility():GetSpecialValueFor("enemy_slow")
    self.attack_speed = -self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_slark_fish_bait_custom_debuff:OnRefresh(keys)
    self.movespeed = -self:GetAbility():GetSpecialValueFor("enemy_slow")
    self.attack_speed = -self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_slark_fish_bait_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_slark_fish_bait_custom_debuff:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

function modifier_slark_fish_bait_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.movespeed
end

function modifier_slark_fish_bait_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_slark/slark_fish_bait_slow.vpcf"
end

function modifier_slark_fish_bait_custom_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

modifier_slark_fish_bait_custom_buff = class({
    IsPurgable = function(self) return false end
})

function modifier_slark_fish_bait_custom_buff:OnCreated(keys)
    self.movespeed = self:GetAbility():GetSpecialValueFor("ally_movespeed")
    self.attack_speed = self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_slark_fish_bait_custom_buff:OnRefresh(keys)
    self.movespeed = self:GetAbility():GetSpecialValueFor("ally_movespeed")
    self.attack_speed = self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_slark_fish_bait_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_slark_fish_bait_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

function modifier_slark_fish_bait_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self.movespeed
end

function modifier_slark_fish_bait_custom_buff:GetEffectName()
    return "particles/units/heroes/hero_slark/slark_fish_bait_slow.vpcf"
end

function modifier_slark_fish_bait_custom_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end