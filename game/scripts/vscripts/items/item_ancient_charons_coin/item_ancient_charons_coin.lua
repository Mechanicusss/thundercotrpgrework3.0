LinkLuaModifier("modifier_item_ancient_charons_coin", "items/item_ancient_charons_coin/item_ancient_charons_coin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_charons_coin_aura", "items/item_ancient_charons_coin/item_ancient_charons_coin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_charons_coin_buff", "items/item_ancient_charons_coin/item_ancient_charons_coin.lua", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_ancient_charons_coin = class(ItemBaseClass)
item_ancient_charons_coin_2 = item_ancient_charons_coin
item_ancient_charons_coin_3 = item_ancient_charons_coin
item_ancient_charons_coin_4 = item_ancient_charons_coin
item_ancient_charons_coin_5 = item_ancient_charons_coin
modifier_item_ancient_charons_coin = class(ItemBaseClass)
modifier_item_ancient_charons_coin_aura = class(ItemBaseClassBuff)
modifier_item_ancient_charons_coin_buff = class(ItemBaseClassBuff)
-------------
function item_ancient_charons_coin:GetIntrinsicModifierName()
    return "modifier_item_ancient_charons_coin"
end

function item_ancient_charons_coin:OnSpellStart()
    if not IsServer() then return end

    if self:GetLevel() < 5 then return end

    local caster = self:GetCaster()

    EmitSoundOn("Hero_OgreMagi.Bloodlust.Cast", caster)

    local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if IsSummonTCOTRPG(unit) and unit:IsAlive() and unit:GetOwner() == caster then
            local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_cast.vpcf", PATTACH_POINT_FOLLOW, unit)
            ParticleManager:SetParticleControl(effect_cast, 0, unit:GetAbsOrigin())
            ParticleManager:ReleaseParticleIndex(effect_cast)

            unit:AddNewModifier(caster, self, "modifier_item_ancient_charons_coin_buff", {
                duration = self:GetSpecialValueFor("active_duration")
            })

            unit:SetHealth(unit:GetMaxHealth())

            EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", unit)
        end
    end
end
---
function modifier_item_ancient_charons_coin:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.ability = ability

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    self.summons = 0

    self:OnIntervalThink()
    self:StartIntervalThink(FrameTime())
end

function modifier_item_ancient_charons_coin:OnIntervalThink()
    local abilityName = self:GetName()

    local reduction = self:GetAbility():GetSpecialValueFor("damage_reduction_per_unit") * self.summons

    local maxReduction = self:GetAbility():GetSpecialValueFor("max_damage_reduction")

    if reduction < maxReduction then
        reduction = maxReduction 
    end

    _G.PlayerDamageReduction[self.accountID][abilityName] = reduction
end

function modifier_item_ancient_charons_coin:OnRemoved()
    if not IsServer() then return end 

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil

    self.summons = 0
end

function modifier_item_ancient_charons_coin:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
    }

    return funcs
end

function modifier_item_ancient_charons_coin:GetModifierTotalDamageOutgoing_Percentage()
    if IsServer() then
        local outgoing = self:GetAbility():GetSpecialValueFor("outgoing_damage_per_unit") * self.summons

        return outgoing
    end
end

function modifier_item_ancient_charons_coin:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_ancient_charons_coin:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_ancient_charons_coin:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_ancient_charons_coin:GetModifierBonusStats_Intellect()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_ancient_charons_coin:GetModifierBonusStats_Agility()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_ancient_charons_coin:GetModifierBonusStats_Strength()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_ancient_charons_coin:IsAura()
    return true
end

function modifier_item_ancient_charons_coin:GetAuraSearchType()
    return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_item_ancient_charons_coin:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_ancient_charons_coin:GetAuraRadius()
    return FIND_UNITS_EVERYWHERE
end

function modifier_item_ancient_charons_coin:GetModifierAura()
    return "modifier_item_ancient_charons_coin_aura"
end

function modifier_item_ancient_charons_coin:GetAuraEntityReject(target)
    -- Reject non-summons
    if not IsSummonTCOTRPG(target) then return true end 

    -- Reject summons that don't belong to the wearer
    if target:GetOwner() ~= self:GetCaster() then return true end 
    
    return false
