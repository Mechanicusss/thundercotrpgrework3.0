LinkLuaModifier("modifier_item_ancient_garthos_greatsword", "items/item_ancient_garthos_greatsword/item_ancient_garthos_greatsword.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_garthos_greatsword_stacks", "items/item_ancient_garthos_greatsword/item_ancient_garthos_greatsword.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_ancient_garthos_greatsword = class(ItemBaseClass)
item_ancient_garthos_greatsword_2 = item_ancient_garthos_greatsword
item_ancient_garthos_greatsword_3 = item_ancient_garthos_greatsword
item_ancient_garthos_greatsword_4 = item_ancient_garthos_greatsword
item_ancient_garthos_greatsword_5 = item_ancient_garthos_greatsword
modifier_item_ancient_garthos_greatsword = class(ItemBaseClass)
modifier_item_ancient_garthos_greatsword_stacks = class(ItemBaseClassBuff)
-------------
function item_ancient_garthos_greatsword:GetIntrinsicModifierName()
    return "modifier_item_ancient_garthos_greatsword"
end
-------------
function modifier_item_ancient_garthos_greatsword:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
    }
end

function modifier_item_ancient_garthos_greatsword:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
            
            EmitSoundOn("DOTA_Item.Daedelus.Crit", params.target)
        end
    end
end

function modifier_item_ancient_garthos_greatsword:GetModifierPreAttack_CriticalStrike(keys)
    if not IsServer() then return end 
    
    local ability = self:GetAbility()
    local unit = self:GetParent()

    local crit = ability:GetSpecialValueFor("crit_chance")

    if RollPercentage(crit) then
        self.record = keys.record

        local critDmg = ability:GetSpecialValueFor("crit_multiplier") + (unit:GetStrength() * ability:GetSpecialValueFor("bonus_crit_per_str"))

        return critDmg
    end
end

function modifier_item_ancient_garthos_greatsword:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_ancient_garthos_greatsword:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_ancient_garthos_greatsword:GetModifierPreAttack_BonusDamage()
    local damage = self:GetAbility():GetSpecialValueFor("bonus_damage")

    if self:GetAbility():GetLevel() == 5 then
        return damage + (self:GetAbility():GetSpecialValueFor("str_damage_multiplier") * self:GetParent():GetStrength())
    end

    return damage
end

function modifier_item_ancient_garthos_greatsword:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_health_regen_pct")
end

function modifier_item_ancient_garthos_greatsword:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if parent ~= event.unit then return end
    if not IsCreepTCOTRPG(event.attacker) and not IsBossTCOTRPG(event.attacker) then return end

    local maxStacks = ability:GetSpecialValueFor("max_stacks")
    local duration = ability:GetSpecialValueFor("duration")

    local buff = parent:FindModifierByName("modifier_item_ancient_garthos_greatsword_stacks")
    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_item_ancient_garthos_greatsword_stacks", { duration = duration })
    end

    if buff then
        if buff:GetStackCount() < maxStacks then
            buff:IncrementStackCount()
        end
        
        buff:ForceRefresh()
    end
end

function modifier_item_ancient_garthos_greatsword:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("bonus_base_damage_reduction")

    self:StartIntervalThink(0.1)
end

function modifier_item_ancient_garthos_greatsword:OnIntervalThink()
    local abilityName = self:GetName()
    
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("bonus_base_damage_reduction")
end

function modifier_item_ancient_garthos_greatsword:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end
-------------------
function modifier_item_ancient_garthos_greatsword_stacks:OnCreated(props)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("bonus_damage_reduction") * self:GetStackCount()

    self:StartIntervalThink(0.1)
end

function modifier_item_ancient_garthos_greatsword_stacks:OnIntervalThink()
    local abilityName = self:GetName()
    
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("bonus_damage_reduction") * self:GetStackCount()
end

function modifier_item_ancient_garthos_greatsword_stacks:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end