LinkLuaModifier("modifier_tidehunter_tentacle_custom", "heroes/hero_tidehunter/tidehunter_tentacle_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tidehunter_tentacle_custom_debuff", "heroes/hero_tidehunter/tidehunter_tentacle_custom", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

tidehunter_tentacle_custom = class(ItemBaseClass)
modifier_tidehunter_tentacle_custom = class(tidehunter_tentacle_custom)
modifier_tidehunter_tentacle_custom_debuff = class(ItemBaseClassDebuff)
-------------
function tidehunter_tentacle_custom:GetIntrinsicModifierName()
    return "modifier_tidehunter_tentacle_custom"
end

function tidehunter_tentacle_custom:OnProjectileHitHandle(target, loc, handle)
    if not target or target:IsNull() then 
        self.projs[handle] = nil
        return 
    end 

    if not target:IsAlive() then return end

    if target:IsMagicImmune() then return end

    local caster = self:GetCaster()

    self.projs[handle] = self.projs[handle] or 0
    self.projs[handle] = self.projs[handle] + 1

    local damage = self:GetSpecialValueFor("damage") + (caster:GetStrength() * (self:GetSpecialValueFor("str_to_damage")/100))
    local increase = self:GetSpecialValueFor("damage_increase_per_target_pct")

    if self.projs[handle] > 0 then
        damage = damage * ((increase/100) * self.projs[handle])
    end

    local damageType = self:GetAbilityDamageType()
    if caster:HasScepter() then
        damageType = DAMAGE_TYPE_PURE
    end

    ApplyDamage({
        attacker = caster,
        victim = target,
        damage = damage,
        damage_type = damageType,
        ability = self
    })

    EmitSoundOn("Ability.GushImpact", target)

    target:AddNewModifier(caster, self, "modifier_tidehunter_tentacle_custom_debuff", {
        duration = self:GetSpecialValueFor("debuff_duration")
    })
end

function tidehunter_tentacle_custom:Gush(point, spawnOrigin)
    if not IsServer() then return end 

    local caster = self:GetCaster()

    EmitSoundOn("Hero_Tidehunter.Gush.AghsProjectile", caster)

    local direction = (point - spawnOrigin):Normalized()
    local speed = self:GetSpecialValueFor("speed")
    local maxDistance = self:GetSpecialValueFor("max_distance")
    local radius = self:GetSpecialValueFor("radius")

    local proj = {
        vSpawnOrigin = spawnOrigin,
        vVelocity = direction * speed,
        fDistance = maxDistance,
        fStartRadius = radius,
        fEndRadius = radius,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_CREEP,DOTA_UNIT_TARGET_BASIC),
        EffectName = "particles/units/heroes/hero_tidehunter/tidehunter_gush_upgrade.vpcf",
        Ability = self,
        Source = caster,
        bProvidesVision = true,
        iVisionRadius = radius,
        fVisionDuration = 1,
        iVisionTeamNumber = caster:GetTeamNumber()
    }

    local id = ProjectileManager:CreateLinearProjectile(proj)

    -- We store the hit count of the current projectile
    self.projs = self.projs or {}
    self.projs[id] = self.projs[id] or 0
end
------------------------
function modifier_tidehunter_tentacle_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_tidehunter_tentacle_custom:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    --if parent.smash == true then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")

    if not RollPercentage(chance) then return end 

    ability:Gush(target:GetAbsOrigin(), parent:GetAbsOrigin())
end
----------
function modifier_tidehunter_tentacle_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_tidehunter_tentacle_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("debuff_slow")
end