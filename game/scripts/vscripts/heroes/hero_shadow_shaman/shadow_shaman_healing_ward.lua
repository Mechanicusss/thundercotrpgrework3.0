LinkLuaModifier("modifier_shadow_shaman_healing_ward", "heroes/hero_shadow_shaman/shadow_shaman_healing_ward", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_shaman_healing_ward_thinker", "heroes/hero_shadow_shaman/shadow_shaman_healing_ward", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_shaman_healing_ward_aura", "heroes/hero_shadow_shaman/shadow_shaman_healing_ward", LUA_MODIFIER_MOTION_NONE)

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

shadow_shaman_healing_ward = class(ItemBaseClass)
modifier_shadow_shaman_healing_ward = class(shadow_shaman_healing_ward)
modifier_shadow_shaman_healing_ward_thinker = class(ItemBaseClass)
modifier_shadow_shaman_healing_ward_aura = class(ItemBaseClassAura)

-------------
function shadow_shaman_healing_ward:GetIntrinsicModifierName()
    return "modifier_shadow_shaman_healing_ward"
end

function modifier_shadow_shaman_healing_ward_thinker:RemoveOnDeath() return true end

function modifier_shadow_shaman_healing_ward_thinker:CheckState()
    local state = {
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_DISARMED] = true,
    }

    return state
end

function modifier_shadow_shaman_healing_ward_thinker:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local duration = self:GetAbility():GetSpecialValueFor("duration")
    local target = self:GetParent()

    local particle = ParticleManager:CreateParticle("particles/econ/items/juggernaut/jugg_fall20_immortal/jugg_fall20_immortal_healing_ward.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

    Timers:CreateTimer(duration, function()
      ParticleManager:DestroyParticle(particle, true)
      ParticleManager:ReleaseParticleIndex(particle)
    end)

    self:SetDuration(duration, true)

    self:OnRefresh()
end

function modifier_shadow_shaman_healing_ward_thinker:OnDestroy()
    if not IsServer() then return end

    if not self or self == nil then return end
    if not self:GetParent() or self:GetParent() == nil then return end
    if not self:GetParent():IsAlive() then return end

    self:GetParent():ForceKill(false)
end

function modifier_shadow_shaman_healing_ward_thinker:IsAura()
  return true
end

function modifier_shadow_shaman_healing_ward_thinker:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_shadow_shaman_healing_ward_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_shadow_shaman_healing_ward_thinker:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_shadow_shaman_healing_ward_thinker:GetModifierAura()
    return "modifier_shadow_shaman_healing_ward_aura"
end

function modifier_shadow_shaman_healing_ward_thinker:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_shadow_shaman_healing_ward_thinker:GetAuraEntityReject()
    return false
end

---
function modifier_shadow_shaman_healing_ward_aura:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.5)
end

function modifier_shadow_shaman_healing_ward_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_shadow_shaman_healing_ward_aura:GetModifierTotalDamageOutgoing_Percentage()
    if HasShard(self:GetCaster()) then
        return self:GetAbility():GetSpecialValueFor("bonus_outgoing")
    end
end

function modifier_shadow_shaman_healing_ward_aura:OnIntervalThink()
    local ability = self:GetAbility()
    local parent = self:GetParent()
    local regen = (parent:GetMaxHealth() * (ability:GetSpecialValueFor("max_hp_regen")/100))/2

    parent:Heal(regen, ability)
    
    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_HEAL,
        parent,
        regen,
        nil
    )
end
---
function shadow_shaman_healing_ward:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = caster:GetCursorPosition()

    local unit = CreateUnitByName(
        "npc_dota_shadow_shaman_healing_ward",
        point,
        true,
        caster,
        caster,
        caster:GetTeamNumber()
    )

    local hp = self:GetSpecialValueFor("health")
            
    unit:SetBaseMaxHealth(hp)
    unit:SetMaxHealth(hp)
    unit:SetHealth(hp)

    unit:SetControllableByPlayer(caster:GetPlayerID(), false)

    unit:AddNewModifier(unit, self, "modifier_shadow_shaman_healing_ward_thinker", {})

    if caster:IsAlive() then
        unit:MoveToNPC(caster)
    end

    EmitSoundOn("Hero_Juggernaut.HealingWard.Cast", caster)
end
-----------------
function modifier_shadow_shaman_healing_ward_thinker:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    }

    return funcs
end

function modifier_shadow_shaman_healing_ward_thinker:OnRefresh()
    if not IsServer() then return end

    local owner = self:GetParent():GetOwner()

    self.summonerStaff = nil
    self.armor = 0
    self.health = 0

    if owner:FindItemInInventory("item_summoning_staff") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff")
    elseif owner:FindItemInInventory("item_summoning_staff_2") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_2")
    elseif owner:FindItemInInventory("item_summoning_staff_3") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_3")
    elseif owner:FindItemInInventory("item_summoning_staff_4") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_4")
    elseif owner:FindItemInInventory("item_summoning_staff_5") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_5")
    elseif owner:FindItemInInventory("item_summoning_staff_6") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_6")
    elseif owner:FindItemInInventory("item_summoning_staff_7") ~= nil then
        self.summonerStaff = owner:FindItemInInventory("item_summoning_staff_7")
    end

    if self.summonerStaff == nil or self.summonerStaff:IsInBackpack() then return end

    self.armor = owner:GetAgility() * self.summonerStaff:GetSpecialValueFor("agi_armor")
    self.health = owner:GetStrength() * self.summonerStaff:GetSpecialValueFor("str_hp")

    --self:InvokeBonuses()
end

function modifier_shadow_shaman_healing_ward_thinker:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_shadow_shaman_healing_ward_thinker:GetModifierExtraHealthBonus()
    return self.fHealth
end

function modifier_shadow_shaman_healing_ward_thinker:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
        health = self.fHealth
    }
end

function modifier_shadow_shaman_healing_ward_thinker:HandleCustomTransmitterData(data)
    if data.armor ~= nil and data.health ~= nil then
        self.fArmor = tonumber(data.armor)
        self.fHealth = tonumber(data.health)
    end
end

function modifier_shadow_shaman_healing_ward_thinker:InvokeBonuses()
    if IsServer() == true then
        self.fArmor = self.armor
        self.fHealth = self.health

        self:SendBuffRefreshToClients()
    end
end