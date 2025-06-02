LinkLuaModifier("modifier_undying_flesh_golem_custom", "heroes/hero_undying/flesh_golem", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_undying_flesh_golem_custom_aura", "heroes/hero_undying/flesh_golem", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

undying_flesh_golem_custom = class(ItemBaseClass)
modifier_undying_flesh_golem_custom = class(undying_flesh_golem_custom)
modifier_undying_flesh_golem_custom_aura = class(ItemBaseClassAura)

-------------
function undying_flesh_golem_custom:GetIntrinsicModifierName()
    return "modifier_undying_flesh_golem_custom"
end

function undying_flesh_golem_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function modifier_undying_flesh_golem_custom:GetModifierModelChange()
    return "models/heroes/undying/undying_flesh_golem.vmdl"
end

function modifier_undying_flesh_golem_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local parent = self:GetParent()

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_undying/undying_fg_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, parent:GetAbsOrigin() )

    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("dmg_reduction_pct")

    self.str = 0

    self:StartIntervalThink(0.1)
end

function modifier_undying_flesh_golem_custom:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.str = parent:GetBaseStrength() * (ability:GetSpecialValueFor("str_pct")/100)
    self:InvokeStrength()
end

function modifier_undying_flesh_golem_custom:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_undying_flesh_golem_custom:AddCustomTransmitterData()
    return
    {
        str = self.fStr,
    }
end

function modifier_undying_flesh_golem_custom:HandleCustomTransmitterData(data)
    if data.str ~= nil then
        self.fStr = tonumber(data.str)
    end
end

function modifier_undying_flesh_golem_custom:InvokeStrength()
    if IsServer() == true then
        self.fStr = self.str

        self:SendBuffRefreshToClients()
    end
end

function modifier_undying_flesh_golem_custom:DeclareFunctions()
    local funcs = {
         MODIFIER_PROPERTY_STATS_STRENGTH_BONUS , --GetModifierBonusStats_Strength
         MODIFIER_PROPERTY_MODEL_CHANGE 
    }
    return funcs
end

function modifier_undying_flesh_golem_custom:GetModifierBonusStats_Strength()
    return self.fStr
end

function modifier_undying_flesh_golem_custom:IsAura()
  return true
end

function modifier_undying_flesh_golem_custom:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_undying_flesh_golem_custom:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_undying_flesh_golem_custom:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_undying_flesh_golem_custom:GetModifierAura()
    return "modifier_undying_flesh_golem_custom_aura"
end

function modifier_undying_flesh_golem_custom:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_undying_flesh_golem_custom:GetAuraEntityReject(target)
    return false
end
------
function modifier_undying_flesh_golem_custom_aura:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.slow = self:GetAbility():GetLevelSpecialValueFor("slow_pct", (self:GetAbility():GetLevel() - 1))
    end

    if not IsServer() then return end

    self.damageTable = {
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage = self:GetCaster():GetStrength() * (ability:GetSpecialValueFor("str_to_damage")/100) * 0.25,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability,
    }

    self:StartIntervalThink(0.25)
end

function modifier_undying_flesh_golem_custom_aura:OnIntervalThink()
    if not self:GetCaster():HasScepter() then return end

    ApplyDamage(self.damageTable)
end

function modifier_undying_flesh_golem_custom_aura:IsDebuff()
    return true
end

function modifier_undying_flesh_golem_custom_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_undying_flesh_golem_custom_aura:OnDeath(event)
    if not IsServer() then return end
    if event.unit ~= self:GetParent() then return end
    if event.attacker ~= self:GetCaster() then return end

    local heal = event.unit:GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("heal_per_kill_pct")/100)
    self:GetCaster():Heal(heal, self:GetAbility())
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetCaster(), heal, nil)
end

function modifier_undying_flesh_golem_custom_aura:GetModifierMoveSpeedBonus_Percentage()
    return self.slow or self:GetAbility():GetLevelSpecialValueFor("slow_pct", (self:GetAbility():GetLevel() - 1))
end