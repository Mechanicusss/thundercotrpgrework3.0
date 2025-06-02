require("libraries/cfinder")

LinkLuaModifier("modifier_item_elemental_trident_custom", "items/item_elemental_trident_custom/item_elemental_trident_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_elemental_trident_custom_buff_magical", "items/item_elemental_trident_custom/item_elemental_trident_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_elemental_trident_custom_buff_physical", "items/item_elemental_trident_custom/item_elemental_trident_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_elemental_trident_custom_buff_pure", "items/item_elemental_trident_custom/item_elemental_trident_custom.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

item_elemental_trident_custom = class(ItemBaseClass)
item_elemental_trident_custom_2 = item_elemental_trident_custom
item_elemental_trident_custom_3 = item_elemental_trident_custom
item_elemental_trident_custom_4 = item_elemental_trident_custom
item_elemental_trident_custom_5 = item_elemental_trident_custom
modifier_item_elemental_trident_custom = class(item_elemental_trident_custom)
modifier_item_elemental_trident_custom_buff_magical = class(ItemBaseClassBuff)
modifier_item_elemental_trident_custom_buff_physical = class(ItemBaseClassBuff)
modifier_item_elemental_trident_custom_buff_pure = class(ItemBaseClassBuff)
-------------
function item_elemental_trident_custom:GetIntrinsicModifierName()
    return "modifier_item_elemental_trident_custom"
end
------------
function modifier_item_elemental_trident_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_item_elemental_trident_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local victim = event.unit

    if event.attacker ~= parent or victim == parent then return end
    if not event.inflictor then return end
    --if (event.inflictor and event.inflictor == ability) then return end
    if not parent:IsRealHero() or victim:IsOther() or victim:IsBuilding() or (not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim)) then return end

    if event.inflictor ~= nil then
        if string.match(event.inflictor:GetAbilityName(), "item_scorched_orchid") then return end
    end

    -- Ignore talent damage
    local flags = event.damage_flags 
    if bit.band(flags, 9991) ~= 0 or bit.band(flags, 9992) ~= 0 or bit.band(flags, 9993) ~= 0 or bit.band(flags, 9994) ~= 0 or bit.band(flags, 9995) ~= 0 then return end

    -- We use this flag to detect trident dealing damage, so ignore if it's found
    if bit.band(flags, DOTA_DAMAGE_FLAG_DONT_DISPLAY_DAMAGE_IF_SOURCE_HIDDEN) ~= 0 then return end

    -- Ignore HP loss
    if bit.band(flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return end

    -- Ancient
    if ability:GetLevel() == 5 then
        local ancientBuffName
        if event.damage_type == DAMAGE_TYPE_MAGICAL then
            ancientBuffName = "modifier_item_elemental_trident_custom_buff_magical"
        end
        
        if event.damage_type == DAMAGE_TYPE_PHYSICAL then
            ancientBuffName = "modifier_item_elemental_trident_custom_buff_physical"
        end
        
        if event.damage_type == DAMAGE_TYPE_PURE then
            ancientBuffName = "modifier_item_elemental_trident_custom_buff_pure"
        end

        local ancientBuff = parent:FindModifierByName(ancientBuffName)
        if not ancientBuff then
            ancientBuff = parent:AddNewModifier(parent, ability, ancientBuffName, { duration = ability:GetSpecialValueFor("proficiency_duration") })
        end

        if ancientBuff then
            ancientBuff:ForceRefresh()
        end
    end
    -------
    local critChance = ability:GetSpecialValueFor("spell_crit_chance")
    local critDmg = ability:GetSpecialValueFor("spell_crit_damage")

    local witchBlade = parent:FindModifierByName("modifier_item_witch_blade_custom")
    if witchBlade ~= nil and victim:HasModifier("modifier_item_witch_blade_custom_poison") then
        local witchBladeItem = witchBlade:GetAbility()
        if witchBladeItem ~= nil then
            critDmg = critDmg + witchBladeItem:GetSpecialValueFor("poison_critical_multiplier")
        end
    end

    for _,banned in ipairs(TRIDENT_CRITICAL_IGNORE) do
        if event.inflictor:GetAbilityName() == banned then 
            return
        end
    end

    if IsBossTCOTRPG(victim) then
        for _,banned in ipairs(DAMAGE_FILTER_BANNED_BOSS_ABILITIES) do
            if event.inflictor:GetAbilityName() == banned then 
                return
            end
        end
    end

    if not RollPercentage(critChance) then return end

    local damage = event.damage * (critDmg / 100)

    local flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_DONT_DISPLAY_DAMAGE_IF_SOURCE_HIDDEN
    if string.match(ability:GetAbilityName(), "item_gladiator_armor") then
        flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_DONT_DISPLAY_DAMAGE_IF_SOURCE_HIDDEN
    end

    ApplyDamage({
        victim = victim,
        attacker = event.attacker,
        ability = event.inflictor,
        damage = damage,
        damage_type = event.damage_type,
        damage_flags = flags,
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, damage, nil)

    self:PerformNova(event.damage_type)
end

function modifier_item_elemental_trident_custom:PerformNova(damageType)
    local parent = self:GetParent()

    local particle_cast = "particles/units/heroes/hero_crystalmaiden_persona/cm_persona_nova_2.vpcf"

    if damageType == DAMAGE_TYPE_PURE then
        particle_cast = "particles/units/heroes/hero_crystalmaiden_persona/cm_persona_nova_2_2.vpcf"
    end

    if damageType == DAMAGE_TYPE_PHYSICAL then
        particle_cast = "particles/units/heroes/hero_crystalmaiden_persona/cm_persona_nova_2_2_2.vpcf"
    end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    local radius = ability:GetSpecialValueFor("nova_radius")
    local scaling = ability:GetSpecialValueFor("nova_attribute_mult")

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, Vector(radius, 2, 1000))
    ParticleManager:ReleaseParticleIndex(effect_cast)

    local damage = (parent:GetStrength()+parent:GetAgility()+parent:GetIntellect()) * scaling

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)
    
    for _,victim in pairs(victims) do 
        ApplyDamage({
            attacker = parent,
            victim = victim,
            damage = damage,
            damage_type = damageType,
            ability = ability
        })
    end

    EmitSoundOn("Ability.LightStrikeArray", parent)

    ability:UseResources(false, false, false, true)
