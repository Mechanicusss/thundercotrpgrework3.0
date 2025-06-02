LinkLuaModifier("modifier_stargazer_celestial_selection", "heroes/hero_stargazer/celestial_selection.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stargazer_celestial_selection_buff_permanent_str", "heroes/hero_stargazer/celestial_selection.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stargazer_celestial_selection_buff_permanent_agi", "heroes/hero_stargazer/celestial_selection.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stargazer_celestial_selection_buff_permanent_int", "heroes/hero_stargazer/celestial_selection.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stargazer_celestial_selection_buff_cycle", "heroes/hero_stargazer/celestial_selection.lua", LUA_MODIFIER_MOTION_NONE)

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

stargazer_celestial_selection = class(ItemBaseClass)
modifier_stargazer_celestial_selection = class(stargazer_celestial_selection)
modifier_stargazer_celestial_selection_buff_permanent_str = class(ItemBaseClassBuff)
modifier_stargazer_celestial_selection_buff_permanent_agi = class(ItemBaseClassBuff)
modifier_stargazer_celestial_selection_buff_permanent_int = class(ItemBaseClassBuff)
modifier_stargazer_celestial_selection_buff_cycle = class(ItemBaseClassBuff)
-------------
function modifier_stargazer_celestial_selection_buff_permanent_str:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_stargazer_celestial_selection_buff_permanent_str:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS 
    }

    return funcs
end

function modifier_stargazer_celestial_selection_buff_permanent_str:GetModifierBonusStats_Strength()
    return self:GetStackCount()
end

function modifier_stargazer_celestial_selection_buff_permanent_str:OnTooltip()
    return self:GetStackCount()
end

function modifier_stargazer_celestial_selection_buff_permanent_str:OnRefresh()
    if not IsServer() then return end
end

function modifier_stargazer_celestial_selection_buff_permanent_int:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_stargazer_celestial_selection_buff_permanent_int:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    }

    return funcs
end

function modifier_stargazer_celestial_selection_buff_permanent_int:GetModifierBonusStats_Intellect()
    return self:GetStackCount()
end

function modifier_stargazer_celestial_selection_buff_permanent_int:OnTooltip()
    return self:GetStackCount()
end

function modifier_stargazer_celestial_selection_buff_permanent_int:OnRefresh()
    if not IsServer() then return end
end

function modifier_stargazer_celestial_selection_buff_permanent_agi:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_stargazer_celestial_selection_buff_permanent_agi:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS
    }

    return funcs
end

function modifier_stargazer_celestial_selection_buff_permanent_agi:GetModifierBonusStats_Agility()
    return self:GetStackCount()
end

function modifier_stargazer_celestial_selection_buff_permanent_agi:OnTooltip()
    return self:GetStackCount()
end

function modifier_stargazer_celestial_selection_buff_permanent_agi:OnRefresh()
    if not IsServer() then return end
end
-------------
function stargazer_celestial_selection:GetIntrinsicModifierName()
    return "modifier_stargazer_celestial_selection"
end


function modifier_stargazer_celestial_selection:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH 
    }
    return funcs
end

function modifier_stargazer_celestial_selection:OnCreated()
    self.parent = self:GetParent()

    self.cycle = 1
end

