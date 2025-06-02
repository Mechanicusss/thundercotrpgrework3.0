LinkLuaModifier("modifier_muerta_gunslinger_custom", "heroes/hero_muerta/muerta_gunslinger_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muerta_gunslinger_custom_debuff", "heroes/hero_muerta/muerta_gunslinger_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muerta_gunslinger_custom_doubleshot_damage", "heroes/hero_muerta/muerta_gunslinger_custom", LUA_MODIFIER_MOTION_NONE)

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

muerta_gunslinger_custom = class(ItemBaseClass)
modifier_muerta_gunslinger_custom = class(muerta_gunslinger_custom)
modifier_muerta_gunslinger_custom_debuff = class(ItemBaseClassDebuff)
modifier_muerta_gunslinger_custom_doubleshot_damage = class(ItemBaseClassDebuff)
-------------
function muerta_gunslinger_custom:GetIntrinsicModifierName()
    return "modifier_muerta_gunslinger_custom"
end

function muerta_gunslinger_custom:OnProjectileHit(target, location)
    local caster = self:GetCaster()
    local ability = self

    target:AddNewModifier(caster, ability, "modifier_muerta_gunslinger_custom_debuff", {
        duration = ability:GetSpecialValueFor("duration")
    })

    caster:AddNewModifier(caster, ability, "modifier_muerta_gunslinger_custom_doubleshot_damage", {
        duration = 1
    })

    caster:PerformAttack(
        target,
        true,
        true,
        true,
        false,
        false,
        false,
        false
    )

    caster:RemoveModifierByName("modifier_muerta_gunslinger_custom_doubleshot_damage")

    EmitSoundOn("Hero_Muerta.Attack.DoubleShot", target)
end
------------
function modifier_muerta_gunslinger_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_muerta_gunslinger_custom:FireShot(target)
    local parent = self:GetParent()

    local effect_castLeft = ParticleManager:CreateParticle("particles/units/heroes/hero_muerta/muerta_gunslinger_left.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(
        effect_castLeft,
        0,
        parent,
        PATTACH_CUSTOMORIGIN_FOLLOW,
        "attach_attack1",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:ReleaseParticleIndex(effect_castLeft)

    local effect_castRight = ParticleManager:CreateParticle("particles/units/heroes/hero_muerta/muerta_gunslinger_right.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(
        effect_castRight,
        0,
        parent,
        PATTACH_CUSTOMORIGIN_FOLLOW,
        "attach_attack2",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:ReleaseParticleIndex(effect_castRight)

    self.target = target

    self:StartIntervalThink(parent:GetAttackAnimationPoint())
end

function modifier_muerta_gunslinger_custom:OnAttackStart(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end
    if parent:PassivesDisabled() then return end
    if not parent:IsRangedAttacker() then return end

    local ability = self:GetAbility()

    if not RollPseudoRandomPercentage(ability:GetSpecialValueFor("chance"), ability:entindex()+100, parent) then return end

    parent:StartGesture(ACT_DOTA_CAST_ABILITY_3)

    local radius = parent:Script_GetAttackRange()+150

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsAttackImmune() or victim:IsInvulnerable() then return end

        if #victims > 1 then
            if victim ~= event.target then
                self:FireShot(victim)
                break
            end
        else
            self:FireShot(victim)
            break
        end
    end
end

function modifier_muerta_gunslinger_custom:OnIntervalThink()
    local parent = self:GetParent()

    local projName = parent:GetRangedProjectileName()
    local speed = parent:GetProjectileSpeed()

    local proj = {
        Target = self.target,
        iMoveSpeed = speed,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
        bVisibleToEnemies = true,
        EffectName = projName,
        Ability = self:GetAbility(),
        Source = parent,
        bProvidesVision = false,
    }

    ProjectileManager:CreateTrackingProjectile(proj)

    parent:RemoveGesture(ACT_DOTA_CAST_ABILITY_3)

    self:StartIntervalThink(-1)
end
-------------
function modifier_muerta_gunslinger_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_muerta_gunslinger_custom_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_reduction")
end
----------------
function modifier_muerta_gunslinger_custom_doubleshot_damage:IsHidden() return true end

function modifier_muerta_gunslinger_custom_doubleshot_damage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    }
end

function modifier_muerta_gunslinger_custom_doubleshot_damage:GetModifierTotalDamageOutgoing_Percentage(event)
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end