LinkLuaModifier("modifier_hoodwink_sharpshooter_custom", "heroes/hero_hoodwink/hoodwink_sharpshooter_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_sharpshooter_custom_buff", "heroes/hero_hoodwink/hoodwink_sharpshooter_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hoodwink_sharpshooter_custom_debuff", "heroes/hero_hoodwink/hoodwink_sharpshooter_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
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

hoodwink_sharpshooter_custom = class(ItemBaseClass)
modifier_hoodwink_sharpshooter_custom = class(hoodwink_sharpshooter_custom)
modifier_hoodwink_sharpshooter_custom_buff = class(ItemBaseClassBuff)
hoodwink_sharpshooter_cancel_custom = class(ItemBaseClass)
modifier_hoodwink_sharpshooter_custom_debuff = class(ItemBaseClassDebuff)

_G.hoodwink_sharpshooter_custom_projectiles = {}
-----------------------------------------------------------------
function hoodwink_sharpshooter_cancel_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local cancel = caster:FindAbilityByName("hoodwink_sharpshooter_cancel_custom")
    if not cancel or cancel == nil then return end

    caster:SwapAbilities(
        "hoodwink_sharpshooter_cancel_custom",
        "hoodwink_sharpshooter_custom",
        false,
        true
    )

    cancel:SetHidden(true)

    local sharpshooter = caster:FindAbilityByName("hoodwink_sharpshooter_custom")
    if not sharpshooter or sharpshooter == nil then return end

    sharpshooter:UseResources(false, false, false, true)

    -- Add modifier
    caster:RemoveModifierByName("modifier_hoodwink_sharpshooter_custom_buff")
end
-----------------------------------------------------------------
function hoodwink_sharpshooter_custom:GetIntrinsicModifierName()
    return "modifier_hoodwink_sharpshooter_custom"
end

function hoodwink_sharpshooter_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local cancel = caster:FindAbilityByName("hoodwink_sharpshooter_cancel_custom")
    if not cancel or cancel == nil then return end

    EmitSoundOn("Hero_Hoodwink.Sharpshooter.Cast", caster)

    caster:SwapAbilities(
        "hoodwink_sharpshooter_cancel_custom",
        "hoodwink_sharpshooter_custom",
        true,
        false
    )

    cancel:SetHidden(false)
    cancel:SetLevel(1)

    self:SetCurrentAbilityCharges(self:GetCurrentAbilityCharges()+1)

    cancel:SetCurrentAbilityCharges(self:GetCurrentAbilityCharges())

    -- Add modifier
    caster:AddNewModifier(caster, self, "modifier_hoodwink_sharpshooter_custom_buff", {})
end

function hoodwink_sharpshooter_custom:OnProjectileHitHandle( target, location, handle )
    local caster = self:GetCaster()

    if not target then
        -- unregister projectile
        _G.hoodwink_sharpshooter_custom_projectiles[handle] = nil
        return
    end

    -- get data
    local data = _G.hoodwink_sharpshooter_custom_projectiles[handle]
    local multiplier = 1
    local damage = data.damage

    if caster:HasScepter() then
        -- Calculate damage based on distance between Hoodwink and the target
        local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()

        local maxRange = self:GetSpecialValueFor("arrow_range")
        local minRange = self:GetSpecialValueFor("min_damage_range")
        local baseMultiplier = (((minRange / self:GetSpecialValueFor("units_per_increase")) * self:GetSpecialValueFor("increase_per_units"))/100)

        if distance > maxRange then
            distance = maxRange
        end

        multiplier = baseMultiplier + (((distance / self:GetSpecialValueFor("units_per_increase")) * self:GetSpecialValueFor("increase_per_units"))/100)

        if distance < minRange then 
             multiplier = 1
        end

        damage = data.damage * multiplier

        SendOverheadEventMessage(
            nil,
            OVERHEAD_ALERT_CRITICAL,
            target,
            damage,
            nil
        )
    end

    -- damage
    local damageTable = {
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
        ability = self, --Optional.
    }

    ApplyDamage(damageTable)

    target:AddNewModifier(caster, self, "modifier_hoodwink_sharpshooter_custom_debuff", {
        duration = self:GetSpecialValueFor("debuff_duration")
    })

    -- reduce damage
    data.damage = damage

    local direction = Vector( data.direction.x, data.direction.y, 0 ):Normalized()
    self:PlayEffects(target, direction)
end

function hoodwink_sharpshooter_custom:PlayEffects( target, direction )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_impact.vpcf"
    local sound_cast = "Hero_Hoodwink.Sharpshooter.Target"

    -- Get Data

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, target:GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 1, direction )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
-----------------------------------------------------------------
function modifier_hoodwink_sharpshooter_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_MAX_ATTACK_RANGE 
    }
