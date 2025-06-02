LinkLuaModifier("modifier_monkey_king_boundless_strike_stack_custom", "heroes/hero_monkey_king/monkey_king_boundless_strike_stack_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_king_boundless_strike_stack_custom_buff_permanent", "heroes/hero_monkey_king/monkey_king_boundless_strike_stack_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}
local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}


monkey_king_boundless_strike_stack_custom = class(ItemBaseClass)
modifier_monkey_king_boundless_strike_stack_custom = class(monkey_king_boundless_strike_stack_custom)
modifier_monkey_king_boundless_strike_stack_custom_buff_permanent = class(ItemBaseClassBuff)
-------------
function modifier_monkey_king_boundless_strike_stack_custom_buff_permanent:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_monkey_king_boundless_strike_stack_custom_buff_permanent:OnTooltip()
    local chance = self:GetStackCount() * self:GetAbility():GetSpecialValueFor("pure_chance")
    if chance >= self:GetAbility():GetSpecialValueFor("pure_chance_max") then
        chance = self:GetAbility():GetSpecialValueFor("pure_chance_max")
    end

    return chance
end

function modifier_monkey_king_boundless_strike_stack_custom_buff_permanent:OnTooltip2()
    local critDamage = self:GetStackCount() * self:GetAbility():GetSpecialValueFor("crit_per_kill")
    return critDamage
end

function modifier_monkey_king_boundless_strike_stack_custom_buff_permanent:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
        MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_TOOLTIP2
    }

    return funcs
end

function modifier_monkey_king_boundless_strike_stack_custom_buff_permanent:GetModifierOverrideAbilityValues(params)
    if self:GetParent() == nil or params.ability == nil then
        return 0
    end

    local szAbilityName = params.ability:GetAbilityName()
    local szSpecialValueName = params.ability_special_value

    if szAbilityName ~= "monkey_king_boundless_strike_custom" then
        return 0
    end

    if szSpecialValueName == "strike_crit_mult" then
        return 1
    end

    return 0
end


function modifier_monkey_king_boundless_strike_stack_custom_buff_permanent:GetModifierOverrideAbilityValuesValue(params)
    local szAbilityName = params.ability:GetAbilityName()
    local szSpecialValueName = params.ability_special_value

    if szAbilityName == "monkey_king_boundless_strike_custom" and string.find(szSpecialValueName, "strike_crit_mult") then
        local nSpecialLevel = params.ability_special_level
        local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( szSpecialValueName, nSpecialLevel )
        return (flBaseValue) + (self:GetAbility():GetSpecialValueFor("crit_per_kill") * self:GetStackCount())
    end
end
-------------
function monkey_king_boundless_strike_stack_custom:GetIntrinsicModifierName()
    return "modifier_monkey_king_boundless_strike_stack_custom"
end


function modifier_monkey_king_boundless_strike_stack_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH 
    }
    return funcs
end

function modifier_monkey_king_boundless_strike_stack_custom:OnCreated()
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.parent:AddNewModifier(self.parent, self:GetAbility(), "modifier_monkey_king_boundless_strike_stack_custom_buff_permanent", {})
end

function modifier_monkey_king_boundless_strike_stack_custom:OnDeath(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local victim = event.unit

    if not unit or unit == nil or unit:IsNull() then return end
    if unit ~= parent then return end
    if not unit:IsAlive() then return end
        
    local owner = unit:GetOwner()
    if not owner:IsPlayerController() then
        local unitName = unit:GetUnitName()
        if unitName == "npc_dota_monkey_clone_custom" then
            unit = owner
            parent = unit
        end
    end

    --[[
    if unit ~= parent then
        if not unit:IsAlive() or not unit or unit == nil or unit:IsNull() then return end
        if not unit:GetOwner() or unit:GetOwner():IsNull() or unit:GetOwner() == nil then return end
        if unit:GetOwner():GetUnitName() ~= "npc_dota_hero_monkey_king" then
            return
        else
            unit = unit:GetOwner()
            parent = unit
            if event.inflictor ~= nil then event.inflictor = parent:FindAbilityByName("monkey_king_boundless_strike_custom") end
        end
    end
    --]]

    if unit:FindAbilityByName("monkey_king_boundless_strike_custom") == nil then return end
    if unit:FindAbilityByName("monkey_king_boundless_strike_custom"):GetLevel() < 1 then return end

    if event.inflictor ~= nil and unit:IsAlive() then
        local ability = event.inflictor
        if not ability or ability == nil then return end
        local abilityName = ability:GetAbilityName()
        if abilityName ~= nil then
            if abilityName == "monkey_king_boundless_strike_custom" then
                local ability = self:GetAbility()

                local buff = unit:FindModifierByNameAndCaster("modifier_monkey_king_boundless_strike_stack_custom_buff_permanent", unit)
                local stacks = unit:GetModifierStackCount("modifier_monkey_king_boundless_strike_stack_custom_buff_permanent", unit)
                
                if not buff then
                    unit:AddNewModifier(unit, ability, "modifier_monkey_king_boundless_strike_stack_custom_buff_permanent", {})
                else
                    buff:ForceRefresh()
                end

                unit:SetModifierStackCount("modifier_monkey_king_boundless_strike_stack_custom_buff_permanent", unit, (stacks + 1))
            end
        end
    end
end