LinkLuaModifier("modifier_ancient_apparition_frozen_time", "heroes/hero_ancient_apparition/ancient_apparition_frozen_time", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ancient_apparition_frozen_time_scepter_buff", "heroes/hero_ancient_apparition/ancient_apparition_frozen_time", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

ancient_apparition_frozen_time = class(ItemBaseClass)
modifier_ancient_apparition_frozen_time = class(ancient_apparition_frozen_time)
modifier_ancient_apparition_frozen_time_scepter_buff = class(ItemBaseClassBuff)

ALLOWED_ABILITY_TYPES = {
    DOTA_ABILITY_BEHAVIOR_NO_TARGET,
    DOTA_ABILITY_BEHAVIOR_UNIT_TARGET,
    DOTA_ABILITY_BEHAVIOR_POINT,
    DOTA_ABILITY_BEHAVIOR_AOE,
    DOTA_ABILITY_BEHAVIOR_CHANNELLED,
    DOTA_ABILITY_BEHAVIOR_DIRECTIONAL
}
-------------
function ancient_apparition_frozen_time:GetIntrinsicModifierName()
    return "modifier_ancient_apparition_frozen_time"
end

function ancient_apparition_frozen_time:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if not caster:HasScepter() then return end

    if caster:HasModifier("modifier_ancient_apparition_frozen_time_scepter_buff") then
        caster:RemoveModifierByNameAndCaster("modifier_ancient_apparition_frozen_time_scepter_buff", caster)
    end

    caster:AddNewModifier(caster, self, "modifier_ancient_apparition_frozen_time_scepter_buff", { duration = self:GetSpecialValueFor("scepter_duration") })

    local sharpIce = caster:FindAbilityByName("ancient_apparition_sharp_ice")
    if sharpIce ~= nil and sharpIce:GetLevel() > 0 and not sharpIce:IsCooldownReady() then
        sharpIce:EndCooldown()
    end
end

function ancient_apparition_frozen_time:GetBehavior()
    if self:GetCaster():HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET 
    end

    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function ancient_apparition_frozen_time:GetCooldown()
    if self:GetCaster():HasScepter() then
        return self:GetSpecialValueFor("scepter_cooldown")
    end

    return 0
end

function modifier_ancient_apparition_frozen_time:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH 
    }
    return funcs
end

function modifier_ancient_apparition_frozen_time:OnCreated()
    if not IsServer() then return end

    self.ready = true
end

function modifier_ancient_apparition_frozen_time:OnDeath(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    if not self.ready then return end

    local time = ability:GetSpecialValueFor("cooldown_reduction_seconds")

    for i=0, parent:GetAbilityCount()-1 do
        local abil = parent:GetAbilityByIndex(i)
        if abil ~= nil then
            if not abil:IsPassive() and abil:GetCooldown(abil:GetLevel()) > 0 and not abil:IsCooldownReady() then
                local remaining = abil:GetCooldownTimeRemaining()
                abil:EndCooldown()
                abil:StartCooldown(remaining-time)
            end
        end
    end

    self.ready = false
    Timers:CreateTimer(ability:GetSpecialValueFor("cooldown"), function()
        self.ready = true
    end)
end