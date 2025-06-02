LinkLuaModifier("modifier_huskar_mayhem_custom", "huskar_mayhem_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

huskar_mayhem_custom = class(ItemBaseClass)
modifier_huskar_mayhem_custom = class(huskar_mayhem_custom)
-------------
function huskar_mayhem_custom:GetIntrinsicModifierName()
    return "modifier_huskar_mayhem_custom"
end

function huskar_mayhem_custom:OnUpgrade()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local maxHealthLimit = caster:GetMaxHealth() * (self:GetSpecialValueFor("max_hp_threshold") / 100)

    local accountID = PlayerResource:GetSteamAccountID(caster:GetPlayerID())
    local abilityName = self:GetAbilityName()

    caster:SetHealth(maxHealthLimit)

    _G.PlayerDamageReduction[accountID] = _G.PlayerDamageReduction[accountID] or {}
    _G.PlayerDamageReduction[accountID][abilityName] = _G.PlayerDamageReduction[accountID][abilityName] or {}

    _G.PlayerDamageReduction[accountID][abilityName] = self:GetSpecialValueFor("damage_reduction")
end

function modifier_huskar_mayhem_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_RESPAWN,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
    return funcs
end

function modifier_huskar_mayhem_custom:GetModifierPreAttack_BonusDamage()
    return ((self:GetAbility():GetCaster():GetMaxHealth()) - (self:GetAbility():GetCaster():GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("max_hp_threshold") / 100))) * self:GetAbility():GetSpecialValueFor("damage_per_missing_hp")
end

function modifier_huskar_mayhem_custom:OnRemoved()
    if not IsServer() then return end

    local abilityName = self:GetAbility():GetAbilityName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_huskar_mayhem_custom:OnRespawn(event)
    if not IsServer() then return end

    local hp = self.maxHealthLimit

    if not hp or hp == nil or hp <= 0 then 
        hp = self:GetParent():GetMaxHealth()
    end

    self.caster:SetHealth(hp)
end

function modifier_huskar_mayhem_custom:OnRefresh()
    if not IsServer() then return end
end

function modifier_huskar_mayhem_custom:OnCreated()
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    self.maxHealthLimit = self.caster:GetMaxHealth() * (self.ability:GetSpecialValueFor("max_hp_threshold") / 100)

    self.caster:SetHealth(self.maxHealthLimit)
end