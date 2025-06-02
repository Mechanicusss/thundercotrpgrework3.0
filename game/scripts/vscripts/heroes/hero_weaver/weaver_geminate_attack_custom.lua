LinkLuaModifier("modifier_weaver_geminate_attack_custom", "heroes/hero_weaver/weaver_geminate_attack_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weaver_geminate_attack_custom_extra_attack", "heroes/hero_weaver/weaver_geminate_attack_custom", LUA_MODIFIER_MOTION_NONE)

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

weaver_geminate_attack_custom = class(ItemBaseClass)
modifier_weaver_geminate_attack_custom = class(weaver_geminate_attack_custom)
modifier_weaver_geminate_attack_custom_extra_attack = class(ItemBaseClassDebuff)
-------------
function weaver_geminate_attack_custom:GetIntrinsicModifierName()
    return "modifier_weaver_geminate_attack_custom"
end

function weaver_geminate_attack_custom:OnProjectileHit(target, location)
    local caster = self:GetCaster()
    local ability = self

    caster:AddNewModifier(caster, ability, "modifier_weaver_geminate_attack_custom_extra_attack", {
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

    caster:RemoveModifierByName("modifier_weaver_geminate_attack_custom_extra_attack")

    return true
end
------------
function modifier_weaver_geminate_attack_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ATTACK_CANCELLED,
    }
end

function modifier_weaver_geminate_attack_custom:FireShot(target, amount)
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.target = target

    local delay = ability:GetSpecialValueFor("delay")

    for i=1,amount,1 do
        Timers:CreateTimer(delay*i, function()
            if parent:IsNull() then return end 

            local projName = parent:GetRangedProjectileName()
            local speed = parent:GetProjectileSpeed()
    
            local proj = {
                Target = self.target,
                iMoveSpeed = speed,
                iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
                bVisibleToEnemies = true,
                EffectName = projName,
                Ability = ability,
                Source = parent,
                bProvidesVision = false,
            }
            
            -- Destroying an entity with active projectiles might crash the game?
            ProjectileManager:CreateTrackingProjectile(proj)
    
            EmitSoundOn("Hero_Weaver.Attack", parent)
        end)
    end
end

function modifier_weaver_geminate_attack_custom:OnAttackStart(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end
    if parent:PassivesDisabled() then return end
    if not parent:IsRangedAttacker() then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    self.attack = true
end

function modifier_weaver_geminate_attack_custom:OnAttackCancelled(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end
    if parent:PassivesDisabled() then return end
    if not parent:IsRangedAttacker() then return end

    local ability = self:GetAbility()

    self.attack = false
end

function modifier_weaver_geminate_attack_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end
    if parent:PassivesDisabled() then return end
    if not parent:IsRangedAttacker() then return end

    local ability = self:GetAbility()

    if not self.attack then return end 

    self:FireShot(event.target, 2)

    ability:UseResources(false, false, false, true)

    self.attack = false
end
----------------
function modifier_weaver_geminate_attack_custom_extra_attack:IsHidden() return true end

function modifier_weaver_geminate_attack_custom_extra_attack:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }
end

function modifier_weaver_geminate_attack_custom_extra_attack:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_weaver_geminate_attack_custom_extra_attack:GetModifierPreAttack_CriticalStrike( params )
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        self.record = params.record

        return self:GetAbility():GetSpecialValueFor("crit_damage") + (self:GetParent():GetAgility() * (self:GetAbility():GetSpecialValueFor("crit_per_agility")))
    end
end

function modifier_weaver_geminate_attack_custom_extra_attack:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end
end