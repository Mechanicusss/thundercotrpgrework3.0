LinkLuaModifier("modifier_mars_spear_of_mars_custom", "heroes/hero_mars/mars_spear_of_mars_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mars_spear_of_mars_custom_trailblazer_thinker", "heroes/hero_mars/mars_spear_of_mars_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mars_spear_of_mars_custom_casting", "heroes/hero_mars/mars_spear_of_mars_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mars_spear_of_mars_custom_debuff", "heroes/hero_mars/mars_spear_of_mars_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mars_spear_of_mars_custom_debuff_stunned", "heroes/hero_mars/mars_spear_of_mars_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassCasting = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

mars_spear_of_mars_custom = class(ItemBaseClass)
modifier_mars_spear_of_mars_custom = class(mars_spear_of_mars_custom)
modifier_mars_spear_of_mars_custom_casting = class(ItemBaseClassCasting)
modifier_mars_spear_of_mars_custom_debuff = class(ItemBaseClassDebuff)
modifier_mars_spear_of_mars_custom_trailblazer_thinker = class(ItemBaseClass)
modifier_mars_spear_of_mars_custom_debuff_stunned = class(ItemBaseClassDebuff)
-------------
function mars_spear_of_mars_custom:GetIntrinsicModifierName()
    return "modifier_mars_spear_of_mars_custom"
end

function mars_spear_of_mars_custom:GetAOERadius()
    return self:GetSpecialValueFor("spear_range")
end

function mars_spear_of_mars_custom:GetChannelTime()
    local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_mars_4_custom")
    if talent ~= nil and talent:GetLevel() > 0 then
        return 4 + talent:GetSpecialValueFor("value")
    end

    return 4
end

function mars_spear_of_mars_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    caster:AddNewModifier(caster, self, "modifier_mars_spear_of_mars_custom_casting", {
        x = point.x,
        y = point.y,
        z = point.z
    })
end

function mars_spear_of_mars_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_mars_spear_of_mars_custom_casting")
end

function mars_spear_of_mars_custom:OnProjectileThink(vLocation)
    if not IsServer() then return end

    if self.trailblazer_thinker and vLocation then
        self.trailblazer_thinker:SetAbsOrigin(vLocation)
    end
end

function mars_spear_of_mars_custom:OnProjectileHit(hTarget, vLoc)
    if not IsServer() then return end

    if not hTarget then return end

    local caster = self:GetCaster()
    local ability = self

    EmitSoundOn("Hero_Mars.Spear.Target", hTarget)

    hTarget:AddNewModifier(caster, ability, "modifier_mars_spear_of_mars_custom_debuff_stunned", {
        duration = ability:GetSpecialValueFor("stun_duration")
    })

    ApplyDamage({
        victim = hTarget,
        attacker = caster,
        damage = (caster:GetAverageTrueAttackDamage(caster)*(ability:GetSpecialValueFor("damage")/100)) + (caster:GetStrength() * (ability:GetSpecialValueFor("str_to_damage")/100)),
        ability = ability,
        damage_type = DAMAGE_TYPE_MAGICAL,
    })
end
-----------
function modifier_mars_spear_of_mars_custom_casting:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("interval")

    local vision = ability:GetSpecialValueFor("spear_vision")
    local speed = ability:GetSpecialValueFor("spear_speed")
    local radius = ability:GetSpecialValueFor("spear_width")
    local maxDistance = ability:GetSpecialValueFor("spear_range")
    self.point = Vector(params.x, params.y, params.z)
    local projectile_direction = (self.point - parent:GetAbsOrigin()):Normalized()
    
    self.proj = {
        vSpawnOrigin = parent:GetAbsOrigin(),
        vVelocity = projectile_direction * speed,
        fDistance = maxDistance,
        fStartRadius = radius,
        fEndRadius = radius,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_CREEP,DOTA_UNIT_TARGET_BASIC),
        EffectName = "particles/units/heroes/hero_mars/mars_spear.vpcf",
        Ability = ability,
        Source = parent,
        bProvidesVision = true,
        iVisionRadius = vision,
        fVisionDuration = 10,
        iVisionTeamNumber = parent:GetTeamNumber(),
    }

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_mars_spear_of_mars_custom_casting:OnIntervalThink()
    self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_5)

    EmitSoundOn("Hero_Mars.Spear.Cast", self:GetParent())

    EmitSoundOn("Hero_Mars.Spear", self:GetParent())

    self:FireSpear()
end

