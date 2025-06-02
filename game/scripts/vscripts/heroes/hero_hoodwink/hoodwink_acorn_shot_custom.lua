LinkLuaModifier("modifier_hoodwink_acorn_shot_custom", "heroes/hero_hoodwink/hoodwink_acorn_shot_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_acorn_shot_custom_bounce_thinker", "heroes/hero_hoodwink/hoodwink_acorn_shot_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_acorn_shot_custom_debuff", "heroes/hero_hoodwink/hoodwink_acorn_shot_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_acorn_shot_custom_debuff_armor", "heroes/hero_hoodwink/hoodwink_acorn_shot_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassThinker = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

hoodwink_acorn_shot_custom = class(ItemBaseClass)
modifier_hoodwink_acorn_shot_custom = class(hoodwink_acorn_shot_custom)
modifier_hoodwink_acorn_shot_custom_bounce_thinker = class(ItemBaseClassThinker)
modifier_hoodwink_acorn_shot_custom_debuff = class(ItemBaseClassDebuff)
modifier_hoodwink_acorn_shot_custom_debuff_armor = class(ItemBaseClassDebuff)

hoodwink_acorn_shot_custom.targets = {}
hoodwink_acorn_shot_custom.bounces = 0
-------------
function hoodwink_acorn_shot_custom:GetIntrinsicModifierName()
    return "modifier_hoodwink_acorn_shot_custom"
end

function hoodwink_acorn_shot_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    self.targets = {}
    self.bounces = 0

    EmitSoundOn("Hero_Hoodwink.AcornShot.Cast", caster)

    local projectile = {
        Target = target,
        Source = caster,
        Ability = self, 
        
        EffectName = "particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_tracking.vpcf",
        iMoveSpeed = 2200,
        bDodgeable = false,                           -- Optional
    
        bVisibleToEnemies = true,                         -- Optional
        bProvidesVision = true,                           -- Optional
        iVisionRadius = 200,                              -- Optional
        iVisionTeamNumber = caster:GetTeamNumber(),        -- Optional
        ExtraData = {
            
        }
    }

    ProjectileManager:CreateTrackingProjectile(projectile)
end

function hoodwink_acorn_shot_custom:OnProjectileHit_ExtraData(target, location, kv)
    local caster = self:GetCaster()

    self.targets[target:entindex()] = true

    EmitSoundOn("Hero_Hoodwink.AcornShot.Target", target)
    EmitSoundOn("Hero_Hoodwink.AcornShot.Bounce", target)

    if not caster:HasModifier("modifier_hoodwink_acorn_shot_custom_bounce_thinker") then
        caster:AddNewModifier(target, self, "modifier_hoodwink_acorn_shot_custom_bounce_thinker", {})
    end

    -- Slow
    local slow = target:AddNewModifier(caster, self, "modifier_hoodwink_acorn_shot_custom_debuff", {
        duration = self:GetSpecialValueFor("debuff_duration")
    })

    -- Armor corruption
    local debuff = target:FindModifierByName("modifier_hoodwink_acorn_shot_custom_debuff_armor")
    if not debuff then
        debuff = target:AddNewModifier(caster, self, "modifier_hoodwink_acorn_shot_custom_debuff_armor", {
            duration = self:GetSpecialValueFor("corruption_duration")
        })
    end

    if debuff then
        local maxStacks = self:GetSpecialValueFor("corruption_max_stacks")

        if caster:HasTalent("special_bonus_unique_hoodwink_1_custom") then
            maxStacks = maxStacks + caster:FindAbilityByName("special_bonus_unique_hoodwink_1_custom"):GetSpecialValueFor("value")
        end

        if debuff:GetStackCount() < maxStacks then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end

    local specialDamage = self:GetSpecialValueFor("acorn_shot_damage")
    if caster:HasTalent("special_bonus_unique_hoodwink_8_custom") then
        specialDamage = specialDamage + caster:FindAbilityByName("special_bonus_unique_hoodwink_8_custom"):GetSpecialValueFor("value")
    end

    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = specialDamage + (caster:GetAverageTrueAttackDamage(caster) * (self:GetSpecialValueFor("base_damage_pct")/100)),
        damage_type = self:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
        ability = self
    })

    self.bounces = self.bounces + 1
end
--------------------------------------------------------
function modifier_hoodwink_acorn_shot_custom_bounce_thinker:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local delay = ability:GetSpecialValueFor("bounce_delay")

    self:StartIntervalThink(delay)
end

function modifier_hoodwink_acorn_shot_custom_bounce_thinker:OnIntervalThink()
    local target = self:GetCaster()

    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("bounce_range")
    local parent = self:GetParent()

    local point = target:GetAbsOrigin()

    local maxBounces = ability:GetSpecialValueFor("bounce_count")
    local pass = true

    if ability.bounces >= maxBounces then 
        pass = false
    end

    local victims = FindUnitsInRadius(parent:GetTeam(), point, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    if #victims < 1 then 
        pass = false
    end

    local currentTarget = nil

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and parent:CanEntityBeSeenByMyTeam(victim) and not ability.targets[victim:entindex()] then
            currentTarget = victim
            break
        end
    end

    if not currentTarget or currentTarget == nil then
        pass = false
    end

    if not pass then
        self:StartIntervalThink(-1)
        self:Destroy()
        return 
    end

    local projectile = {
        Target = currentTarget,
        Source = target,
        Ability = ability, 
        
        EffectName = "particles/units/heroes/hero_hoodwink/hoodwink_acorn_shot_tracking.vpcf",
        iMoveSpeed = 2200,
        bDodgeable = false,                           -- Optional
    
        bVisibleToEnemies = true,                         -- Optional
        bProvidesVision = true,                           -- Optional
        iVisionRadius = 200,                              -- Optional
        iVisionTeamNumber = parent:GetTeamNumber(),        -- Optional
        ExtraData = {
            
        }
    }

    ProjectileManager:CreateTrackingProjectile(projectile)

    self:StartIntervalThink(-1)
    self:Destroy()
end
---------------------------------
function modifier_hoodwink_acorn_shot_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_hoodwink_acorn_shot_custom_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_hoodwink_acorn_shot_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end
-------------------------------------------
function modifier_hoodwink_acorn_shot_custom_debuff_armor:IsStackable() return true end

function modifier_hoodwink_acorn_shot_custom_debuff_armor:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_hoodwink_acorn_shot_custom_debuff_armor:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_hoodwink_acorn_shot_custom_debuff_armor:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("corruption") * self:GetStackCount()
end
-----------------
function modifier_hoodwink_acorn_shot_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK 
    }
    return funcs
end

function modifier_hoodwink_acorn_shot_custom:OnAttack(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:IsSilenced() then
        return
    end

    local ability = self:GetAbility()

    if not ability:GetAutoCastState() or not ability:IsCooldownReady() then return end

    if ability:GetManaCost(-1) > caster:GetMana() then return end

    if not ability:IsActivated() then return end

    SpellCaster:Cast(ability, victim, true)
end
