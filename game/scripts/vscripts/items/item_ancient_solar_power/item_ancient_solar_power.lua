LinkLuaModifier("modifier_item_ancient_solar_power", "items/item_ancient_solar_power/item_ancient_solar_power.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_solar_power_buff", "items/item_ancient_solar_power/item_ancient_solar_power.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_solar_power_pulse", "items/item_ancient_solar_power/item_ancient_solar_power.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_solar_power_blinded", "items/item_ancient_solar_power/item_ancient_solar_power.lua", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_ancient_solar_power = class(ItemBaseClass)
item_ancient_solar_power_2 = item_ancient_solar_power
item_ancient_solar_power_3 = item_ancient_solar_power
item_ancient_solar_power_4 = item_ancient_solar_power
item_ancient_solar_power_5 = item_ancient_solar_power
modifier_item_ancient_solar_power = class(ItemBaseClass)
modifier_item_ancient_solar_power_buff = class(ItemBaseClassBuff)
modifier_item_ancient_solar_power_pulse = class(ItemBaseClassBuff)
modifier_item_ancient_solar_power_blinded = class(ItemBaseClassDebuff)
-------------
function item_ancient_solar_power:GetIntrinsicModifierName()
    return "modifier_item_ancient_solar_power"
end
-------------
function modifier_item_ancient_solar_power:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
end

function modifier_item_ancient_solar_power:GetModifierBonusStats_Intellect()
    return self.fIntel
end

function modifier_item_ancient_solar_power:GetModifierSpellAmplify_Percentage()
    return self.fAmp
end

function modifier_item_ancient_solar_power:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.intel = self:GetAbility():GetSpecialValueFor("bonus_intellect")
    self.amp = self:GetAbility():GetSpecialValueFor("bonus_spell_damage")

    self:StartIntervalThink(0.1)
end

function modifier_item_ancient_solar_power:OnIntervalThink()
    if GameRules:IsDaytime() and self:GetAbility():GetLevel() == 5 then
        self.intel = self:GetAbility():GetSpecialValueFor("bonus_intellect") * self:GetAbility():GetSpecialValueFor("daytime_stat_mult")
        self.amp = self:GetAbility():GetSpecialValueFor("bonus_spell_damage") * self:GetAbility():GetSpecialValueFor("daytime_stat_mult")
    else
        self.intel = self:GetAbility():GetSpecialValueFor("bonus_intellect")
        self.amp = self:GetAbility():GetSpecialValueFor("bonus_spell_damage")
    end

    self:InvokeBonus()
end

function modifier_item_ancient_solar_power:AddCustomTransmitterData()
    return
    {
        amp = self.fAmp,
        intel = self.fIntel
    }
end

function modifier_item_ancient_solar_power:HandleCustomTransmitterData(data)
    if data.amp ~= nil and data.intel ~= nil then
        self.fAmp = tonumber(data.amp)
        self.fIntel = tonumber(data.intel)
    end
end

function modifier_item_ancient_solar_power:InvokeBonus()
    if IsServer() == true then
        self.fAmp = self.amp
        self.fIntel = self.intel

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_ancient_solar_power:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end 

    if event.damage_type ~= DAMAGE_TYPE_PURE then
        return -9999
    end

    if event.damage_type == DAMAGE_TYPE_PURE then
        local damage = self:GetAbility():GetSpecialValueFor("pure_damage_pct")

        if GameRules:IsDaytime() then
            damage = damage * self:GetAbility():GetSpecialValueFor("daytime_stat_mult")
        end

        return damage
    end
end

function modifier_item_ancient_solar_power:OnAbilityFullyCast(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    local ability = self:GetAbility()

    if ability == event.ability then return end 

    if not ability:IsCooldownReady() then return end 

    if string.match(event.ability:GetAbilityName(), "item_") then return end
    if string.match(event.ability:GetAbilityName(), "twin_gate_portal_warp_custom") then return end
    if string.match(event.ability:GetAbilityName(), "aghanim_tower_capture") then return end

    parent:RemoveModifierByName("modifier_item_ancient_solar_power_buff")

    parent:AddNewModifier(parent, ability, "modifier_item_ancient_solar_power_buff", { duration = ability:GetSpecialValueFor("duration") })

    ability:UseResources(false, false, false, true)
end
-----------
function modifier_item_ancient_solar_power_buff:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    EmitSoundOn("Hero_Luna.Eclipse.Cast", parent)

    parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_ancient_solar_power_pulse", {})

    self.flare = ParticleManager:CreateParticle( "particles/econ/items/luna/luna_lucent_ti5_gold/luna_eclipse_cast_moonfall_gold.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.flare,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.flare,
        1,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    self:StartIntervalThink(interval)
end

function modifier_item_ancient_solar_power_buff:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")
    local damage = ability:GetSpecialValueFor("int_multiplier")

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for i,victim in pairs(victims) do
        local effect_cast = ParticleManager:CreateParticle( "particles/econ/items/luna/luna_lucent_ti5_gold/luna_eclipse_impact_moonfall_gold.vpcf", PATTACH_ABSORIGIN_FOLLOW, victim )
        ParticleManager:SetParticleControlEnt(
            effect_cast,
            0,
            victim,
            PATTACH_ABSORIGIN_FOLLOW,
            "attach_hitloc",
            victim:GetAbsOrigin(), -- unknown
            true -- unknown, true
        )
        ParticleManager:SetParticleControlEnt(
            effect_cast,
            1,
            victim,
            PATTACH_ABSORIGIN_FOLLOW,
            "attach_hitloc",
            victim:GetAbsOrigin(), -- unknown
            true -- unknown, true
        )
        ParticleManager:SetParticleControlEnt(
            effect_cast,
            5,
            victim,
            PATTACH_ABSORIGIN_FOLLOW,
            "attach_hitloc",
            victim:GetAbsOrigin(), -- unknown
            true -- unknown, true
        )
        ParticleManager:ReleaseParticleIndex(effect_cast)
        
        ApplyDamage({
            attacker = parent,
            victim = victim,
            damage = parent:GetIntellect() * (damage),
            damage_type = DAMAGE_TYPE_PURE,
            ability = ability
        })

        EmitSoundOn("Hero_Luna.Eclipse.Target", victim)
    end
end

function modifier_item_ancient_solar_power_buff:OnDestroy()
    if not IsServer() then return end 

    if self.flare ~= nil then
        ParticleManager:DestroyParticle(self.flare, false)
        ParticleManager:ReleaseParticleIndex(self.flare)
    end

    self:GetParent():RemoveModifierByName("modifier_item_ancient_solar_power_pulse")
end
-------------
function modifier_item_ancient_solar_power_pulse:IsHidden() return true end

function modifier_item_ancient_solar_power_pulse:OnCreated()
    if not IsServer() then return end 

    local interval = self:GetAbility():GetSpecialValueFor("pulse_interval")

    self:StartIntervalThink(interval)
end

function modifier_item_ancient_solar_power_pulse:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("pulse_radius")
    local duration = ability:GetSpecialValueFor("blind_duration")

    EmitSoundOn("Hero_KeeperOfTheLight.BlindingLight", parent)

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_blinding_light_aoe.vpcf", PATTACH_ABSORIGIN_FOLLOW, victim )
    ParticleManager:SetParticleControl(effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 2, Vector(radius,radius,radius))
    ParticleManager:ReleaseParticleIndex(effect_cast)

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for i,victim in pairs(victims) do
        victim:AddNewModifier(parent, ability, "modifier_item_ancient_solar_power_blinded", { duration = duration })
    end
end
----------
function modifier_item_ancient_solar_power_blinded:GetEffectName()
    return "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_blinding_light_debuff.vpcf"
end

function modifier_item_ancient_solar_power_blinded:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MISS_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_item_ancient_solar_power_blinded:GetModifierMiss_Percentage()
    return self:GetAbility():GetSpecialValueFor("blind_miss")
end

function modifier_item_ancient_solar_power_blinded:GetModifierIncomingDamage_Percentage(event)
    if not IsServer() then return end 

    if event.damage_type == DAMAGE_TYPE_PURE and GameRules:IsDaytime() then
        return self:GetAbility():GetSpecialValueFor("blind_pure_vulnerability")
    end
end