end
---------------------
function modifier_item_ancient_charons_coin_aura:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if IsServer() then
        self:StartIntervalThink(FrameTime())
        self:OnIntervalThink()

        local mod = self:GetCaster():FindModifierByName("modifier_item_ancient_charons_coin")
        if not mod or mod == nil then return end
        if not mod.summons then return end 

        mod.summons = mod.summons + 1
    end
end

function modifier_item_ancient_charons_coin_aura:OnRemoved()
    if not IsServer() then return end 

    local mod = self:GetCaster():FindModifierByName("modifier_item_ancient_charons_coin")
    if not mod or mod == nil then return end
    if not mod.summons then return end 

    mod.summons = mod.summons - 1

    if mod.summons < 0 then
        mod.summons = 0
    end
end

function modifier_item_ancient_charons_coin_aura:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.damage = caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("shared_damage_pct"))
    self:InvokeBonus()
end

function modifier_item_ancient_charons_coin_aura:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage
    }
end

function modifier_item_ancient_charons_coin_aura:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_item_ancient_charons_coin_aura:InvokeBonus()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_ancient_charons_coin_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_ancient_charons_coin_aura:OnTakeDamage(event)
    if not IsServer() then return end
    
    if event.attacker == self:GetParent() and not event.unit:IsBuilding() and not event.unit:IsOther() then
        if self:GetParent():FindAllModifiersByName(self:GetName())[1] == self and (event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL or event.damage_type == DAMAGE_TYPE_MAGICAL) and event.inflictor and bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL and event.damage_flags ~= 1280 then
            local particle = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.attacker)
            ParticleManager:ReleaseParticleIndex(particle)

            if not event.attacker:IsAlive() or event.attacker:GetHealth() < 1 then return end
            
            local lifestealCreep = self:GetAbility():GetSpecialValueFor("minion_lifesteal")
            local healAmount = math.max(event.damage, 0) * lifestealCreep * 0.01
            if healAmount < 0 or healAmount > INT_MAX_LIMIT then
                healAmount = self:GetParent():GetMaxHealth()
            end
            event.attacker:Heal(healAmount, event.attacker)
        end
    end
end

function modifier_item_ancient_charons_coin_aura:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end

    local target = event.target
    local attacker = event.attacker
    local ability = self:GetAbility()

    if target:GetUnitName() == "npc_tcot_tormentor" then return end
    ---------------------------
    local lifestealAmount = self:GetAbility():GetSpecialValueFor("minion_lifesteal")

    if lifestealAmount < 1 or not attacker:IsAlive() or attacker:GetHealth() < 1 or event.target:IsOther() or event.target:IsBuilding() then
        return
    end

    local heal = event.damage * (lifestealAmount/100)

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

function modifier_item_ancient_charons_coin_aura:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_reduction_summons")
end

function modifier_item_ancient_charons_coin_aura:GetModifierTotalDamageOutgoing_Percentage()
    if IsServer() then
        local mod = self:GetCaster():FindModifierByName("modifier_item_ancient_charons_coin")
        if not mod or mod == nil then return end
        if not mod.summons then return end 

        local outgoing = self:GetAbility():GetSpecialValueFor("outgoing_damage_per_unit") * mod.summons

        return outgoing
    end
end

function modifier_item_ancient_charons_coin_aura:GetModifierExtraHealthBonus()
    if self:GetParent():GetUnitName() ~= "npc_dota_wraith_king_skeleton_warrior_tcot" then
        return self:GetCaster():GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("shared_health_pct"))
    end
end

function modifier_item_ancient_charons_coin_aura:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_item_ancient_charons_coin_aura:GetModifierAttackSpeedBonus_Constant()
    return (self:GetCaster():GetAttackSpeed(false)*100) * (self:GetAbility():GetSpecialValueFor("shared_attack_speed_pct"))
end

function modifier_item_ancient_charons_coin_aura:GetModifierPhysicalArmorBonus()
    return self:GetCaster():GetPhysicalArmorValue(false) * (self:GetAbility():GetSpecialValueFor("shared_armor_pct"))
end
---------
function modifier_item_ancient_charons_coin_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_MIN_HEALTH 
    }

    return funcs
end

function modifier_item_ancient_charons_coin_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("active_damage_boost_pct")
end

function modifier_item_ancient_charons_coin_buff:GetModifierModelScale()
    return 20
end

function modifier_item_ancient_charons_coin_buff:GetMinHealth()
    return 1
end

function modifier_item_ancient_charons_coin_buff:GetEffectName()
    return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end
