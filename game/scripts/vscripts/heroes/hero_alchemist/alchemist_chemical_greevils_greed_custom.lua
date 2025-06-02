LinkLuaModifier("modifier_alchemist_chemical_greevils_greed_custom", "heroes/hero_alchemist/alchemist_chemical_greevils_greed_custom", LUA_MODIFIER_MOTION_NONE)

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

alchemist_chemical_greevils_greed_custom = class(ItemBaseClass)
modifier_alchemist_chemical_greevils_greed_custom = class(alchemist_chemical_greevils_greed_custom)
-------------
function alchemist_chemical_greevils_greed_custom:GetIntrinsicModifierName()
    return "modifier_alchemist_chemical_greevils_greed_custom"
end

function modifier_alchemist_chemical_greevils_greed_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
    }
    return funcs
end

function modifier_alchemist_chemical_greevils_greed_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self:OnRefresh()

    self:StartIntervalThink(1)
end

function modifier_alchemist_chemical_greevils_greed_custom:OnRefresh()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local accountID = PlayerResource:GetSteamAccountID(caster:GetPlayerID())

    local goldBank = _G.PlayerGoldBank[accountID]
    local goldStash = caster:GetGold()
    local goldTotal = goldBank + goldStash

    self:InvokeBonusDamage()

    self.damage = goldTotal * (self:GetAbility():GetSpecialValueFor("gold_to_damage")/100)
end

function modifier_alchemist_chemical_greevils_greed_custom:OnIntervalThink()
    self:OnRefresh()
end

function modifier_alchemist_chemical_greevils_greed_custom:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage
    }
end

function modifier_alchemist_chemical_greevils_greed_custom:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_alchemist_chemical_greevils_greed_custom:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_alchemist_chemical_greevils_greed_custom:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end
