LinkLuaModifier("modifier_servants_from_below", "heroes/hero_doom/servants_from_below", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_servants_from_below_disarm", "heroes/hero_doom/servants_from_below", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_servants_from_below_root", "heroes/hero_doom/servants_from_below", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemDebuffBaseClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
}

servants_from_below_uba = class(ItemBaseClass)
modifier_servants_from_below = class(servants_from_below_uba)
modifier_servants_from_below_disarm = class(ItemDebuffBaseClass)
modifier_servants_from_below_root = class(ItemDebuffBaseClass)
-------------
function servants_from_below_uba:GetIntrinsicModifierName()
    return "modifier_servants_from_below"
end

function servants_from_below_uba:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCursorTarget()
    local caster = self:GetCaster()
    local ability = self

    if not ability or ability:IsNull() then return end

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    local impactDamage = ability:GetLevelSpecialValueFor("damage", (ability:GetLevel() - 1))
    local bountyMultiplier = ability:GetLevelSpecialValueFor("creep_bounty_multiplier", (ability:GetLevel() - 1))
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))

    if not target or target:IsNull() or not target:IsAlive() then return end 

    if target:TriggerSpellAbsorb(ability) then return end
    if IsBossTCOTRPG(target) then return end
    if target:GetLevel() > caster:GetLevel() then return end

    target:AddNewModifier(caster, ability, "modifier_servants_from_below_disarm", { duration = duration })
    target:AddNewModifier(caster, ability, "modifier_servants_from_below_root", { duration = duration })
        
    CreateParticleWithTargetAndDuration("particles/units/heroes/hero_warlock/warlock_rain_of_chaos_explosion_fallback_mid.vpcf", target, 1.0)
    CreateParticleWithTargetAndDuration("particles/units/heroes/hero_warlock/warlock_rain_of_chaos_explosion.vpcf", target, 1.0)
    EmitSoundOnLocationWithCaster(target:GetOrigin(), "Hero_DoomBringer.DevourCast", target)

    -- Kill creeps instantly for bonus gold ---
    if target:IsCreep() or target:IsNeutralUnitType() then 
        local bonusGold = target:GetGoldBounty() * bountyMultiplier
        local bonusXP = target:GetDeathXP() * bountyMultiplier
        target:ForceKill(false)

        EmitSoundOnLocationWithCaster(target:GetOrigin(), "DOTA_Item.Hand_Of_Midas", target)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, target, bonusGold, nil)

        -- Display gold particle --
        local particle = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_midas_knuckles/alch_hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
        ParticleManager:ReleaseParticleIndex(particle)
        -- End --

        caster:ModifyGold(bonusGold, false, DOTA_ModifyGold_CreepKill)
        caster:AddExperience(bonusXP, DOTA_ModifyXP_CreepKill, false, false)
        return
    end
    ------

    local damage = {
        victim = target,
        attacker = caster,
        damage = impactDamage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    }

    ApplyDamage(damage)

    -- Look for additional targets in the AOE except the targeted unit --
    local point = self:GetCursorPosition()

    local extraTargets = FindUnitsInRadius(caster:GetTeam(), point, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER, false)

    for _,extra in ipairs(extraTargets) do
        if extra:IsAlive() and not extra:IsNull() and UnitIsNotMonkeyClone(extra) and extra ~= target then
            extra:AddNewModifier(caster, ability, "modifier_servants_from_below_root", { duration = duration })
        end
    end
end

function servants_from_below_uba:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
--------------
function modifier_servants_from_below_disarm:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true
    }

    return state
end
--------------
function modifier_servants_from_below_root:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_servants_from_below_root:OnDeath(event)
    if not IsServer() then return end

    local target = self:GetParent()

    if target ~= event.unit then return end

    ParticleManager:DestroyParticle(self.p1, true)
    ParticleManager:DestroyParticle(self.p2, true)
    target:StopSound("Hero_Warlock.Upheaval")
end

function modifier_servants_from_below_root:OnCreated(params)
    if not IsServer() then return end

    local target = self:GetParent()

    self.p1 = CreateParticleWithTargetAndDuration("particles/econ/items/warlock/warlock_staff_hellborn/warlock_upheaval_hellborn_debuff_base.vpcf", target, params.duration)
    self.p2 = CreateParticleWithTargetAndDuration("particles/econ/items/warlock/warlock_staff_hellborn/warlock_upheaval_hellborn_debuff.vpcf", target, params.duration)
    target:EmitSound("Hero_Warlock.Upheaval")

    Timers:CreateTimer(params.duration, function()
        target:StopSound("Hero_Warlock.Upheaval")
    end)
end

function modifier_servants_from_below_root:CheckState()
    local state = {
        [MODIFIER_STATE_ROOTED] = true
    }

    return state
end