LinkLuaModifier("modifier_creature_necrolyte_aura", "creeps/creature_necrolyte_aura/creature_necrolyte_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_creature_necrolyte_aura_enemy", "creeps/creature_necrolyte_aura/creature_necrolyte_aura", LUA_MODIFIER_MOTION_NONE)

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

creature_necrolyte_aura = class(ItemBaseClass)
modifier_creature_necrolyte_aura = class(creature_necrolyte_aura)
modifier_creature_necrolyte_aura_enemy = class(ItemBaseClassAura)
-------------
function creature_necrolyte_aura:GetIntrinsicModifierName()
    return "modifier_creature_necrolyte_aura"
end

function creature_necrolyte_aura:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function modifier_creature_necrolyte_aura:OnCreated()
    if not IsServer() then return end
end

function modifier_creature_necrolyte_aura:IsAura()
  return true
end

function modifier_creature_necrolyte_aura:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_creature_necrolyte_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_creature_necrolyte_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_creature_necrolyte_aura:GetModifierAura()
    return "modifier_creature_necrolyte_aura_enemy"
end

function modifier_creature_necrolyte_aura:GetAuraEntityReject(target)
    if not self:GetAbility():IsActivated() then return true end

    return not self:GetParent():CanEntityBeSeenByMyTeam(target)
end
------------
function modifier_creature_necrolyte_aura_enemy:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self.shred = 0

    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()

    self.damageTable = {
        victim = parent,
        attacker = caster,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
    }

    self.interval = 0.25

    self:StartIntervalThink(self.interval)

    self:OnRefresh()
end

function modifier_creature_necrolyte_aura_enemy:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    if not caster:IsAlive() or not parent:IsAlive() then return end
    if ability == nil then return end

    local distance = (caster:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
    local falloff = ability:GetSpecialValueFor("min_radius") / distance

    -- Deals full damage if they're X radius or closer to Necrophos
    if falloff > 1 or (distance <= ability:GetSpecialValueFor("min_radius")) then
        falloff = 1
    end

    local hpDmg = ability:GetSpecialValueFor("max_hp_damage")
    
    local damage = (parent:GetHealth() * (hpDmg/100)) * falloff 

    self.damageTable.damage = damage * self.interval

    ApplyDamage(self.damageTable)

    self:OnRefresh()
end

function modifier_creature_necrolyte_aura_enemy:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    local distance = (caster:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
    local falloff = ability:GetSpecialValueFor("min_radius") / distance

    if falloff > 1 or (distance <= ability:GetSpecialValueFor("min_radius")) then
        falloff = 1
    end

    self.shred = self:GetAbility():GetSpecialValueFor("magic_shred") * falloff
    self.degen = self:GetAbility():GetSpecialValueFor("degen_pct") * falloff

    self:InvokeBonusShred()
end

function modifier_creature_necrolyte_aura_enemy:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }

    return funcs
end

function modifier_creature_necrolyte_aura_enemy:GetModifierHealAmplify_PercentageTarget()
    return self.fDegen
end

function modifier_creature_necrolyte_aura_enemy:GetModifierHPRegenAmplify_Percentage()
    return self.fDegen
end

function modifier_creature_necrolyte_aura_enemy:GetModifierLifestealRegenAmplify_Percentage()
    return self.fDegen
end

function modifier_creature_necrolyte_aura_enemy:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self.fDegen
end

function modifier_creature_necrolyte_aura_enemy:GetModifierMagicalResistanceBonus()
    return self.fShred
end

function modifier_creature_necrolyte_aura_enemy:AddCustomTransmitterData()
    return
    {
        shred = self.fShred,
        degen = self.fDegen
    }
end

function modifier_creature_necrolyte_aura_enemy:HandleCustomTransmitterData(data)
    if data.shred ~= nil and data.degen ~= nil then
        self.fShred = tonumber(data.shred)
        self.fDegen = tonumber(data.degen)
    end
end

function modifier_creature_necrolyte_aura_enemy:InvokeBonusShred()
    if IsServer() == true then
        self.fShred = self.shred
        self.fDegen = self.degen

        self:SendBuffRefreshToClients()
    end
end