function modifier_mars_spear_of_mars_custom_casting:FireSpear()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local pos = caster:GetAbsOrigin()
    local team = caster:GetTeamNumber()
    local dur = ability:GetSpecialValueFor("shard_trail_duration")

    Timers:CreateTimer(0.25, function()
        self.trailblazer_thinker = CreateModifierThinker(
            caster,
            ability,
            "modifier_mars_spear_of_mars_custom_trailblazer_thinker",
            {duration = dur },
            pos,
            team,
            false
        )
        ProjectileManager:CreateLinearProjectile(self.proj)
    end)
end
--------
function modifier_mars_spear_of_mars_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE   
    }
end

function modifier_mars_spear_of_mars_custom_debuff:GetModifierDamageOutgoing_Percentage(event)
    return self:GetAbility():GetSpecialValueFor("damage_debuff")
end

function modifier_mars_spear_of_mars_custom_debuff:GetModifierMoveSpeedBonus_Percentage(event)
    return self:GetAbility():GetSpecialValueFor("shard_move_slow_pct")
end
---------
modifier_mars_spear_of_mars_custom_trailblazer_thinker = modifier_mars_spear_of_mars_custom_trailblazer_thinker or class({})

function modifier_mars_spear_of_mars_custom_trailblazer_thinker:IsPurgable() return false end

function modifier_mars_spear_of_mars_custom_trailblazer_thinker:CheckState() return {
    -- keep thinker visible by everyone, so the firefly ground pfx don't disappear when batrider is no longer visible
    [MODIFIER_STATE_PROVIDES_VISION] = true,
} end

function modifier_mars_spear_of_mars_custom_trailblazer_thinker:OnCreated(keys)
    if not IsServer() then return end

    self.tick_time = self:GetAbility():GetSpecialValueFor("shard_interval")
    self.start_pos = self:GetParent():GetAbsOrigin()
    local direction = (self:GetCaster():GetCursorPosition() - self.start_pos):Normalized()

    local direction = (self:GetCaster():GetCursorPosition() - self.start_pos):Normalized()
    self.end_pos = self.start_pos + direction * self:GetAbility():GetSpecialValueFor("spear_range")
    
    self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_mars/mars_spear_burning_trail.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.pfx, 0, self.start_pos)
    ParticleManager:SetParticleControl(self.pfx, 1, self.end_pos)
    ParticleManager:SetParticleControl(self.pfx, 2, Vector(self:GetAbility():GetSpecialValueFor("shard_trail_duration"), 0, 0))
    ParticleManager:SetParticleControl(self.pfx, 3, Vector(self:GetAbility():GetSpecialValueFor("shard_trail_radius"), 0, 0))

    self:StartIntervalThink(self.tick_time)
end

function modifier_mars_spear_of_mars_custom_trailblazer_thinker:OnIntervalThink()
    local damage = ((self:GetAbility():GetSpecialValueFor("shard_damage")+(self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("str_to_damage")/100))) * (self:GetAbility():GetSpecialValueFor("shard_dps") / 100)) * self.tick_time
    local enemies = FindUnitsInLine(self:GetCaster():GetTeamNumber(), self.start_pos, self.end_pos, nil, self:GetAbility():GetSpecialValueFor("shard_trail_radius"), self:GetAbility():GetAbilityTargetTeam(), self:GetAbility():GetAbilityTargetType(), self:GetAbility():GetAbilityTargetFlags())

    if #enemies > 0 then
        for _, enemy in pairs(enemies) do
            local debuff = enemy:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_mars_spear_of_mars_custom_debuff", {
                duration = self:GetAbility():GetSpecialValueFor("damage_debuff_duration")
            })

            if debuff then
                debuff:ForceRefresh()
            end

            ApplyDamage({
                attacker = self:GetCaster(),
                victim = enemy,
                damage = damage,
                damage_type = self:GetAbility():GetAbilityDamageType(),
                damage_flags = self:GetAbility():GetAbilityTargetFlags(),
                ability = self:GetAbility()
            })
        end
    end
end

function modifier_mars_spear_of_mars_custom_trailblazer_thinker:OnDestroy()
    if not IsServer() then return end

    self:GetParent():RemoveSelf()

    if self:GetAbility() then
        self:GetAbility().trailblazer_thinker = nil
    end

    if self.pfx then
        ParticleManager:DestroyParticle(self.pfx, false)
        ParticleManager:ReleaseParticleIndex(self.pfx)
    end
end
-------
function modifier_mars_spear_of_mars_custom_debuff_stunned:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
    }
    return state
end