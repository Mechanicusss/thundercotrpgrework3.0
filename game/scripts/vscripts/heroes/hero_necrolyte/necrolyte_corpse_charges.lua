LinkLuaModifier("modifier_necrolyte_corpse_charges", "heroes/hero_necrolyte/necrolyte_corpse_charges", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_corpse_charges_buff_permanent", "heroes/hero_necrolyte/necrolyte_corpse_charges", LUA_MODIFIER_MOTION_NONE)

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


necrolyte_corpse_charges = class(ItemBaseClass)
modifier_necrolyte_corpse_charges = class(necrolyte_corpse_charges)
modifier_necrolyte_corpse_charges_buff_permanent = class(ItemBaseClassBuff)
-------------
function modifier_necrolyte_corpse_charges_buff_permanent:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE
    }

    return funcs
end

function modifier_necrolyte_corpse_charges_buff_permanent:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("spell_amp_per_charge") * self:GetStackCount()
end

function modifier_necrolyte_corpse_charges_buff_permanent:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("regen_amp_per_charge")
end
-------------
function necrolyte_corpse_charges:GetIntrinsicModifierName()
    return "modifier_necrolyte_corpse_charges"
end

function modifier_necrolyte_corpse_charges:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH 
    }
    return funcs
end

function modifier_necrolyte_corpse_charges:OnCreated()

end

function modifier_necrolyte_corpse_charges:OnDeath(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit
    local inflictor = event.inflictor

    if unit ~= parent then
        return
    end

    if not inflictor then return end 

    if string.match(inflictor:GetAbilityName(), "item_") then return end

    local ability = self:GetAbility()

    local buff = unit:FindModifierByName("modifier_necrolyte_corpse_charges_buff_permanent")
    
    if not buff then
        buff = unit:AddNewModifier(unit, ability, "modifier_necrolyte_corpse_charges_buff_permanent", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if buff ~= nil then
        if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end 

        buff:ForceRefresh()
    end
end