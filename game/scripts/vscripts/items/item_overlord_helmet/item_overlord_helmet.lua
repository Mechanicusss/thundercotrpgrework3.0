LinkLuaModifier("modifier_item_overlord_helmet", "items/item_overlord_helmet/item_overlord_helmet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_overlord_helmet_aura", "items/item_overlord_helmet/item_overlord_helmet", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_overlord_helmet_aura_friendly", "items/item_overlord_helmet/item_overlord_helmet", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_overlord_helmet = class(ItemBaseClass)
item_overlord_helmet_2 = item_overlord_helmet
item_overlord_helmet_3 = item_overlord_helmet
item_overlord_helmet_4 = item_overlord_helmet
item_overlord_helmet_5 = item_overlord_helmet
item_overlord_helmet_6 = item_overlord_helmet
item_overlord_helmet_7 = item_overlord_helmet
modifier_item_overlord_helmet = class(item_overlord_helmet)
modifier_item_overlord_helmet_aura = class(ItemBaseClassAura)
modifier_item_overlord_helmet_aura_friendly = class(ItemBaseClassAura)
modifier_item_overlord_helmet_aura.units = {}
modifier_item_overlord_helmet.units = 0
-------------
function item_overlord_helmet:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function item_overlord_helmet:GetIntrinsicModifierName()
    return "modifier_item_overlord_helmet"
end
-------------
function modifier_item_overlord_helmet:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        
    }

    return funcs
end

function modifier_item_overlord_helmet:OnCreated()
    self.aura_modifier_name = "modifier_item_overlord_helmet_aura"
    self.allyAura = "modifier_item_overlord_helmet_aura_friendly"
    self.enemyAura = "modifier_item_overlord_helmet_aura"
end


function modifier_item_overlord_helmet:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_overlord_helmet:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_overlord_helmet:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_overlord_helmet:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_overlord_helmet:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end

function modifier_item_overlord_helmet:IsAura()
  return true
end

function modifier_item_overlord_helmet:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_item_overlord_helmet:GetAuraSearchTeam()
  return bit.bor(DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_TEAM_ENEMY)
end

function modifier_item_overlord_helmet:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_item_overlord_helmet:GetModifierAura()
    return self.aura_modifier_name
end

function modifier_item_overlord_helmet:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_item_overlord_helmet:GetAuraEntityReject(target)
    if target:GetTeamNumber() == self:GetCaster():GetTeamNumber() then
        self.aura_modifier_name = self.allyAura
    else
        self.aura_modifier_name = self.enemyAura
    end

    return false
end
-------------
function modifier_item_overlord_helmet_aura:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_item_overlord_helmet_aura:OnIntervalThink()
    self:OnRefresh()
end

function modifier_item_overlord_helmet_aura:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    if not ability then return end
    local parent = self:GetParent()
    local res = ability:GetSpecialValueFor("status_resistance")

    self.status = res

    if not GameRules:IsDaytime() then
        self.status = res * 2

        if self.units[self:GetParent():entindex()] ~= res * 2 then
            -- It is day but resistance is not default value, we remove the aura modifier so it gets re-applied
            -- This is necessary to make sure the ModifierFilter gets the updated value
            self:Destroy()
        end
    end

    if GameRules:IsDaytime() then
        if self.units[self:GetParent():entindex()] ~= res then
            -- It is day but resistance is not default value, we remove the aura modifier so it gets re-applied
            -- This is necessary to make sure the ModifierFilter gets the updated value
            self:Destroy()
        end
    end

    self.units[self:GetParent():entindex()] = self.status

    self:InvokeBonus()
end

function modifier_item_overlord_helmet_aura:OnDestroy()
    if not IsServer() then return end

    self.units[self:GetParent():entindex()] = nil
end

function modifier_item_overlord_helmet_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    }

    return funcs
end

function modifier_item_overlord_helmet_aura:GetModifierStatusResistanceStacking()
    return self.fStatus
end

function modifier_item_overlord_helmet_aura:AddCustomTransmitterData()
    return
    {
        status = self.fStatus,
    }
end

function modifier_item_overlord_helmet_aura:HandleCustomTransmitterData(data)
    if data.status ~= nil then
        self.fStatus = tonumber(data.status)
    end
end

function modifier_item_overlord_helmet_aura:InvokeBonus()
    if IsServer() == true then
        self.fStatus = self.status

        self:SendBuffRefreshToClients()
    end
end
---------------------------------
function modifier_item_overlord_helmet_aura_friendly:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }

    return funcs
end

function modifier_item_overlord_helmet_aura_friendly:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_item_overlord_helmet_aura_friendly:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    if not IsServer() then return end

    modifier_item_overlord_helmet.units =  modifier_item_overlord_helmet.units + 1

    self:StartIntervalThink(0.1)
end

function modifier_item_overlord_helmet_aura_friendly:OnIntervalThink()
    self:OnRefresh()
end

function modifier_item_overlord_helmet_aura_friendly:OnRefresh()
    if not IsServer() then return end

    local share = self:GetAbility():GetSpecialValueFor("damage_share_pct")
    local damage = share

    if not GameRules:IsDaytime() then
        damage = share * 2
    end

    local baseDamage = self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())
    self.damage = ((baseDamage * (damage/100))/modifier_item_overlord_helmet.units)

    self:InvokeBonus()
end

function modifier_item_overlord_helmet_aura_friendly:OnDestroy()
    if not IsServer() then return end

    modifier_item_overlord_helmet.units = modifier_item_overlord_helmet.units - 1
end

function modifier_item_overlord_helmet_aura_friendly:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_item_overlord_helmet_aura_friendly:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_item_overlord_helmet_aura_friendly:InvokeBonus()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end