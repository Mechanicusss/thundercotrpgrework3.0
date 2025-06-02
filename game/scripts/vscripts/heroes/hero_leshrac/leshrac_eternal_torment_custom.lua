LinkLuaModifier("modifier_leshrac_eternal_torment_custom", "heroes/hero_leshrac/leshrac_eternal_torment_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_leshrac_eternal_torment_custom_buff_permanent", "heroes/hero_leshrac/leshrac_eternal_torment_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_leshrac_eternal_torment_custom_debuff", "heroes/hero_leshrac/leshrac_eternal_torment_custom.lua", LUA_MODIFIER_MOTION_NONE)

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
local ItemBaseClassDeBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

leshrac_eternal_torment_custom = class(ItemBaseClass)
modifier_leshrac_eternal_torment_custom = class(leshrac_eternal_torment_custom)
modifier_leshrac_eternal_torment_custom_buff_permanent = class(ItemBaseClassBuff)
modifier_leshrac_eternal_torment_custom_debuff = class(ItemBaseClassDeBuff)
-------------
function modifier_leshrac_eternal_torment_custom_buff_permanent:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_leshrac_eternal_torment_custom_buff_permanent:DeclareFunctions()
    local funcs = {
        --MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_TOOLTIP 
    }

    return funcs
end

function modifier_leshrac_eternal_torment_custom_buff_permanent:OnCreated()
    self.total = 0
end

function modifier_leshrac_eternal_torment_custom_buff_permanent:OnTooltip()
    return self.total
end

function modifier_leshrac_eternal_torment_custom_buff_permanent:OnRefresh()
    local gain = self:GetAbility():GetSpecialValueFor("int_gain")

    local minutesPassedSinceGameStart = math.floor(GameRules:GetGameTime() / 60)
    if minutesPassedSinceGameStart >= self:GetAbility():GetSpecialValueFor("times_ten_time_limit_minutes") then
        gain = gain * 2
    end

    self.total = self.total + gain
    
    if not IsServer() then return end

    self:GetParent():ModifyIntellect(gain)
end
-------------
function leshrac_eternal_torment_custom:GetIntrinsicModifierName()
    return "modifier_leshrac_eternal_torment_custom"
end

function modifier_leshrac_eternal_torment_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
    return funcs
end

function modifier_leshrac_eternal_torment_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local victim = event.unit

    if unit ~= parent or unit == victim then
        return
    end

    if unit:IsIllusion() then return end

    if (event.damage_type ~= DAMAGE_TYPE_MAGICAL and event.damage_type ~= DAMAGE_TYPE_PURE) or event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end
    
    local debuff = victim:AddNewModifier(unit, ability, "modifier_leshrac_eternal_torment_custom_debuff", {
        duration = ability:GetSpecialValueFor("duration")
    })

    if debuff ~= nil then
        debuff:ForceRefresh()
    end
end

function modifier_leshrac_eternal_torment_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_leshrac_eternal_torment_custom:OnDeath(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    local ability = self:GetAbility()

    local buff = unit:FindModifierByNameAndCaster("modifier_leshrac_eternal_torment_custom_buff_permanent", unit)
    local stacks = unit:GetModifierStackCount("modifier_leshrac_eternal_torment_custom_buff_permanent", unit)
    
    if not buff then
        buff = unit:AddNewModifier(unit, ability, "modifier_leshrac_eternal_torment_custom_buff_permanent", {})
    end

    unit:SetModifierStackCount("modifier_leshrac_eternal_torment_custom_buff_permanent", unit, (stacks + 1))
    buff:ForceRefresh()
end

function modifier_leshrac_eternal_torment_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS , --GetModifierMagicalResistanceBonus
    }
    return funcs
end

function modifier_leshrac_eternal_torment_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_reduction")
end