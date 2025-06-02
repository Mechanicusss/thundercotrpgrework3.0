LinkLuaModifier("hero_akasha_scream_of_pain_modifier", "heroes/hero_akasha/scream_of_pain", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("hero_akasha_scream_of_pain_modifier_debuff", "heroes/hero_akasha/scream_of_pain", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local BaseClassDebuff = {
    IsPurgable = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end
}

hero_akasha_scream_of_pain = class(BaseClass)
hero_akasha_scream_of_pain_modifier = class(BaseClass)
hero_akasha_scream_of_pain_modifier_debuff = class(BaseClassDebuff)

function hero_akasha_scream_of_pain:GetIntrinsicModifierName()
    return "hero_akasha_scream_of_pain_modifier"
end

function hero_akasha_scream_of_pain_modifier:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function hero_akasha_scream_of_pain_modifier:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.target or parent == event.attacker then return end

    local attacker = event.attacker 

    if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end 

    if not parent:HasModifier("modifier_item_aghanims_shard") then return end

    local ability = self:GetAbility()

    if not RollPercentage(ability:GetSpecialValueFor("chance")) then return end

    EmitSoundOn("Hero_QueenOfPain.ScreamOfPain", parent)
    ability:FireScream(attacker)
end

function hero_akasha_scream_of_pain_modifier:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function hero_akasha_scream_of_pain_modifier:OnRemoved()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    if not parent:IsAlive() and ability:GetAutoCastState() then
        ability:ToggleAutoCast()
    end

    self:StartIntervalThink(-1)
end

function hero_akasha_scream_of_pain_modifier:OnIntervalThink()
    if self:GetParent():IsChanneling() then return end
    
    if self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() and self:GetAbility():IsCooldownReady() then
        SpellCaster:Cast(self:GetAbility(), nil, true)
    end
end

function hero_akasha_scream_of_pain:FireScream(target)
    local caster = self:GetCaster()

    local projectileSpeed = self:GetLevelSpecialValueFor("projectile_speed", (self:GetLevel() - 1))
    local projectile = "particles/units/heroes/hero_queenofpain/queen_scream_of_pain.vpcf"

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

function hero_akasha_scream_of_pain:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_QueenOfPain.ScreamOfPain", caster)

    local aoe = self:GetLevelSpecialValueFor("area_of_effect", (self:GetLevel() - 1))

    local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #units < 1 then return end

    for _,target in ipairs(units) do
        self:FireScream(target)
    end
end

function hero_akasha_scream_of_pain:OnProjectileHit(hTarget, vLocation)
    local caster = self:GetCaster()
    local damage = self:GetLevelSpecialValueFor("damage", (self:GetLevel() - 1)) + (caster:GetBaseIntellect()*(self:GetSpecialValueFor("int_to_damage")/100))

    local debuffDuration = self:GetLevelSpecialValueFor("magic_res_duration", (self:GetLevel() - 1))

    CreateParticleWithTargetAndDuration("particles/units/heroes/hero_queenofpain/queen_scream_of_pain_explosion.vpcf", hTarget, 1.0)

    local hitDamage = {
        victim = hTarget,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
    }

    ApplyDamage(hitDamage)

    local mod = hTarget:FindModifierByName("hero_akasha_scream_of_pain_modifier_debuff")
    if mod == nil then
        mod = hTarget:AddNewModifier(caster, self, "hero_akasha_scream_of_pain_modifier_debuff", { duration = debuffDuration })
    end

    if mod ~= nil then
        if mod:GetStackCount() < self:GetSpecialValueFor("max_stacks") then
            mod:IncrementStackCount()
        end
        mod:ForceRefresh()
    end
end
--------
function hero_akasha_scream_of_pain_modifier_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE  
    }
    return funcs
end

function hero_akasha_scream_of_pain_modifier_debuff:GetModifierIncomingDamage_Percentage(event)
    if event.inflictor == self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("magic_res_amount") * self:GetStackCount()
    end
end
