LinkLuaModifier("modifier_lone_druid_spirit_link_custom", "heroes/hero_lone_druid/lone_druid_spirit_link_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lone_druid_spirit_link_custom_bear", "heroes/hero_lone_druid/lone_druid_spirit_link_custom", LUA_MODIFIER_MOTION_NONE)

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

lone_druid_spirit_link_custom = class(ItemBaseClass)
modifier_lone_druid_spirit_link_custom = class(lone_druid_spirit_link_custom)
modifier_lone_druid_spirit_link_custom_bear = class(ItemBaseClassBuff)
-------------
function lone_druid_spirit_link_custom:GetIntrinsicModifierName()
    return "modifier_lone_druid_spirit_link_custom"
end

function lone_druid_spirit_link_custom:OnUpgrade()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    local existing = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,ex in ipairs(existing) do
        if string.match(ex:GetUnitName(), "npc_dota_lone_druid_bear_custom") and not ex:HasModifier("modifier_lone_druid_spirit_link_custom_bear") then
            ex:AddNewModifier(caster, self, "modifier_lone_druid_spirit_link_custom_bear", {})
            EmitSoundOn("Hero_LoneDruid.SpiritLink.Bear", ex)
        end
    end
end
-------------
function modifier_lone_druid_spirit_link_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_lone_druid_spirit_link_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_lone_druid_spirit_link_custom:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end
-------------
function modifier_lone_druid_spirit_link_custom_bear:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
    }
end

function modifier_lone_druid_spirit_link_custom_bear:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_lone_druid_spirit_link_custom_bear:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_lone_druid_spirit_link_custom_bear:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end

function modifier_lone_druid_spirit_link_custom_bear:OnAttackLanded(event)
    if not IsServer() then return end

    local caster = self:GetCaster()

    local attacker = event.attacker
    
    local healingTarget = caster

    local talent = caster:FindAbilityByName("talent_lone_druid_2")
    if talent ~= nil and talent:GetLevel() > 1 then
        if attacker ~= self:GetParent() and attacker ~= caster then return end
        if attacker == caster then
            healingTarget = self:GetParent()
        end
    else
        if attacker ~= self:GetParent() then return end
    end
    
    local target = event.target
    
    local ability = self:GetAbility()
    
    local lifestealAmount = self:GetAbility():GetSpecialValueFor("lifesteal_percent")

    if lifestealAmount < 1 or not healingTarget:IsAlive() or healingTarget:GetHealth() < 1 or event.target:IsOther() or event.target:IsBuilding() then
        return
    end

    local heal = event.damage * (lifestealAmount/100)

    --local heal = attacker:GetLevel() + self.lifestealAmount

    if attacker:IsIllusion() then -- Illusions only heal for 10% of the value
        heal = heal * 0.1
    end
    
    --attacker:SetHealth(attacker:GetHealth() + heal) DO NOT USE! Ignores regen reduction
    if heal < 0 or heal > INT_MAX_LIMIT then
        heal = healingTarget:GetMaxHealth()
    end

    healingTarget:Heal(heal, nil)

    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, healingTarget)
    ParticleManager:ReleaseParticleIndex(particle)
end