LinkLuaModifier("modifier_ancient_apparition_chilling_touch_custom", "heroes/hero_ancient_apparition/ancient_apparition_chilling_touch_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ancient_apparition_chilling_touch_custom_slow_debuff", "heroes/hero_ancient_apparition/ancient_apparition_chilling_touch_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )


local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

ancient_apparition_chilling_touch_custom = class(ItemBaseClass)
boss_ancient_apparition_chilling_touch_custom = ancient_apparition_chilling_touch_custom
modifier_ancient_apparition_chilling_touch_custom = class(ancient_apparition_chilling_touch_custom)
modifier_ancient_apparition_chilling_touch_custom_slow_debuff = class(ItemBaseClassDebuff)
-------------
function ancient_apparition_chilling_touch_custom:GetIntrinsicModifierName()
    return "modifier_generic_orb_effect_lua"
end

function ancient_apparition_chilling_touch_custom:GetManaCost()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then return 0 end

    return self.BaseClass.GetManaCost(self, -1) or 0
end

function ancient_apparition_chilling_touch_custom:GetProjectileName()
    return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_chilling_touch_projectile.vpcf"
end

function ancient_apparition_chilling_touch_custom:GetCastRange(vLocation, hTarget)
    if IsServer() then
        local caster = self:GetCaster()
        local ability = self

        local range = ability:GetSpecialValueFor("attack_range_bonus")

        return self.BaseClass.GetCastRange( self, vLocation, hTarget ) + range
    end
end

function ancient_apparition_chilling_touch_custom:OnOrbFire(params)
    local caster = self:GetCaster()

    EmitSoundOn("Hero_Ancient_Apparition.ChillingTouch.Cast", caster)
end

function ancient_apparition_chilling_touch_custom:OnOrbImpact(params)
    local target = params.target

    if target:IsMagicImmune() or target:IsInvulnerable() then return end

    local ability = self
    local caster = self:GetCaster()
    local talentDamage = 0

    if caster:HasTalent("special_bonus_unique_ancient_apparition_2") then
        talentDamage = caster:FindAbilityByName("special_bonus_unique_ancient_apparition_2"):GetSpecialValueFor("value")
    end

    local intellectDamage = 0
    if caster:IsRealHero() then
        intellectDamage = caster:GetBaseIntellect()
    end

    local damage = ability:GetSpecialValueFor("damage") + (intellectDamage * (ability:GetSpecialValueFor("int_to_damage")/100)) + talentDamage
    local damageTable = {
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_MAGIC_AUTO_ATTACK,
        ability = ability
    }

    ApplyDamage(damageTable)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, damage, nil)
    
    target:AddNewModifier(caster, ability, "modifier_ancient_apparition_chilling_touch_custom_slow_debuff", { duration = ability:GetSpecialValueFor("duration") })
    
    if caster:HasModifier("modifier_item_aghanims_shard") then
        local radius = ability:GetSpecialValueFor("radius")

        local victims = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil,
                radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            if victim:IsAlive() and not victim:IsMagicImmune() and not victim:IsInvulnerable() and victim ~= target then
                damageTable.victim = victim

                ApplyDamage(damageTable)

                SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, damage, nil)
                victim:AddNewModifier(caster, ability, "modifier_ancient_apparition_chilling_touch_custom_slow_debuff", { duration = ability:GetSpecialValueFor("duration") })
            end
        end
    end

    EmitSoundOn("Hero_Ancient_Apparition.ChillingTouch.Target", target)
end

function modifier_ancient_apparition_chilling_touch_custom_slow_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function modifier_ancient_apparition_chilling_touch_custom_slow_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_ancient_apparition_chilling_touch_custom_slow_debuff:GetEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end