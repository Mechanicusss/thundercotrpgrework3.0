LinkLuaModifier("modifier_talent_tidehunter_2", "heroes/hero_tidehunter/talents/talent_tidehunter_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_tidehunter_2_shield", "heroes/hero_tidehunter/talents/talent_tidehunter_2", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
}

talent_tidehunter_2 = class(ItemBaseClass)
modifier_talent_tidehunter_2 = class(talent_tidehunter_2)
modifier_talent_tidehunter_2_shield = class(ItemBaseClassBuff)
-------------
function talent_tidehunter_2:GetIntrinsicModifierName()
    return "modifier_talent_tidehunter_2"
end
-------------
function modifier_talent_tidehunter_2:OnCreated()
    if not IsServer() then return end 

    local interval = 12

    self:StartIntervalThink(interval)
end

function modifier_talent_tidehunter_2:OnDestroy()
end

function modifier_talent_tidehunter_2:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local kraken = parent:FindAbilityByName("tidehunter_kraken_shell_custom")
    if not kraken or (kraken ~= nil and kraken:GetLevel() < 1) then return end

    local mod = parent:FindModifierByName("modifier_talent_tidehunter_2_shield")
    if not mod then
        mod = parent:AddNewModifier(parent, ability, "modifier_talent_tidehunter_2_shield", {})
    end

    if mod then
        mod:ForceRefresh()
    end
end
------------------------
function modifier_talent_tidehunter_2_shield:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    if not IsServer() then return end 

    self:StartIntervalThink(FrameTime())
end

function modifier_talent_tidehunter_2_shield:OnIntervalThink()
    local parent = self:GetParent()

    local kraken = parent:FindAbilityByName("tidehunter_kraken_shell_custom")
    if not kraken or (kraken ~= nil and kraken:GetLevel() < 1) then return end

    local talent = parent:FindAbilityByName("talent_tidehunter_2")

    if not talent or (talent ~= nil and talent:GetLevel() < 2) then
        self:StartIntervalThink(-1)
        self:Destroy()
    end
end

function modifier_talent_tidehunter_2_shield:OnRefresh()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if ability:GetLevel() < 2 then
        self.shieldAmount = 0
    else
        self.shieldAmount = parent:GetMaxHealth() * (ability:GetSpecialValueFor("shield_hp_pct")/100)
    end

    self:InvokeShield()
end

function modifier_talent_tidehunter_2_shield:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT, 
    }

    return funcs
end

function modifier_talent_tidehunter_2_shield:GetModifierIncomingPhysicalDamageConstant(event)
    if not IsServer() then
        return self.fShieldAmount
    end

    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end
    if self.shieldAmount <= 0 then return end

    local block = 0
    local negated = self.shieldAmount - event.damage 

    if negated <= 0 then
        block = self.shieldAmount
    else
        block = event.damage
    end

    self.shieldAmount = negated

    if self.shieldAmount <= 0 then
        self.shieldAmount = 0
    else
        self.shieldAmount = self.shieldAmount
    end

    self:InvokeShield()

    return -block
end

function modifier_talent_tidehunter_2_shield:AddCustomTransmitterData()
    return
    {
        shieldAmount = self.fShieldAmount,
    }
end

function modifier_talent_tidehunter_2_shield:HandleCustomTransmitterData(data)
    if data.shieldAmount ~= nil then
        self.fShieldAmount = tonumber(data.shieldAmount)
    end
end

function modifier_talent_tidehunter_2_shield:InvokeShield()
    if IsServer() == true then
        self.fShieldAmount = self.shieldAmount

        self:SendBuffRefreshToClients()
    end
end