end

function modifier_item_elemental_trident_custom:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1)) + self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_elemental_trident_custom:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_elemental_trident_custom:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_elemental_trident_custom:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("spell_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_elemental_trident_custom:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_elemental_trident_custom:GetModifierStatusResistance()
    return self:GetAbility():GetLevelSpecialValueFor("status_resistance", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_elemental_trident_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_elemental_trident_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_elemental_trident_custom:GetEffectName() 
    if self:GetAbility():GetLevel() == 8 then
        return "particles/units/heroes/hero_clinkz/clinkz_burning_army_ambient_2.vpcf"
    end
end

function modifier_item_elemental_trident_custom:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_item_elemental_trident_custom:OnIntervalThink()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    if ability:GetLevel() == 8 then
        if parent:GetLevel() < MAX_LEVEL then
            DisplayError(parent:GetPlayerID(), "Requires Level " .. MAX_LEVEL)
            parent:DropItemAtPositionImmediate(ability, parent:GetAbsOrigin())
        end
    end
end
--------------
function modifier_item_elemental_trident_custom_buff_magical:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_item_elemental_trident_custom_buff_magical:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("proficiency_damage_pct")
end

function modifier_item_elemental_trident_custom_buff_magical:GetModifierTotalDamageOutgoing_Percentage(event)
    local ability = event.inflictor 
    
    if not inflictor then return end 
    if string.match(inflictor:GetAbilityName(), "item_") then return end 
    
    if event.damage_type == DAMAGE_TYPE_MAGICAL then
        return self:GetAbility():GetSpecialValueFor("proficiency_damage_pct") 
    end
end
--------------
function modifier_item_elemental_trident_custom_buff_physical:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_item_elemental_trident_custom_buff_physical:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("proficiency_damage_pct")
end

function modifier_item_elemental_trident_custom_buff_physical:GetModifierTotalDamageOutgoing_Percentage(event)
    local ability = event.inflictor 
    
    if not inflictor then return end 
    if string.match(inflictor:GetAbilityName(), "item_") then return end 

    if event.damage_type == DAMAGE_TYPE_PHYSICAL then
        return self:GetAbility():GetSpecialValueFor("proficiency_damage_pct") 
    end
end
--------------
function modifier_item_elemental_trident_custom_buff_pure:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP 
    }
end

function modifier_item_elemental_trident_custom_buff_pure:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("proficiency_damage_pct") 
end

function modifier_item_elemental_trident_custom_buff_pure:GetModifierTotalDamageOutgoing_Percentage(event)
    local ability = event.inflictor 

    if not inflictor then return end 
    if string.match(inflictor:GetAbilityName(), "item_") then return end 

    if event.damage_type == DAMAGE_TYPE_PURE then
        return self:GetAbility():GetSpecialValueFor("proficiency_damage_pct")
    end
end