function modifier_stargazer_celestial_selection:OnDeath(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    if unit:IsTempestDouble() then return end
    if unit:IsIllusion() then return end

    local ability = self:GetAbility()
    if not ability:IsCooldownReady() then return end

    ability:UseResources(false, false, false, true)

    local cycle = unit:FindModifierByNameAndCaster("modifier_stargazer_celestial_selection_buff_cycle", unit)

    --
    local buffStr = unit:FindModifierByNameAndCaster("modifier_stargazer_celestial_selection_buff_permanent_str", unit)
    local stacksStr = unit:GetModifierStackCount("modifier_stargazer_celestial_selection_buff_permanent_str", unit)

    if not buffStr then
        buffStr = unit:AddNewModifier(unit, ability, "modifier_stargazer_celestial_selection_buff_permanent_str", {})
        buffStr:SetStackCount(0)
    end

    if buffStr ~= nil then
        local preTotal = unit:GetStrength() + (buffStr:GetStackCount() * ability:GetSpecialValueFor("str_gain"))
        if preTotal >= 1000000 or unit:GetStrength() >= 1000000 then return false end
    end
    --
    local buffAgi = unit:FindModifierByNameAndCaster("modifier_stargazer_celestial_selection_buff_permanent_agi", unit)
    local stacksAgi = unit:GetModifierStackCount("modifier_stargazer_celestial_selection_buff_permanent_agi", unit)

    if not buffAgi then
        buffAgi = unit:AddNewModifier(unit, ability, "modifier_stargazer_celestial_selection_buff_permanent_agi", {})
        buffAgi:SetStackCount(0)
    end

    if buffAgi ~= nil then
        local preTotal = unit:GetAgility() + (buffAgi:GetStackCount() * ability:GetSpecialValueFor("agi_gain"))
        if preTotal >= 1000000 or unit:GetAgility() >= 1000000 then return false end
    end
    --
    local buffInt = unit:FindModifierByNameAndCaster("modifier_stargazer_celestial_selection_buff_permanent_int", unit)
    local stacksInt = unit:GetModifierStackCount("modifier_stargazer_celestial_selection_buff_permanent_int", unit)

    if not buffInt then
        buffInt = unit:AddNewModifier(unit, ability, "modifier_stargazer_celestial_selection_buff_permanent_int", {})
        buffInt:SetStackCount(0)
    end

    if buffInt ~= nil then
        local preTotal = unit:GetBaseIntellect() + (buffInt:GetStackCount() * ability:GetSpecialValueFor("int_gain"))
        if preTotal >= 1000000 or unit:GetBaseIntellect() >= 1000000 then return false end
    end
    --

    if not cycle then 
        cycle = unit:AddNewModifier(unit, ability, "modifier_stargazer_celestial_selection_buff_cycle", {})
        cycle:SetStackCount(1)
    end

    local attr = ""

    function IncreaseStr(advanceCycle)
        attr = "str_gain"
        unit:SetModifierStackCount("modifier_stargazer_celestial_selection_buff_permanent_str", unit, (stacksStr + ability:GetSpecialValueFor(attr)))
        buffStr:ForceRefresh()
        if advanceCycle then
            self.cycle = 2
            cycle:SetStackCount(2)
        end
    end

    function IncreaseAgi(advanceCycle)
        attr = "agi_gain"
        unit:SetModifierStackCount("modifier_stargazer_celestial_selection_buff_permanent_agi", unit, (stacksAgi + ability:GetSpecialValueFor(attr)))
        buffAgi:ForceRefresh()
        if advanceCycle then
            self.cycle = 3
            cycle:SetStackCount(3)
        end
    end

    function IncreaseInt(advanceCycle)
        attr = "int_gain"
        unit:SetModifierStackCount("modifier_stargazer_celestial_selection_buff_permanent_int", unit, (stacksInt + ability:GetSpecialValueFor(attr)))
        buffInt:ForceRefresh()
        if advanceCycle then
            self.cycle = 1
            cycle:SetStackCount(1)
        end
    end

    if unit:HasScepter() and RollPercentage(ability:GetSpecialValueFor("chance")) then
        IncreaseStr(false)
        IncreaseAgi(false)
        IncreaseInt(false)
        local nextCycle = self.cycle + 1
        if nextCycle > 3 then
            self.cycle = 1
            cycle:SetStackCount(1)
        else
            self.cycle = nextCycle
            cycle:SetStackCount(nextCycle)
        end

        return
    end

    if self.cycle == 1 then
        IncreaseStr(true)
        return
    elseif self.cycle == 2 then
        IncreaseAgi(true)
        return
    elseif self.cycle == 3 then
        IncreaseInt(true)
        return
    end
end