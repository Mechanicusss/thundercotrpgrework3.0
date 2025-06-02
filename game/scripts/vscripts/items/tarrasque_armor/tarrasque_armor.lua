LinkLuaModifier("modifier_item_tarrasque_armor", "items/tarrasque_armor/tarrasque_armor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_tarrasque_armor_active", "items/tarrasque_armor/tarrasque_armor", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

item_tarrasque_armor = class(ItemBaseClass)
item_tarrasque_armor_2 = item_tarrasque_armor
item_tarrasque_armor_3 = item_tarrasque_armor
item_tarrasque_armor_4 = item_tarrasque_armor
item_tarrasque_armor_5 = item_tarrasque_armor
item_tarrasque_armor_6 = item_tarrasque_armor
item_tarrasque_armor_7 = item_tarrasque_armor
item_tarrasque_armor_8 = item_tarrasque_armor
modifier_item_tarrasque_armor = class(ItemBaseClass)
modifier_item_tarrasque_armor_active = class(ItemBaseClassActive)
-------------
function item_tarrasque_armor:GetIntrinsicModifierName()
    return "modifier_item_tarrasque_armor"
end

function item_tarrasque_armor:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    local radius = self:GetSpecialValueFor("radius")

    local heroes = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,hero in ipairs(heroes) do
        if not hero:IsAlive() then break end

        hero:AddNewModifier(caster, ability, "modifier_item_tarrasque_armor_active", { duration = duration })
    end

    EmitSoundOn("Item.Pavise.Target", caster)
end
---
function modifier_item_tarrasque_armor:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK, --GetModifierPhysical_ConstantBlock
    }

    return funcs
end

function modifier_item_tarrasque_armor:OnCreated()
    if not IsServer() then return end
end

function modifier_item_tarrasque_armor:OnRemoved()
    if not IsServer() then return end
end

function modifier_item_tarrasque_armor:GetModifierPhysical_ConstantBlock(params)
    if params.inflictor then return 0 end

    return self:GetCaster():GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("max_hp_block_pct")/100)
end

function modifier_item_tarrasque_armor:GetModifierHealthBonus()
    local flat = self:GetAbility():GetSpecialValueFor("bonus_health")
    local strbonus = self:GetParent():GetStrength() * self:GetAbility():GetSpecialValueFor("hp_per_str")
    return flat+strbonus
end

function modifier_item_tarrasque_armor:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_hp_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_tarrasque_armor:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_tarrasque_armor:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_tarrasque_armor:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetLevelSpecialValueFor("hp_regen_pct", (self:GetAbility():GetLevel() - 1))
end
---
function modifier_item_tarrasque_armor_active:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT, 
    }

    return funcs
end

function modifier_item_tarrasque_armor_active:OnCreated()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.shieldAmount = parent:GetMaxHealth() * (ability:GetSpecialValueFor("active_health_block_pct")/100)

    if not IsServer() then return end

    self.effect_cast = ParticleManager:CreateParticle( "particles/items2_fx/pavise_friend.vpcf", PATTACH_OVERHEAD_FOLLOW, parent )

    ParticleManager:SetParticleControl( self.effect_cast, 0, Vector(300, 0, 0) )

    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        1,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
end

function modifier_item_tarrasque_armor_active:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_item_tarrasque_armor_active:GetModifierIncomingPhysicalDamageConstant(event)
    if not IsServer() then
        return self.shieldAmount
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

    return -block
end

function modifier_item_tarrasque_armor_active:GetTexture() return "tarrasque_armor" end