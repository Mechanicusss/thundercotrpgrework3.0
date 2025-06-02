LinkLuaModifier("modifier_lich_frost_nova_custom", "heroes/hero_lich/lich_frost_nova_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lich_frost_nova_custom_debuff", "heroes/hero_lich/lich_frost_nova_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

lich_frost_nova_custom = class(ItemBaseClass)
modifier_lich_frost_nova_custom = class(lich_frost_nova_custom)
modifier_lich_frost_nova_custom_debuff = class(ItemBaseClassDebuff)
-------------
function lich_frost_nova_custom:GetIntrinsicModifierName()
    return "modifier_lich_frost_nova_custom"
end

function lich_frost_nova_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function lich_frost_nova_custom:GetCooldown(level)
    local ab = self:GetCaster():FindAbilityByName("special_bonus_unique_lich_1_custom")
    if ab ~= nil and ab:GetLevel() > 0 then
        return self.BaseClass.GetCooldown(self, level) - ab:GetSpecialValueFor("value")
    end

    return self.BaseClass.GetCooldown(self, level) or 0
end

function lich_frost_nova_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local radius = self:GetSpecialValueFor("radius")
    local intellectDamage = self:GetCaster():GetBaseIntellect() * (self:GetSpecialValueFor("int_to_damage")/100)
    local damage = self:GetSpecialValueFor("damage") + intellectDamage
    local aoeDamage = self:GetSpecialValueFor("aoe_damage") + intellectDamage

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_lich/lich_frost_nova.vpcf", PATTACH_POINT, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin() )

    EmitSoundOn("Ability.FrostNova", target)

    ApplyDamage({
        victim = target, 
        attacker = caster, 
        damage = damage, 
        damage_type = self:GetAbilityDamageType(),
        ability = self
    })

    local victims = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        ApplyDamage({
            victim = victim, 
            attacker = caster, 
            damage = aoeDamage, 
            damage_type = self:GetAbilityDamageType(),
            ability = self
        })

        victim:AddNewModifier(caster, self, "modifier_lich_frost_nova_custom_debuff", {
            duration = self:GetSpecialValueFor("duration")
        })
    end
end
------------------
function modifier_lich_frost_nova_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 

    }
end

function modifier_lich_frost_nova_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow_movement_speed")
end

function modifier_lich_frost_nova_custom_debuff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("slow_attack_speed_primary")
end

function modifier_lich_frost_nova_custom_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end
-----------------
function modifier_lich_frost_nova_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_lich_frost_nova_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local ability = self:GetAbility()

    if not ability:GetAutoCastState() or not ability:IsCooldownReady() or ability:GetManaCost(-1) > parent:GetMana() or parent:IsSilenced() then return end

    SpellCaster:Cast(ability, event.target, true)
end