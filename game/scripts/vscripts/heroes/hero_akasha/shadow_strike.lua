LinkLuaModifier("hero_akasha_shadow_strike_modifier", "heroes/hero_akasha/shadow_strike", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("hero_akasha_shadow_strike_modifier_debuff", "heroes/hero_akasha/shadow_strike", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("hero_akasha_shadow_strike_modifier_damage_debuff", "heroes/hero_akasha/shadow_strike", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local BaseClassDebuff = {
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end
}

hero_akasha_shadow_strike = class(BaseClass)
hero_akasha_shadow_strike_modifier = class(BaseClass)
hero_akasha_shadow_strike_modifier_debuff = class(BaseClassDebuff)
hero_akasha_shadow_strike_modifier_damage_debuff = class(BaseClassDebuff)

function hero_akasha_shadow_strike:GetIntrinsicModifierName()
    return "hero_akasha_shadow_strike_modifier"
end

function hero_akasha_shadow_strike:OnProjectileHit(hTarget, vLocation)
    -- get references
    local caster = self:GetCaster()

    local initialDamage = self:GetLevelSpecialValueFor("strike_damage", (self:GetLevel() - 1))
    local overtimeDamage = self:GetLevelSpecialValueFor("duration_damage", (self:GetLevel() - 1))
    local overtimeDamageInterval = self:GetLevelSpecialValueFor("damage_interval", (self:GetLevel() - 1))
    local duration = self:GetLevelSpecialValueFor("duration", (self:GetLevel() - 1))

    EmitSoundOnLocationWithCaster(hTarget:GetOrigin(), "Hero_QueenOfPain.ShadowStrike.Target.TI8", hTarget)
    CreateParticleWithTargetAndDuration("particles/econ/items/queen_of_pain/qop_ti8_immortal/queen_ti8_golden_shadow_strike_debuff.vpcf", hTarget, duration)

    -- Apply strike damage
    local strikeDamage = {
        victim = hTarget,
        attacker = caster,
        damage = initialDamage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
    }

    ApplyDamage(strikeDamage)

    -- Add debuff modifier
    hTarget:AddNewModifier(caster, self, "hero_akasha_shadow_strike_modifier_debuff", { duration = duration, interval = overtimeDamageInterval, damage = overtimeDamage })
end
---------
function hero_akasha_shadow_strike_modifier:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function hero_akasha_shadow_strike_modifier:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    if not RollPercentage(ability:GetSpecialValueFor("chance")) then return end

    EmitSoundOn("Hero_QueenOfPain.ShadowStrike", parent)

    local projectileSpeed = ability:GetLevelSpecialValueFor("projectile_speed", (ability:GetLevel() - 1))
    local projectile = "particles/econ/items/queen_of_pain/qop_ti8_immortal/queen_ti8_golden_shadow_strike.vpcf"

    local info = {
        Source = parent,
        Target = target,
        Ability = ability,
        iMoveSpeed = projectileSpeed,
        EffectName = projectile,
        bDodgeable = false,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
    }

    ProjectileManager:CreateTrackingProjectile(info)
end
---------
function hero_akasha_shadow_strike_modifier_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }

    return funcs
end

function hero_akasha_shadow_strike_modifier_debuff:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()

    self.target = self:GetParent()

    self.ability = self:GetAbility()

    self.interval = params.interval

    self.damage = params.damage+(self.caster:GetBaseIntellect()*(self.ability:GetSpecialValueFor("int_to_damage")/100))

    self:StartIntervalThink(self.interval)
end

function hero_akasha_shadow_strike_modifier_debuff:OnIntervalThink()
    if not IsServer() then return end

    local overtimeDamage = {
        victim = self.target,
        attacker = self.caster,
        damage = self.damage*self.interval,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability
    }

    ApplyDamage(overtimeDamage)

    local debuff = self.target:FindModifierByName("hero_akasha_shadow_strike_modifier_damage_debuff")
    if not debuff then
        debuff = self.target:AddNewModifier(self.caster, self.ability, "hero_akasha_shadow_strike_modifier_damage_debuff", {
            duration = self.ability:GetSpecialValueFor("duration")
        })
    end

    if debuff then
        if debuff:GetStackCount() < self.ability:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end
end

function hero_akasha_shadow_strike_modifier_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("movement_slow", (self:GetAbility():GetLevel() - 1))
end

function hero_akasha_shadow_strike_modifier_debuff:OnDestroy()
    if not IsServer() then return end

    local target = self:GetParent()

    target:RemoveModifierByName("hero_akasha_shadow_strike_modifier_damage_debuff")
end
------------
function hero_akasha_shadow_strike_modifier_damage_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function hero_akasha_shadow_strike_modifier_damage_debuff:GetModifierMagicalResistanceBonus()
    local stackCount = self:GetParent():GetModifierStackCount("hero_akasha_shadow_strike_modifier_damage_debuff", self:GetCaster())

    return stackCount * self:GetAbility():GetLevelSpecialValueFor("damage_increase_debuff_interval_pct", (self:GetAbility():GetLevel() - 1))
end