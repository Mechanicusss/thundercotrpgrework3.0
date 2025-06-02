LinkLuaModifier("modifier_necrolyte_death_aura", "heroes/hero_necrolyte/necrolyte_death_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_death_aura_enemy", "heroes/hero_necrolyte/necrolyte_death_aura", LUA_MODIFIER_MOTION_NONE)

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

necrolyte_death_aura = class(ItemBaseClass)
modifier_necrolyte_death_aura = class(necrolyte_death_aura)
modifier_necrolyte_death_aura_enemy = class(ItemBaseClassAura)
-------------
function necrolyte_death_aura:GetIntrinsicModifierName()
    return "modifier_necrolyte_death_aura"
end

function necrolyte_death_aura:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function modifier_necrolyte_death_aura:OnCreated()
    if not IsServer() then return end
end

function modifier_necrolyte_death_aura:IsAura()
  return true
end

function modifier_necrolyte_death_aura:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_necrolyte_death_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_necrolyte_death_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_necrolyte_death_aura:GetModifierAura()
    return "modifier_necrolyte_death_aura_enemy"
end

function modifier_necrolyte_death_aura:GetAuraEntityReject(target)
    if not self:GetAbility():IsActivated() then return true end

    return not self:GetParent():CanEntityBeSeenByMyTeam(target)
end
------------
function modifier_necrolyte_death_aura_enemy:OnCreated()
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

function modifier_necrolyte_death_aura_enemy:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    if not caster:IsAlive() or not parent:IsAlive() then return end
    if parent:GetLevel() > caster:GetLevel() or IsBossTCOTRPG(parent) then return end
    if ability == nil then return end

    local minRadius = ability:GetSpecialValueFor("min_radius")

    local distance = (caster:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
    local falloff = minRadius / distance

    -- Deals full damage if they're X radius or closer to Necrophos
    if falloff > 1 or (distance <= minRadius) then
        falloff = 1
    end

    local hpDmg = ability:GetSpecialValueFor("max_hp_damage")

    if caster:HasTalent("special_bonus_unique_necrolyte_4_custom") then
        hpDmg = hpDmg + caster:FindAbilityByName("special_bonus_unique_necrolyte_4_custom"):GetSpecialValueFor("value")
    end
    
    local damage = (parent:GetMaxHealth() * (hpDmg/100)) * falloff 
    
    if caster:HasScepter() then
        damage = damage + (caster:GetHealthRegen()*(ability:GetSpecialValueFor("damage_from_regen_pct")/100))
    end

    self.damageTable.damage = damage * self.interval

    ApplyDamage(self.damageTable)

    self:OnRefresh()
end

function modifier_necrolyte_death_aura_enemy:OnRefresh()
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

    self:InvokeBonusShred()
end

function modifier_necrolyte_death_aura_enemy:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function modifier_necrolyte_death_aura_enemy:GetModifierMagicalResistanceBonus()
    return self.fShred
end

function modifier_necrolyte_death_aura_enemy:AddCustomTransmitterData()
    return
    {
        shred = self.fShred,
    }
end

function modifier_necrolyte_death_aura_enemy:HandleCustomTransmitterData(data)
    if data.shred ~= nil then
        self.fShred = tonumber(data.shred)
    end
end

function modifier_necrolyte_death_aura_enemy:InvokeBonusShred()
    if IsServer() == true then
        self.fShred = self.shred

        self:SendBuffRefreshToClients()
    end
end