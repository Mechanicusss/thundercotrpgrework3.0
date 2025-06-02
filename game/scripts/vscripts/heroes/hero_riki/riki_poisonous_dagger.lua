LinkLuaModifier("modifier_riki_poisonous_dagger", "heroes/hero_riki/riki_poisonous_dagger.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_riki_poisonous_dagger_debuff", "heroes/hero_riki/riki_poisonous_dagger.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

riki_poisonous_dagger = class(ItemBaseClass)
modifier_riki_poisonous_dagger = class(riki_poisonous_dagger)
modifier_riki_poisonous_dagger_debuff = class(ItemBaseClassDebuff)
-------------
function riki_poisonous_dagger:GetIntrinsicModifierName()
    return "modifier_riki_poisonous_dagger"
end

function riki_poisonous_dagger:GetCooldown()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then return 0 end

    return self.BaseClass.GetCooldown(self, -1) or 0
end

function modifier_riki_poisonous_dagger:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }

    return funcs
end

function modifier_riki_poisonous_dagger:OnCreated()
    self.parent = self:GetParent()
end

function modifier_riki_poisonous_dagger:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if caster:IsIllusion() or not caster:IsRealHero() then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    local buff = victim:FindModifierByName("modifier_riki_poisonous_dagger_debuff")
    if buff == nil then
        buff = victim:AddNewModifier(caster, ability, "modifier_riki_poisonous_dagger_debuff", {
            duration = duration,
            damage = event.damage
        })
    end

    if buff ~= nil then
        if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end

        buff.damage = event.damage 
        
        buff:ForceRefresh()
    end

    ability:UseResources(false, false, false, true)
end
---
--
function modifier_riki_poisonous_dagger_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
    return funcs
end

function modifier_riki_poisonous_dagger_debuff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function modifier_riki_poisonous_dagger_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_riki_poisonous_dagger_debuff:OnCreated(params)
    if not IsServer() then return end

    local target = self:GetParent()
    local caster = self:GetCaster()

    self.damage = params.damage

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_venomancer/venomancer_poison_debuff_nova.vpcf", PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect_cast, 0, target:GetAbsOrigin() )

    self.interval = self:GetAbility():GetSpecialValueFor("interval")
    
    if caster:HasModifier("modifier_item_aghanims_shard") then 
        self.interval = self.interval / 2
    end

    self:StartIntervalThink(self.interval)
end

function modifier_riki_poisonous_dagger_debuff:OnIntervalThink()
    local damage = ((self.damage * (self:GetAbility():GetSpecialValueFor("agi_to_damage")/100))) * self:GetStackCount()

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = self:GetAbility()
    })
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), damage, nil)
end

function modifier_riki_poisonous_dagger_debuff:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end