nevermore_necromastery_custom = class({})
LinkLuaModifier( "modifier_nevermore_necromastery_custom", "heroes/hero_nevermore/necromastery.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function nevermore_necromastery_custom:GetIntrinsicModifierName()
    return "modifier_nevermore_necromastery_custom"
end

modifier_nevermore_necromastery_custom = class({})

--------------------------------------------------------------------------------

function modifier_nevermore_necromastery_custom:IsHidden()
    return false
end

function modifier_nevermore_necromastery_custom:IsDebuff()
    return false
end

function modifier_nevermore_necromastery_custom:IsPurgable()
    return false
end

function modifier_nevermore_necromastery_custom:RemoveOnDeath()
    return false
end

--------------------------------------------------------------------------------

function modifier_nevermore_necromastery_custom:OnCreated( kv )
    -- get references
    self.soul_release = self:GetAbility():GetSpecialValueFor("soul_release")
    self.soul_damage = self:GetAbility():GetSpecialValueFor("soul_damage")
    self.soul_hero_bonus = self:GetAbility():GetSpecialValueFor("soul_hero_bonus")

    if IsServer() then
        self:SetStackCount(0)
    end
end

function modifier_nevermore_necromastery_custom:OnRefresh( kv )
    -- get references
    self.soul_release = self:GetAbility():GetSpecialValueFor("soul_release")
    self.soul_damage = self:GetAbility():GetSpecialValueFor("soul_damage")
    self.soul_hero_bonus = self:GetAbility():GetSpecialValueFor("soul_hero_bonus")
end

function modifier_nevermore_necromastery_custom:OnUpgrade()
    -- get references
    self.soul_release = self:GetAbility():GetSpecialValueFor("soul_release")
    self.soul_damage = self:GetAbility():GetSpecialValueFor("soul_damage")
    self.soul_hero_bonus = self:GetAbility():GetSpecialValueFor("soul_hero_bonus")
end

function modifier_nevermore_necromastery_custom:OnHeroCalculateStatBonus()
    -- get references
    self.soul_release = self:GetAbility():GetSpecialValueFor("soul_release")
    self.soul_damage = self:GetAbility():GetSpecialValueFor("soul_damage")
    self.soul_hero_bonus = self:GetAbility():GetSpecialValueFor("soul_hero_bonus")
end

--------------------------------------------------------------------------------

function modifier_nevermore_necromastery_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }

    return funcs
end

function modifier_nevermore_necromastery_custom:GetModifierPreAttack_CriticalStrike(params)
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        local cost = self:GetAbility():GetSpecialValueFor("crit_stack_cost")

        if self:GetStackCount() >= cost and self:GetAbility():GetAutoCastState() then
            self.record = params.record

            return self:GetAbility():GetSpecialValueFor("crit_damage")
        end
    end
end

function modifier_nevermore_necromastery_custom:GetModifierProcAttack_Feedback(params)
    if IsServer() then
        if self.record then
            local cost = self:GetAbility():GetSpecialValueFor("crit_stack_cost")
            self:SetStackCount(self:GetStackCount() - cost)
            self.record = nil
        end
    end
end

--------------------------------------------------------------------------------
-- soul release
function modifier_nevermore_necromastery_custom:OnDeath( params )
    if IsServer() then
        self:DeathLogic( params )
        self:KillLogic( params )
    end
end

function modifier_nevermore_necromastery_custom:GetModifierPreAttack_BonusDamage( params )
    if not self:GetParent():IsIllusion() then
        return self:GetStackCount() * self.soul_damage
    end
end

function modifier_nevermore_necromastery_custom:OnTooltip()
    return self:GetStackCount() * self.soul_damage
end

--------------------------------------------------------------------------------
function modifier_nevermore_necromastery_custom:DeathLogic( params )
    -- filter
    local unit = params.unit
    local pass = false
    if unit==self:GetParent() and params.reincarnate==false then
        pass = true
    end

    -- logic
    if pass then
        --local after_death = math.floor(self:GetStackCount() * self.soul_release)
        --self:SetStackCount(math.max(after_death,1))
    end
end

function modifier_nevermore_necromastery_custom:KillLogic( params )
    -- filter
    local target = params.unit
    local attacker = params.attacker
    local pass = false
    if attacker==self:GetParent() and target~=self:GetParent() and attacker:IsAlive() then
        if (not target:IsIllusion()) and (not target:IsBuilding()) then
            pass = true
        end
    end

    -- logic
    if pass and (not self:GetParent():PassivesDisabled()) then
        local amount = self:GetAbility():GetSpecialValueFor("soul_per_kill")

        self:AddStack(amount)

        self:PlayEffects( target )
    end
end

function modifier_nevermore_necromastery_custom:AddStack( value )
    local current = self:GetStackCount()
    local after = current + value
    self:SetStackCount( after )
end

function modifier_nevermore_necromastery_custom:PlayEffects( target )
    -- Get Resources
    local projectile_name = "particles/units/heroes/hero_nevermore/nevermore_necro_souls.vpcf"

    -- CreateProjectile
    local info = {
        Target = self:GetParent(),
        Source = target,
        EffectName = projectile_name,
        iMoveSpeed = 400,
        vSourceLoc= target:GetAbsOrigin(),                -- Optional
        bDodgeable = false,                                -- Optional
        bReplaceExisting = false,                         -- Optional
        flExpireTime = GameRules:GetGameTime() + 5,      -- Optional but recommended
        bProvidesVision = false,                           -- Optional
    }
    ProjectileManager:CreateTrackingProjectile(info)
end