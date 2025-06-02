LinkLuaModifier("modifier_huskar_double_throw_custom", "heroes/hero_huskar/double_throw.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_huskar_double_throw_custom_attack", "heroes/hero_huskar/double_throw.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_huskar_double_throw_custom_damage", "heroes/hero_huskar/double_throw.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

huskar_double_throw_custom = class(ItemBaseClass)
modifier_huskar_double_throw_custom = class(huskar_double_throw_custom)
modifier_huskar_double_throw_custom_attack = class(ItemBaseClassBuff)
modifier_huskar_double_throw_custom_damage = class(ItemBaseClassBuff)
-------------
function huskar_double_throw_custom:GetIntrinsicModifierName()
    return "modifier_huskar_double_throw_custom"
end

function modifier_huskar_double_throw_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_START
    }
    return funcs
end

function modifier_huskar_double_throw_custom:OnAttackStart(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not unit:IsAlive() or unit:PassivesDisabled() or not unit:IsRangedAttacker() then
        return
    end

    local ability = self:GetAbility()
    if not ability:IsCooldownReady() then return end

    local chance = ability:GetSpecialValueFor("chance")

    if RollPercentageTCOT(ability, chance) and not unit:HasModifier("modifier_huskar_double_throw_custom_attack") then 
        local buff = unit:FindModifierByName("modifier_huskar_double_throw_custom_damage")
        if not buff then
            buff = unit:AddNewModifier(unit, ability, "modifier_huskar_double_throw_custom_damage", {
                duration = ability:GetSpecialValueFor("duration")
            })
        end

        if buff then
            if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
                buff:IncrementStackCount()
            end

            buff:ForceRefresh()
        end

        unit:AddNewModifier(victim, ability, "modifier_huskar_double_throw_custom_attack", {})
        ability:UseResources(false, false, false, true)
    end
end
----
function modifier_huskar_double_throw_custom_attack:OnCreated()
    if not IsServer() then return end

    local victim = self:GetCaster()

    if not victim then return end
    if not victim:IsAlive() then return end

    self.victim = victim

    local parent = self:GetParent()

    self:StartIntervalThink(parent:GetSecondsPerAttack(false))
end

function modifier_huskar_double_throw_custom_attack:OnIntervalThink()
    local parent = self:GetParent()

    parent:PerformAttack(self.victim, true, true, true, false, true, false, false)

    self:StartIntervalThink(-1)
    self:Destroy()
end

function modifier_huskar_double_throw_custom_attack:OnDestroy()
    if not IsServer() then return end 
    
    local parent = self:GetParent()
end
------------------
function modifier_huskar_double_throw_custom_damage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_huskar_double_throw_custom_damage:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct") * self:GetStackCount()
end

function modifier_huskar_double_throw_custom_damage:IsHidden() return false end