LinkLuaModifier("modifier_lich_frost_shield_custom", "heroes/hero_lich/lich_frost_shield_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lich_frost_shield_custom_buff", "heroes/hero_lich/lich_frost_shield_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lich_frost_shield_custom_debuff", "heroes/hero_lich/lich_frost_shield_custom", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
}

lich_frost_shield_custom = class(ItemBaseClass)
modifier_lich_frost_shield_custom = class(lich_frost_shield_custom)
modifier_lich_frost_shield_custom_buff = class(ItemBaseClassBuff)
modifier_lich_frost_shield_custom_debuff = class(ItemBaseClassDebuff)
-------------
function lich_frost_shield_custom:GetIntrinsicModifierName()
    return "modifier_lich_frost_shield_custom"
end

function modifier_lich_frost_shield_custom:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_lich_frost_shield_custom:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if ability:GetManaCost(-1) > parent:GetMana() or parent:IsSilenced() or not parent:IsAlive() or not ability:IsCooldownReady() or not ability:IsFullyCastable() or not ability:GetAutoCastState() then return end

    SpellCaster:Cast(ability, parent, true)
end

function lich_frost_shield_custom:GetAOERadius()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return self:GetSpecialValueFor("target_radius")
    end
end

function lich_frost_shield_custom:GetBehavior()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_AUTOCAST + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
    end

    return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AUTOCAST + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
end

function lich_frost_shield_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
        
    local duration = self:GetSpecialValueFor("duration")
    if caster:HasTalent("special_bonus_unique_lich_4_custom") then
        duration = duration + caster:FindAbilityByName("special_bonus_unique_lich_4_custom"):GetSpecialValueFor("value")
    end

    local hasShard = caster:HasModifier("modifier_item_aghanims_shard")

    if hasShard then
        local point = self:GetCursorPosition()
        local radius = self:GetSpecialValueFor("target_radius")

        local targets = FindUnitsInRadius(caster:GetTeam(), point, nil,
            radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,target in ipairs(targets) do
            if not target:IsAlive() then break end

            target:AddNewModifier(caster, self, "modifier_lich_frost_shield_custom_buff", {
                duration = duration
            })
        end

        return
    end

    target:AddNewModifier(caster, self, "modifier_lich_frost_shield_custom_buff", {
        duration = duration
    })
end
------------------
function modifier_lich_frost_shield_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.radius = ability:GetSpecialValueFor("radius")
    self.slowDuration = ability:GetSpecialValueFor("slow_duration")
    self.stackingIncrease = ability:GetSpecialValueFor("stack_increase")
    self.damage = ability:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))
    local interval = ability:GetSpecialValueFor("interval")

    local multiplier = ability:GetSpecialValueFor("int_to_armor")
    if caster:HasTalent("special_bonus_unique_lich_2_custom") then
        multiplier = multiplier + caster:FindAbilityByName("special_bonus_unique_lich_2_custom"):GetSpecialValueFor("value")
    end

    self.armor = caster:GetBaseIntellect() * multiplier
    
    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_lich/lich_ice_age.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        1,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect_cast, 1, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 2, Vector(self.radius, self.radius, self.radius) )

    EmitSoundOn("Hero_Lich.IceAge", parent)

    self:StartIntervalThink(interval)

    self:InvokeBonusArmor()
end

function modifier_lich_frost_shield_custom_buff:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_lich_frost_shield_custom_buff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    local effect_tick = ParticleManager:CreateParticle( "particles/units/heroes/hero_lich/lich_ice_age_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        effect_tick,
        1,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_tick, 1, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect_tick, 2, Vector(self.radius, self.radius, self.radius) )
    ParticleManager:ReleaseParticleIndex(effect_tick)

    EmitSoundOn("Hero_Lich.IceAge.Tick", parent)

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        EmitSoundOn("Hero_Lich.IceAge.Damage", victim)

        local debuff = victim:FindModifierByName("modifier_lich_frost_shield_custom_debuff")
        if debuff == nil then
            debuff = victim:AddNewModifier(caster, self:GetAbility(), "modifier_lich_frost_shield_custom_debuff", {
                duration = self.slowDuration
            })
        end

        if debuff ~= nil then
            debuff:IncrementStackCount()

            ApplyDamage({
                attacker = caster,
                victim = victim,
                damage = self.damage * (1 + (debuff:GetStackCount() * (self.stackingIncrease/100))),
                damage_type = self:GetAbility():GetAbilityDamageType(),
                ability = self:GetAbility(),
            })

            debuff:ForceRefresh()
        end
    end
end

function modifier_lich_frost_shield_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE 

    }
end

function modifier_lich_frost_shield_custom_buff:GetModifierHealthRegenPercentage()
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return self:GetAbility():GetSpecialValueFor("max_health_regen")
    end
end

function modifier_lich_frost_shield_custom_buff:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_lich_frost_shield_custom_buff:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
    }
end

function modifier_lich_frost_shield_custom_buff:HandleCustomTransmitterData(data)
    if data.armor ~= nil then
        self.fArmor = tonumber(data.armor)
    end
end

function modifier_lich_frost_shield_custom_buff:InvokeBonusArmor()
    if IsServer() == true then
        self.fArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end
-------------------
function modifier_lich_frost_shield_custom_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    local effect_frost = ParticleManager:CreateParticle( "particles/units/heroes/hero_lich/lich_ice_age_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        effect_frost,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_frost, 0, parent:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex(effect_frost)
end

function modifier_lich_frost_shield_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE
    }
end

function modifier_lich_frost_shield_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movement_slow")
end

function modifier_lich_frost_shield_custom_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("attack_slow")
end

function modifier_lich_frost_shield_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end