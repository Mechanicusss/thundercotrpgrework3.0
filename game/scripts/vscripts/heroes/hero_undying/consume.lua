LinkLuaModifier("modifier_undying_consume_custom", "heroes/hero_undying/consume", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_undying_consume_custom_buff_permanent", "heroes/hero_undying/consume", LUA_MODIFIER_MOTION_NONE)

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


undying_consume_custom = class(ItemBaseClass)
modifier_undying_consume_custom = class(undying_consume_custom)
modifier_undying_consume_custom_buff_permanent = class(ItemBaseClassBuff)
-------------
function modifier_undying_consume_custom_buff_permanent:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_undying_consume_custom_buff_permanent:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_STATS_STRENGTH_BONUS , --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_TOOLTIP
    }

    return funcs
end

function modifier_undying_consume_custom_buff_permanent:OnCreated()
    self.total = 0
end

function modifier_undying_consume_custom_buff_permanent:OnTooltip()
    return self.total
end

function modifier_undying_consume_custom_buff_permanent:OnRefresh()
    local gain = self:GetAbility():GetSpecialValueFor("str_gain")

    self.total = self.total + gain
    
    if not IsServer() then return end

    self:GetParent():ModifyStrength(gain)
end

function modifier_undying_consume_custom_buff_permanent:GetModifierConstantHealthRegen()
    if not self:GetCaster():HasModifier("modifier_item_aghanims_shard") then return 0 end

    return self:GetStackCount()
end
-------------
function undying_consume_custom:GetIntrinsicModifierName()
    return "modifier_undying_consume_custom"
end


function modifier_undying_consume_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH 
    }
    return funcs
end

function modifier_undying_consume_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_undying_consume_custom:OnDeath(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    local buff = unit:FindModifierByNameAndCaster("modifier_undying_consume_custom_buff_permanent", unit)
    local stacks = unit:GetModifierStackCount("modifier_undying_consume_custom_buff_permanent", unit)
    
    if not buff then
        buff = unit:AddNewModifier(unit, ability, "modifier_undying_consume_custom_buff_permanent", {})
    end

    if buff ~= nil then
        local preTotal = (buff:GetStackCount() * ability:GetSpecialValueFor("str_gain"))
        if preTotal >= 1000000 then return false end

        unit:SetModifierStackCount("modifier_undying_consume_custom_buff_permanent", unit, (stacks + 1))
        buff:ForceRefresh()
        ability:UseResources(false, false, false, true)
    end
end