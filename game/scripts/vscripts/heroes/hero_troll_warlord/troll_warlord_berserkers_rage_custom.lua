LinkLuaModifier("modifier_troll_warlord_berserkers_rage_custom", "heroes/hero_troll_warlord/troll_warlord_berserkers_rage_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_troll_warlord_berserkers_rage_custom_melee", "heroes/hero_troll_warlord/troll_warlord_berserkers_rage_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_troll_warlord_berserkers_rage_custom_ranged", "heroes/hero_troll_warlord/troll_warlord_berserkers_rage_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_troll_warlord_berserkers_rage_custom_ranged_axe_cooldown", "heroes/hero_troll_warlord/troll_warlord_berserkers_rage_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassStance = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

troll_warlord_berserkers_rage_custom = class(ItemBaseClass)
modifier_troll_warlord_berserkers_rage_custom = class(troll_warlord_berserkers_rage_custom)
modifier_troll_warlord_berserkers_rage_custom_melee = class(ItemBaseClassStance)
modifier_troll_warlord_berserkers_rage_custom_ranged = class(ItemBaseClassStance)
modifier_troll_warlord_berserkers_rage_custom_ranged_axe_cooldown = class(ItemBaseClass)
-------------
function troll_warlord_berserkers_rage_custom:GetIntrinsicModifierName()
    return "modifier_troll_warlord_berserkers_rage_custom"
end

function modifier_troll_warlord_berserkers_rage_custom:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local ability = self:GetAbility()

    caster:AddNewModifier(caster, ability, "modifier_troll_warlord_berserkers_rage_custom_ranged", {})
end

function troll_warlord_berserkers_rage_custom:GetAbilityTextureName()
    if self:GetToggleState() then
        return "berserkersrage"
    end

    return "troll_warlord_berserkers_rage"
end

function troll_warlord_berserkers_rage_custom:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)

    local ability = self

    if self:GetToggleState() then
        caster:RemoveModifierByNameAndCaster("modifier_troll_warlord_berserkers_rage_custom_ranged", caster)
        caster:AddNewModifier(caster, ability, "modifier_troll_warlord_berserkers_rage_custom_melee", {})
    else
        caster:RemoveModifierByNameAndCaster("modifier_troll_warlord_berserkers_rage_custom_melee", caster)
        caster:AddNewModifier(caster, ability, "modifier_troll_warlord_berserkers_rage_custom_ranged", {})
    end

    EmitSoundOn("Hero_TrollWarlord.BerserkersRage.Toggle", caster)
end
------------
function modifier_troll_warlord_berserkers_rage_custom_melee:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_troll_warlord_berserkers_rage_custom_melee:GetActivityTranslationModifiers()
    if self:GetParent():GetName() == "npc_dota_hero_troll_warlord" then
        return "melee"
    end

    return 0
end

function modifier_troll_warlord_berserkers_rage_custom_melee:GetAttackSound()
    return "Hero_TrollWarlord.ProjectileImpact"
end

function modifier_troll_warlord_berserkers_rage_custom_melee:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_troll_warlord_berserkers_rage_custom_melee:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("melee_bonus_speed")
end

function modifier_troll_warlord_berserkers_rage_custom_melee:GetModifierAttackRangeBonus()
    return self.attackRange
end

function modifier_troll_warlord_berserkers_rage_custom_melee:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self.attackRange = 150 - self:GetParent():Script_GetAttackRange()

    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)

    local whirlingAxes_Melee = parent:FindAbilityByName("troll_warlord_whirling_axes_melee")
    local whirlingAxes_Ranged = parent:FindAbilityByName("troll_warlord_whirling_axes_ranged")
    if whirlingAxes_Melee ~= nil and whirlingAxes_Ranged ~= nil then
        whirlingAxes_Melee:SetActivated(true)
        whirlingAxes_Ranged:SetActivated(false)
    end

    self.lifestealAmount = ability:GetSpecialValueFor("melee_lifesteal")

    self:OnIntervalThink()

    self:StartIntervalThink(1)
end

function modifier_troll_warlord_berserkers_rage_custom_melee:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.armor = parent:GetPhysicalArmorBaseValue() * (ability:GetSpecialValueFor("melee_bonus_armor_pct")/100)

    self:InvokeBonus()
end

function modifier_troll_warlord_berserkers_rage_custom_melee:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
end

function modifier_troll_warlord_berserkers_rage_custom_melee:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker

    if self:GetParent() ~= attacker then
        return
    end

    if self.lifestealAmount < 1 or not attacker:IsAlive() or attacker:GetHealth() < 1 or event.target:IsOther() or event.target:IsBuilding() then
        return
    end

    local heal = event.damage * (self.lifestealAmount/100)

    --local heal = attacker:GetLevel() + self.lifestealAmount

    if attacker:IsIllusion() then -- Illusions only heal for 10% of the value
        heal = heal * 0.1
    end
    
    --attacker:SetHealth(attacker:GetHealth() + heal) DO NOT USE! Ignores regen reduction
    if heal < 0 or heal > INT_MAX_LIMIT then
        heal = self:GetParent():GetMaxHealth()
    end
    attacker:Heal(heal, nil)

    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_troll_warlord_berserkers_rage_custom_melee:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
    }
end

function modifier_troll_warlord_berserkers_rage_custom_melee:HandleCustomTransmitterData(data)
    if data.armor ~= nil then
        self.fArmor = tonumber(data.armor)
    end
end

function modifier_troll_warlord_berserkers_rage_custom_melee:InvokeBonus()
    if IsServer() == true then
        self.fArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end
------------------------
function modifier_troll_warlord_berserkers_rage_custom_ranged:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)

    local whirlingAxes_Melee = parent:FindAbilityByName("troll_warlord_whirling_axes_melee")
    local whirlingAxes_Ranged = parent:FindAbilityByName("troll_warlord_whirling_axes_ranged")
    if whirlingAxes_Melee ~= nil and whirlingAxes_Ranged ~= nil then
        whirlingAxes_Melee:SetActivated(false)
        whirlingAxes_Ranged:SetActivated(true)
    end
end

function modifier_troll_warlord_berserkers_rage_custom_ranged:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
    return funcs
end

function modifier_troll_warlord_berserkers_rage_custom_ranged:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("ranged_bonus_damage_pct")
end

function modifier_troll_warlord_berserkers_rage_custom_ranged:OnAttack(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() or caster:IsIllusion() or not caster:IsRealHero() then
        return
    end

    local ability = self:GetAbility()
    local rollChance = ability:GetSpecialValueFor("ranged_axe_chance")
    local radius = ability:GetSpecialValueFor("ranged_axe_radius")

    if not RollPercentage(rollChance) or parent:HasModifier("modifier_troll_warlord_berserkers_rage_custom_ranged_axe_cooldown") then return end

    local enemies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)
    enemies = shuffleTable(enemies)
    local target = nil

    for _,enemy in ipairs(enemies) do
        if parent:CanEntityBeSeenByMyTeam(enemy) then
            target = enemy
            break
        end
    end

    if target == nil then return end

    parent:AddNewModifier(parent, ability, "modifier_troll_warlord_berserkers_rage_custom_ranged_axe_cooldown", { duration = parent:GetSecondsPerAttack()+0.2 })

    Timers:CreateTimer(0.2, function()
        parent:PerformAttack(
            target,
            true,
            true,
            true,
            false,
            true,
            false,
            false
        )
    end)
end