LinkLuaModifier("modifier_grimstroke_ink_swell_custom", "heroes/hero_grimstroke/grimstroke_ink_swell_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_ink_swell_custom_aura", "heroes/hero_grimstroke/grimstroke_ink_swell_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_ink_swell_custom_debuff", "heroes/hero_grimstroke/grimstroke_ink_swell_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

grimstroke_ink_swell_custom = class(ItemBaseClass)
modifier_grimstroke_ink_swell_custom = class(grimstroke_ink_swell_custom)
modifier_grimstroke_ink_swell_custom_aura = class(ItemBaseClassDebuff)
modifier_grimstroke_ink_swell_custom_debuff = class(ItemBaseClassDebuff)
-------------
function grimstroke_ink_swell_custom:OnToggle()
    local caster = self:GetCaster()

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_grimstroke_ink_swell_custom", {})
        EmitSoundOn("Hero_Grimstroke.InkSwell.Cast", caster)
    else
        caster:RemoveModifierByName("modifier_grimstroke_ink_swell_custom")
    end
end

function grimstroke_ink_swell_custom:GetManaCost(level)
    return self:GetCaster():GetMaxMana() * (self:GetSpecialValueFor("mana_cost_pct")/100)
end

function grimstroke_ink_swell_custom:GetAOERadius()
    local ability = self

    return ability:GetSpecialValueFor("radius")
end
-------------------------------------------
function modifier_grimstroke_ink_swell_custom:GetStatusEffectName()
    return "particles/status_fx/status_effect_grimstroke_ink_swell.vpcf"
end

function modifier_grimstroke_ink_swell_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_grimstroke_ink_swell_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end

function modifier_grimstroke_ink_swell_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_grimstroke/grimstroke_ink_swell_buff.vpcf", PATTACH_OVERHEAD_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        parent,
        PATTACH_OVERHEAD_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        3,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect_cast, 0, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 3, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 4, parent:GetAbsOrigin() )

    self.interval = ability:GetSpecialValueFor("pulse_interval")

    self.pulseDrain = ability:GetSpecialValueFor("pulse_max_mana_pct")
    self.pulseRadius = ability:GetSpecialValueFor("pulse_radius")
    self.pulseAttackSlow = ability:GetSpecialValueFor("pulse_attack_slow")
    self.pulseMoveSlow = ability:GetSpecialValueFor("pulse_move_slow")
    self.pulseDebuffDuration = ability:GetSpecialValueFor("pulse_debuff_duration")
    self.intDamage = ability:GetSpecialValueFor("int_to_damage")

    self.manaCost = ability:GetManaCost(-1)*0.1
    self.i = 0

    self.damageTable = {
        attacker = parent,
        damage_type = ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_NONE,
        ability = ability,
    }

    self:StartIntervalThink(0.1)
end

function modifier_grimstroke_ink_swell_custom:OnIntervalThink()
    self.i = self.i + 0.1

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if self.manaCost > parent:GetMana() then 
        if ability:GetToggleState() then
            ability:ToggleAbility()
        end
        return 
    end

    parent:SpendMana(self.manaCost, ability)

    if self.i < self.interval then return end

    self.pulse_effect = ParticleManager:CreateParticle( "particles/units/heroes/hero_grimstroke/grimstroke_ink_swell_aoe.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.pulse_effect,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.pulse_effect, 0, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.pulse_effect, 4, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.pulse_effect, 2, Vector(self.pulseRadius,self.pulseRadius,self.pulseRadius) )
    ParticleManager:ReleaseParticleIndex(self.pulse_effect)
    --------
    self.pulse_effect_dust = ParticleManager:CreateParticle( "particles/units/heroes/hero_grimstroke/grimstroke_sfm_ink_swell_reveal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.pulse_effect_dust,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.pulse_effect_dust, 0, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.pulse_effect_dust, 1, parent:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex(self.pulse_effect_dust)
    -----------
    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            self.pulseRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() or victim:IsInvulnerable() then break end

        self.damageTable.victim = victim

        local victimMana = victim:GetMana() * (self.pulseDrain/100)
        if victim:GetMana() >= victimMana then
            victim:SpendMana(victimMana, self:GetAbility())
            parent:GiveMana(victimMana)

            self.damageTable.damage = victimMana + (parent:GetBaseIntellect()*(ability:GetSpecialValueFor("int_to_damage")/100))

            SendOverheadEventMessage(
                nil,
                OVERHEAD_ALERT_MANA_LOSS,
                victim,
                victimMana,
                nil
            )
            SendOverheadEventMessage(
                nil,
                OVERHEAD_ALERT_MANA_ADD,
                parent,
                victimMana,
                nil
            )

            ApplyDamage(self.damageTable)
        end

        victim:AddNewModifier(parent, self:GetAbility(), "modifier_grimstroke_ink_swell_custom_debuff", {
            duration = self.pulseDebuffDuration
        })
    end
    -----------
    EmitSoundOn("Hero_Grimstroke.InkSwell.Stun", parent)
    self.i = 0
end

function modifier_grimstroke_ink_swell_custom:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_grimstroke_ink_swell_custom:IsAura()
    return true
end

function modifier_grimstroke_ink_swell_custom:GetAuraSearchType()
    return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_grimstroke_ink_swell_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_grimstroke_ink_swell_custom:GetAuraRadius()
    local ability = self:GetAbility()

    return ability:GetSpecialValueFor("radius")
end

function modifier_grimstroke_ink_swell_custom:GetModifierAura()
    return "modifier_grimstroke_ink_swell_custom_aura"
end

function modifier_grimstroke_ink_swell_custom:GetAuraEntityReject(target)
    return false
end
-------------------------------
function modifier_grimstroke_ink_swell_custom_aura:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    self.manaCost = ability:GetManaCost(-1)

    local damage = self.manaCost

    self.interval = ability:GetSpecialValueFor("tick_interval")
    self.damage = damage + (caster:GetBaseIntellect()*(ability:GetSpecialValueFor("int_to_damage")/100))

    self.damageTable = {
        victim = parent,
        attacker = caster,
        damage_type = ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_NONE,
        damage = self.damage,
        ability = ability,
    }

    self:StartIntervalThink(self.interval)
end

function modifier_grimstroke_ink_swell_custom_aura:OnIntervalThink()
    local parent = self:GetParent()

    ApplyDamage(self.damageTable)
    EmitSoundOn("Hero_Grimstroke.InkSwell.Damage", self:GetParent())

    self.pulse_tendril = ParticleManager:CreateParticle( "particles/units/heroes/hero_grimstroke/grimstroke_ink_swell_tick_damage.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.pulse_tendril,
        0,
        self:GetCaster(),
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        self:GetCaster():GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.pulse_tendril,
        1,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.pulse_tendril, 0, self:GetCaster():GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.pulse_tendril, 1, parent:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex(self.pulse_tendril)
end

function modifier_grimstroke_ink_swell_custom_aura:OnRemoved()
    if not IsServer() then return end

    StopSoundOn("Hero_Grimstroke.InkSwell.Damage", self:GetParent())
end
--------------
function modifier_grimstroke_ink_swell_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }
end

function modifier_grimstroke_ink_swell_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("pulse_move_slow")
end

function modifier_grimstroke_ink_swell_custom_debuff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("pulse_attack_slow")
end