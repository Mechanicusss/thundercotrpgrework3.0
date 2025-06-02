LinkLuaModifier("modifier_talent_muerta_1", "heroes/hero_muerta/talents/talent_muerta_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_muerta_1_buff", "heroes/hero_muerta/talents/talent_muerta_1", LUA_MODIFIER_MOTION_NONE)

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

talent_muerta_1 = class(ItemBaseClass)
modifier_talent_muerta_1 = class(talent_muerta_1)
modifier_talent_muerta_1_buff = class(ItemBaseClassBuff)
-------------
function talent_muerta_1:GetIntrinsicModifierName()
    return "modifier_talent_muerta_1"
end
-------------
function modifier_talent_muerta_1:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ABILITY_START,
        MODIFIER_EVENT_ON_ABILITY_END_CHANNEL
    }

    return funcs
end

function modifier_talent_muerta_1:OnCreated()
    if not IsServer() then return end

    self.bonusDamageDuration = 0
end

function modifier_talent_muerta_1:OnIntervalThink()
    self.bonusDamageDuration = self.bonusDamageDuration + 1
end

function modifier_talent_muerta_1:OnAbilityStart(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end
    if event.ability:GetAbilityName() ~= "muerta_dead_shot_custom" then return end

    self.bonusDamageDuration = 0

    self:StartIntervalThink(1)
end

function modifier_talent_muerta_1:OnAbilityEndChannel(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end
    if event.ability:GetAbilityName() ~= "muerta_dead_shot_custom" then return end

    if parent:HasModifier("modifier_talent_muerta_1_buff") then
        parent:RemoveModifierByName("modifier_talent_muerta_1_buff")
    end
    
    parent:AddNewModifier(parent, self:GetAbility(), "modifier_talent_muerta_1_buff", {
        duration = self:GetAbility():GetSpecialValueFor("bonus_damage_duration"),
        damage = self.bonusDamageDuration * self:GetAbility():GetSpecialValueFor("bonus_damage_pct_per_sec")
    })

    self.bonusDamageDuration = 0

    self:StartIntervalThink(-1)
end

function modifier_talent_muerta_1:GetModifierTotalDamageOutgoing_Percentage(event)
    local parent = self:GetParent()

    if parent:HasModifier("modifier_muerta_dead_shot_custom_channeling") then
        if (event.inflictor ~= nil and event.inflictor:GetAbilityName() == "muerta_dead_shot_custom") or (event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK) then
            return self:GetAbility():GetSpecialValueFor("damage_bonus_pct")
        end
    end
end
--------------
function modifier_talent_muerta_1_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_talent_muerta_1_buff:GetModifierDamageOutgoing_Percentage()
    return self.fDamage
end

function modifier_talent_muerta_1_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.damage = params.damage

    self:InvokeBonus()
end

function modifier_talent_muerta_1_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_talent_muerta_1_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_talent_muerta_1_buff:InvokeBonus()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end