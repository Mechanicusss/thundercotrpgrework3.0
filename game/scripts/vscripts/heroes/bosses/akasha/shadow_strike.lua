LinkLuaModifier("boss_queen_of_pain_shadow_strike_modifier", "heroes/bosses/akasha/shadow_strike", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_queen_of_pain_shadow_strike_modifier_debuff", "heroes/bosses/akasha/shadow_strike", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_queen_of_pain_shadow_strike_modifier_damage_debuff", "heroes/bosses/akasha/shadow_strike", LUA_MODIFIER_MOTION_NONE)

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

boss_queen_of_pain_shadow_strike = class(BaseClass)
boss_queen_of_pain_shadow_strike_modifier = class(BaseClass)
boss_queen_of_pain_shadow_strike_modifier_debuff = class(BaseClassDebuff)
boss_queen_of_pain_shadow_strike_modifier_damage_debuff = class(BaseClassDebuff)

function boss_queen_of_pain_shadow_strike:GetIntrinsicModifierName()
    return "boss_queen_of_pain_shadow_strike_modifier"
end

function boss_queen_of_pain_shadow_strike:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #units < 1 then return end

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_QueenOfPain.ShadowStrike", caster)

    local projectileSpeed = self:GetLevelSpecialValueFor("projectile_speed", (self:GetLevel() - 1))
    local projectile = "particles/econ/items/queen_of_pain/qop_ti8_immortal/queen_ti8_golden_shadow_strike.vpcf"

    for _,target in ipairs(units) do
        local info = {
            Source = caster,
            Target = target,
            Ability = self,
            iMoveSpeed = projectileSpeed,
            EffectName = projectile,
            bDodgeable = false,
            iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
        }

        ProjectileManager:CreateTrackingProjectile(info)
    end
end

function boss_queen_of_pain_shadow_strike:OnProjectileHit(hTarget, vLocation)
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
    hTarget:AddNewModifier(caster, self, "boss_queen_of_pain_shadow_strike_modifier_debuff", { duration = duration, interval = overtimeDamageInterval, damage = overtimeDamage })
end
---------
function boss_queen_of_pain_shadow_strike_modifier_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }

    return funcs
end

function boss_queen_of_pain_shadow_strike_modifier_debuff:OnCreated(params)
    if not IsServer() then return end

    self.caster = self:GetCaster()

    self.target = self:GetParent()

    self.ability = self:GetAbility()

    self.interval = params.interval

    self.damage = params.damage

    self:StartIntervalThink(self.interval)
end

function boss_queen_of_pain_shadow_strike_modifier_debuff:OnIntervalThink()
    if not IsServer() then return end

    local overtimeDamage = {
        victim = self.target,
        attacker = self.caster,
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability
    }

    ApplyDamage(overtimeDamage)

    local modifier = self.target:FindModifierByNameAndCaster("boss_queen_of_pain_shadow_strike_modifier_damage_debuff", self.caster)
    local stackCount = self.target:GetModifierStackCount("boss_queen_of_pain_shadow_strike_modifier_damage_debuff", self.caster)

    if modifier ~= nil then
        self.target:SetModifierStackCount("boss_queen_of_pain_shadow_strike_modifier_damage_debuff", self.caster, (stackCount+1))
        modifier:ForceRefresh()
    else
        self.target:AddNewModifier(self.caster, self.ability, "boss_queen_of_pain_shadow_strike_modifier_damage_debuff", {})
        self.target:SetModifierStackCount("boss_queen_of_pain_shadow_strike_modifier_damage_debuff", self.caster, 1)
    end
end

function boss_queen_of_pain_shadow_strike_modifier_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("movement_slow", (self:GetAbility():GetLevel() - 1))
end

function boss_queen_of_pain_shadow_strike_modifier_debuff:OnDestroy()
    if not IsServer() then return end

    local target = self:GetParent()

    target:RemoveModifierByName("boss_queen_of_pain_shadow_strike_modifier_damage_debuff")
end
------------
function boss_queen_of_pain_shadow_strike_modifier_damage_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }

    return funcs
end

function boss_queen_of_pain_shadow_strike_modifier_damage_debuff:GetModifierIncomingDamage_Percentage()
    local stackCount = self:GetParent():GetModifierStackCount("boss_queen_of_pain_shadow_strike_modifier_damage_debuff", self:GetCaster())

    return stackCount * self:GetAbility():GetLevelSpecialValueFor("damage_increase_debuff_interval_pct", (self:GetAbility():GetLevel() - 1))
end

function boss_queen_of_pain_shadow_strike_modifier_damage_debuff:GetModifierHealAmplify_PercentageTarget()
    local stackCount = self:GetParent():GetModifierStackCount("boss_queen_of_pain_shadow_strike_modifier_damage_debuff", self:GetCaster())

    return stackCount * self:GetAbility():GetLevelSpecialValueFor("degen", (self:GetAbility():GetLevel() - 1))
end

function boss_queen_of_pain_shadow_strike_modifier_damage_debuff:GetModifierHPRegenAmplify_Percentage()
    local stackCount = self:GetParent():GetModifierStackCount("boss_queen_of_pain_shadow_strike_modifier_damage_debuff", self:GetCaster())

    return stackCount * self:GetAbility():GetLevelSpecialValueFor("degen", (self:GetAbility():GetLevel() - 1))
end

function boss_queen_of_pain_shadow_strike_modifier_damage_debuff:GetModifierLifestealRegenAmplify_Percentage()
    local stackCount = self:GetParent():GetModifierStackCount("boss_queen_of_pain_shadow_strike_modifier_damage_debuff", self:GetCaster())

    return stackCount * self:GetAbility():GetLevelSpecialValueFor("degen", (self:GetAbility():GetLevel() - 1))
end

function boss_queen_of_pain_shadow_strike_modifier_damage_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    local stackCount = self:GetParent():GetModifierStackCount("boss_queen_of_pain_shadow_strike_modifier_damage_debuff", self:GetCaster())

    return stackCount * self:GetAbility():GetLevelSpecialValueFor("degen", (self:GetAbility():GetLevel() - 1))
end

function boss_queen_of_pain_shadow_strike_modifier_damage_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end