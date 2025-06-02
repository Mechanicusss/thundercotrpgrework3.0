LinkLuaModifier("modifier_chicken_ability_7", "heroes/chicken/chicken_ability_7.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chicken_ability_7_buff", "heroes/chicken/chicken_ability_7.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

chicken_ability_7 = class(ItemBaseClass)
modifier_chicken_ability_7 = class(chicken_ability_7)

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_chicken_ability_7_buff = class(ItemBaseClassBuff)
-------------
function chicken_ability_7:GetIntrinsicModifierName()
    return "modifier_chicken_ability_7"
end
-------------
function modifier_chicken_ability_7:OnCreated()
    if not IsServer() then return end

    self.target = nil

    self:StartIntervalThink(0.1)
end

function modifier_chicken_ability_7:OnIntervalThink()
    local caster = self:GetCaster()

    local mod = caster:FindModifierByName("modifier_chicken_ability_1_self_transmute")
    if mod == nil then 
        if self.target ~= nil then
            self.target:RemoveModifierByName("modifier_chicken_ability_7_buff")
        end

        return 
    end

    local target = mod:GetCaster()
    if not target or target == nil then return end
    if not target:IsAlive() then return end

    self.target = target

    if not self.target:HasModifier("modifier_chicken_ability_7_buff") then
        self.target:AddNewModifier(caster, self:GetAbility(), "modifier_chicken_ability_7_buff", {})
    end
end
------------
function modifier_chicken_ability_7_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_chicken_ability_7_buff:OnRefresh()
    if not IsServer() then return end

    local caster = self:GetCaster()

    self.fStr = caster:GetStrength() * (self:GetAbility():GetSpecialValueFor("stats_share_pct")/100)
    self.fAgi = caster:GetAgility() * (self:GetAbility():GetSpecialValueFor("stats_share_pct")/100)
    self.fInt = caster:GetIntellect() * (self:GetAbility():GetSpecialValueFor("stats_share_pct")/100)

    self:InvokeBonus()
end

function modifier_chicken_ability_7_buff:OnIntervalThink()
    self:OnRefresh()
end

function modifier_chicken_ability_7_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, 
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS 
    }
end

function modifier_chicken_ability_7_buff:GetModifierBonusStats_Agility()
    return self.fAgi
end

function modifier_chicken_ability_7_buff:GetModifierBonusStats_Strength()
    return self.fStr
end

function modifier_chicken_ability_7_buff:GetModifierBonusStats_Intellect()
    return self.fInt
end

function modifier_chicken_ability_7_buff:AddCustomTransmitterData()
    return
    {
        agi = self.fAgi,
        str = self.fStr,
        int = self.fInt,
    }
end

function modifier_chicken_ability_7_buff:HandleCustomTransmitterData(data)
    if data.agi ~= nil and data.str ~= nil and data.int ~= nil then
        self.fAgi = tonumber(data.agi)
        self.fStr = tonumber(data.str)
        self.fInt = tonumber(data.int)
    end
end

function modifier_chicken_ability_7_buff:InvokeBonus()
    if IsServer() == true then
        self.fAgi = self.agi
        self.fStr = self.str
        self.fInt = self.int

        self:SendBuffRefreshToClients()
    end
end