end

function modifier_hoodwink_sharpshooter_custom:GetModifierMaxAttackRange()
    return self:GetAbility():GetSpecialValueFor("arrow_range")
end

function modifier_hoodwink_sharpshooter_custom:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("arrow_range")
end
-----------------------------------------------------------------
function modifier_hoodwink_sharpshooter_custom_buff:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK 
    }
end

function modifier_hoodwink_sharpshooter_custom_buff:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
end

function modifier_hoodwink_sharpshooter_custom_buff:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local cancel = caster:FindAbilityByName("hoodwink_sharpshooter_cancel_custom")
    if not cancel or cancel == nil then return end

    local charge = cancel:GetCurrentAbilityCharges()
    if charge > 0 then
        charge = charge+1 -- We have to do this because you lose 1 charge too many otherwise (e.g. end at 8 but you start at 7)
    end

    ability:SetCurrentAbilityCharges(charge)
end

function modifier_hoodwink_sharpshooter_custom_buff:OnAttack(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or unit:IsIllusion() then
        return
    end

    if not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim) then return end

    if event.no_attack_cooldown then return end

    local cancel = caster:FindAbilityByName("hoodwink_sharpshooter_cancel_custom")
    if not cancel or cancel == nil then return end

    EmitSoundOn("Hero_Hoodwink.Sharpshooter.MaxCharge", caster)

    local ability = self:GetAbility()

    local damage = (caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("damage_from_attack")/100)) + ability:GetSpecialValueFor("damage")

    local point = caster:GetForwardVector()
    local projectile_direction = point
    projectile_direction.z = 0
    projectile_direction = projectile_direction:Normalized()

    -- Create projectile
    local info = {
        Source = caster,
        Ability = ability,
        vSpawnOrigin = caster:GetAbsOrigin(),
        
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        
        EffectName = "particles/units/heroes/hero_hoodwink/hoodwink_sharpshooter_projectile.vpcf",
        fDistance = ability:GetSpecialValueFor("arrow_range"),
        fStartRadius = ability:GetSpecialValueFor("arrow_width"),
        fEndRadius = ability:GetSpecialValueFor("arrow_width"),
        vVelocity = projectile_direction * ability:GetSpecialValueFor("arrow_speed"),
    
        bProvidesVision = true,
        iVisionRadius = ability:GetSpecialValueFor("arrow_vision"),
        iVisionTeamNumber = caster:GetTeamNumber(),
    }


    local projectile = ProjectileManager:CreateLinearProjectile(info)

    _G.hoodwink_sharpshooter_custom_projectiles[projectile] = {}
    _G.hoodwink_sharpshooter_custom_projectiles[projectile].damage = damage
    _G.hoodwink_sharpshooter_custom_projectiles[projectile].direction = projectile_direction

    EmitSoundOn("Hero_Hoodwink.Sharpshooter.Projectile", caster)

    -- Spend charges
    local cost = 1
    if caster:HasTalent("special_bonus_unique_hoodwink_2_custom") then
        if RollPercentage(caster:FindAbilityByName("special_bonus_unique_hoodwink_2_custom"):GetSpecialValueFor("value")) then
            cost = 0
        end
    end

    self.charges = cancel:GetCurrentAbilityCharges() - cost

    cancel:SetCurrentAbilityCharges(self.charges)

    if cancel:GetCurrentAbilityCharges() <= 0 then
        caster:SwapAbilities(
            "hoodwink_sharpshooter_cancel_custom",
            "hoodwink_sharpshooter_custom",
            false,
            true
        )

        cancel:SetHidden(true)

        ability:UseResources(false, false, false, true)

        self:Destroy()
    end
end
------------------------------
function modifier_hoodwink_sharpshooter_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_hoodwink_sharpshooter_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow_move_pct")
end