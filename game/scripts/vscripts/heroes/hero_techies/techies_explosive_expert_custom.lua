LinkLuaModifier("modifier_techies_explosive_expert_custom", "heroes/hero_techies/techies_explosive_expert_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_explosive_expert_custom_buff", "heroes/hero_techies/techies_explosive_expert_custom", LUA_MODIFIER_MOTION_NONE)

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


techies_explosive_expert_custom = class(ItemBaseClass)
modifier_techies_explosive_expert_custom = class(techies_explosive_expert_custom)
modifier_techies_explosive_expert_custom_buff = class(ItemBaseClassBuff)
-------------
function techies_explosive_expert_custom:GetIntrinsicModifierName()
    return "modifier_techies_explosive_expert_custom"
end
---------------------
function modifier_techies_explosive_expert_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE 
    }
end

function modifier_techies_explosive_expert_custom:GetModifierPercentageCasttime()
    if self:GetAbility():GetLevel() < 1  then return end
    return 100
end

function modifier_techies_explosive_expert_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
end

function modifier_techies_explosive_expert_custom:OnAbilityExecuted(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if ability:GetLevel() < 1  then return end

    if parent ~= event.unit then return end
    if event.ability == ability then return end
    if not string.match(event.ability:GetAbilityName(), "techies") then return end

    -- Stacks --
    local buff = parent:FindModifierByName("modifier_techies_explosive_expert_custom_buff")

    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_techies_explosive_expert_custom_buff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if buff then
        if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end
---------------------
function modifier_techies_explosive_expert_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE  
    }
end

function modifier_techies_explosive_expert_custom_buff:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp") * self:GetStackCount()
end