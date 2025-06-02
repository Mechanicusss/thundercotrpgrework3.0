LinkLuaModifier("modifier_talent_sniper_2", "heroes/hero_sniper/talents/talent_sniper_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_sniper_2 = class(ItemBaseClass)
modifier_talent_sniper_2 = class(talent_sniper_2)
-------------
function talent_sniper_2:GetIntrinsicModifierName()
    return "modifier_talent_sniper_2"
end

function talent_sniper_2:OnProjectileHit_ExtraData(hTarget, hLoc, extraData)
    local caster = self:GetCaster()

    caster:PerformAttack(
        hTarget,
        true,
        true,
        true,
        false,
        false,
        true,
        true
    )

    ApplyDamage({
        attacker = caster,
        victim = hTarget,
        damage = extraData.damage * (self:GetSpecialValueFor("reduction")/100),
        damage_type = DAMAGE_TYPE_PHYSICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
    })
end
-------------
function modifier_talent_sniper_2:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local machine_gun = parent:FindAbilityByName("gun_joe_machine_gun")

    self.split_shot_attack = false

    if not machine_gun then return end

    if machine_gun:GetToggleState() then
        machine_gun:ToggleAbility()
    end

    machine_gun:SetActivated(false)
end

function modifier_talent_sniper_2:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local machine_gun = parent:FindAbilityByName("gun_joe_machine_gun")

    if not machine_gun then return end

    if machine_gun:GetToggleState() then
        machine_gun:ToggleAbility()
    end

    machine_gun:SetActivated(true)
end

function modifier_talent_sniper_2:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_talent_sniper_2:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end
    if not parent:HasModifier("modifier_gun_joe_rifle") then return end
    if event.original_damage <= 0 then return end

    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")
    local maxTargets = ability:GetSpecialValueFor("max_targets")

    if not RollPercentage(chance) then return end

    local radius = ability:GetSpecialValueFor("radius")

    local targetCount = 0

    local enemies = FindUnitsInRadius(parent:GetTeam(), target:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,enemy in ipairs(enemies) do
        if enemy:IsAlive() and not enemy:IsInvulnerable() and not enemy:IsAttackImmune() and enemy ~= target and targetCount < maxTargets then
            ProjectileManager:CreateTrackingProjectile({
                Target = enemy,
                iMoveSpeed = parent:GetProjectileSpeed(),
                bVisibleToEnemies = true,
                EffectName = parent:GetRangedProjectileName(),
                Source = target,
                Ability = ability,
                vSourceLoc = target:GetAbsOrigin(),
                ExtraData = {
                    damage = event.damage
                }
            })

            targetCount = targetCount + 1
        end
    end
end