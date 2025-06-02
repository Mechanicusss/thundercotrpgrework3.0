LinkLuaModifier("modifier_sniper_rapid_machinery_custom", "heroes/hero_sniper/sniper_rapid_machinery_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_rapid_machinery_custom_buff", "heroes/hero_sniper/sniper_rapid_machinery_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

sniper_rapid_machinery_custom = class(ItemBaseClass)
modifier_sniper_rapid_machinery_custom = class(sniper_rapid_machinery_custom)
modifier_sniper_rapid_machinery_custom_buff = class(ItemBaseClassBuff)
-------------
function sniper_rapid_machinery_custom:GetIntrinsicModifierName()
    return "modifier_sniper_rapid_machinery_custom"
end
------------
function modifier_sniper_rapid_machinery_custom:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if not caster:HasModifier("modifier_gun_joe_machine_gun") then
        ability:SetActivated(false)
    elseif caster:HasModifier("modifier_gun_joe_machine_gun") then
        ability:SetActivated(true)
    end
end

function modifier_sniper_rapid_machinery_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_sniper_rapid_machinery_custom:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
    
    self.target = nil
end

function modifier_sniper_rapid_machinery_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end
    if parent:PassivesDisabled() then return end
    if parent:IsIllusion() then return end

    local target = event.target
    local ability = self:GetAbility()

    if not ability:IsActivated() then return end

    if self.target ~= target and self.target ~= nil then
        -- Changed targets. Reset everything.
        parent:RemoveModifierByName("modifier_sniper_rapid_machinery_custom_buff")
    end

    self.target = target

    local mod = parent:FindModifierByName("modifier_sniper_rapid_machinery_custom_buff")
    if not mod then
        mod = parent:AddNewModifier(parent, ability, "modifier_sniper_rapid_machinery_custom_buff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if mod then
        if mod:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            mod:IncrementStackCount()
        end

        mod:ForceRefresh()
    end
end
---------------
function modifier_sniper_rapid_machinery_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
end

function modifier_sniper_rapid_machinery_custom_buff:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp") * self:GetStackCount()
end