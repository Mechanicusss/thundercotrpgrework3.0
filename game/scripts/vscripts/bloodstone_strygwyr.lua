LinkLuaModifier("modifier_bloodstone_strygwyr", "bloodstone_strygwyr", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodstone_strygwyr_active", "bloodstone_strygwyr", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodstone_strygwyr_kill_counter", "bloodstone_strygwyr", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodstone_strygwyr_overheal_shield", "bloodstone_strygwyr", LUA_MODIFIER_MOTION_NONE)

--todo: fix charges lost on upgrade, and should start with charges but make sure they dont reset when dropped/picked up again
local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end
}

local ItemBaseClassActiveEffect = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end
}

local ItemBaseClassCounter = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end
}

item_bloodstone_strygwyr = class({})
item_bloodstone_strygwyr_2 = item_bloodstone_strygwyr
item_bloodstone_strygwyr_3 = item_bloodstone_strygwyr
item_bloodstone_strygwyr_4 = item_bloodstone_strygwyr
item_bloodstone_strygwyr_5 = item_bloodstone_strygwyr
item_bloodstone_strygwyr_6 = item_bloodstone_strygwyr
item_bloodstone_strygwyr_7 = item_bloodstone_strygwyr
item_bloodstone_strygwyr_8 = item_bloodstone_strygwyr
item_bloodstone_strygwyr_9 = item_bloodstone_strygwyr
modifier_bloodstone_strygwyr = class(ItemBaseClass)
modifier_bloodstone_strygwyr_active = class(ItemBaseClassActiveEffect)
modifier_bloodstone_strygwyr_kill_counter = class(ItemBaseClassCounter)
modifier_bloodstone_strygwyr_overheal_shield = class(ItemBaseClassActiveEffect)

_G.BloodstoneCharges = {}
-------------
function item_bloodstone_strygwyr:GetIntrinsicModifierName()
    return "modifier_bloodstone_strygwyr"
end

function item_bloodstone_strygwyr:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local amount = self:GetLevelSpecialValueFor("mana_cost_percentage", (self:GetLevel() - 1))
    local duration = self:GetLevelSpecialValueFor("restore_duration", (self:GetLevel() - 1))

    if not caster:IsAlive() or caster:GetHealth() < 1 then return end

    if caster:HasModifier("modifier_bloodstone_strygwyr_active") then
        caster:RemoveModifierByName("modifier_bloodstone_strygwyr_active")
    end

    -- Set New Mana ---
    local removeAmount = caster:GetMana() - caster:GetMaxMana() * (amount / 100)
    if removeAmount > 0 then
        caster:SetMana(removeAmount)

        caster:AddNewModifier(caster, nil, "modifier_bloodstone_strygwyr_active", { duration = duration })
        EmitSoundOnLocationWithCaster(caster:GetOrigin(), "DOTA_Item.Bloodstone.Cast", caster)
    end
end
------------
function modifier_bloodstone_strygwyr:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
        MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
        MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierMPRegenAmplify_Percentage
        --MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, -- GetModifierSpellLifestealRegenAmplify_Percentage
        MODIFIER_EVENT_ON_KILL, -- OnKill
        MODIFIER_EVENT_ON_DEATH, -- OnDeath
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS 
    }

    return funcs
end

function modifier_bloodstone_strygwyr:GetModifierBonusStats_Strength()
    if self.fAttr == DOTA_ATTRIBUTE_STRENGTH or self.fAttr == DOTA_ATTRIBUTE_ALL then
        return self:GetAbility():GetSpecialValueFor("str_mana_hp_conversion_pct") * self:GetAbility():GetCurrentCharges()
    end
end

function modifier_bloodstone_strygwyr:GetModifierHealthBonus()
    local hp = self:GetAbility():GetSpecialValueFor("bonus_health")

    return hp
end

function modifier_bloodstone_strygwyr:GetModifierPreAttack_BonusDamage()
    if self.fAttr == DOTA_ATTRIBUTE_AGILITY or self.fAttr == DOTA_ATTRIBUTE_ALL then
        return self:GetAbility():GetSpecialValueFor("agi_attack_damage") * self:GetAbility():GetCurrentCharges()
    end
end

function modifier_bloodstone_strygwyr:GetModifierAttackSpeedBonus_Constant()
    if self.fAttr == DOTA_ATTRIBUTE_AGILITY or self.fAttr == DOTA_ATTRIBUTE_ALL then
        return self:GetAbility():GetSpecialValueFor("agi_attack_speed") * self:GetAbility():GetCurrentCharges()
    end
end

function modifier_bloodstone_strygwyr:GetModifierConstantManaRegen()
    if self.fAttr == DOTA_ATTRIBUTE_INTELLECT or self.fAttr == DOTA_ATTRIBUTE_ALL then
        return self:GetAbility():GetSpecialValueFor("int_regen_per_charge") * self:GetAbility():GetCurrentCharges()
    end
end

function modifier_bloodstone_strygwyr:GetModifierSpellAmplify_Percentage()
    local defaultValue = self:GetAbility():GetSpecialValueFor("spell_amp")

    return defaultValue
end

function modifier_bloodstone_strygwyr:OnTakeDamage(event)
    if not IsServer() then return end
    
    if event.attacker == self:GetParent() and not event.unit:IsBuilding() and not event.unit:IsOther() then
        if self:GetParent():FindAllModifiersByName(self:GetName())[1] == self and bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL and event.damage_flags ~= 1280 then
            local particle = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.attacker)
            ParticleManager:ReleaseParticleIndex(particle)

            if not event.attacker:IsAlive() or event.attacker:GetHealth() < 1 then return end
            
            local lifestealCreep = self.spell_lifesteal_percent
            local healAmount = math.max(event.damage, 0) * lifestealCreep * 0.01
            if healAmount < 0 or healAmount > INT_MAX_LIMIT then
                healAmount = self:GetParent():GetMaxHealth()
            end

            local healingAfter = event.attacker:GetHealth() + healAmount
            local overheal = healingAfter - event.attacker:GetMaxHealth()

            local caster = self:GetCaster()

            local maxShield = caster:GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("shield_max_from_hp")/100)
            if overheal > maxShield then
                overheal = maxShield
            end

            local buff = caster:FindModifierByName("modifier_bloodstone_strygwyr_overheal_shield")
            if not buff then
                buff = caster:AddNewModifier(caster, self:GetAbility(), "modifier_bloodstone_strygwyr_overheal_shield", {
                    overhealPhysical = overheal,
                    overhealMagic = overheal
                })
            end

            if buff then
                local shieldToAddPhysical = buff.overhealPhysical + overheal
                local shieldToAddMagical = buff.overhealMagic + overheal

                if shieldToAddPhysical > maxShield then
                    shieldToAddPhysical = maxShield
                end

                if shieldToAddMagical > maxShield then
                    shieldToAddMagical = maxShield
                end

                if shieldToAddPhysical < 0 then
                    shieldToAddPhysical = 0
                end

                if shieldToAddMagical < 0 then
                    shieldToAddMagical = 0
                end

                buff.overhealPhysical = shieldToAddMagical
                buff.overhealMagic = shieldToAddMagical

                buff:ForceRefresh()
            end

            event.attacker:Heal(healAmount, event.attacker)
        end
    end
end

function modifier_bloodstone_strygwyr:OnCreated(event)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end
    
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.spell_lifesteal_percent = ability:GetLevelSpecialValueFor("lifesteal", (ability:GetLevel() - 1))

    _G.BloodstoneCharges[caster:entindex()] = _G.BloodstoneCharges[caster:entindex()] or 0

    if _G.BloodstoneCharges[caster:entindex()] > 0 then
        ability:SetCurrentCharges(_G.BloodstoneCharges[caster:entindex()])
    else
        ability:SetCurrentCharges(0)
        _G.BloodstoneCharges[caster:entindex()] = 0
    end

    self.attr = caster:GetPrimaryAttribute()

    self:InvokeAttribute()

    caster:CalculateStatBonus(true)
end

function modifier_bloodstone_strygwyr:AddCustomTransmitterData()
    return
    {
        attr = self.fAttr,
    }
end

function modifier_bloodstone_strygwyr:HandleCustomTransmitterData(data)
    if data.attr ~= nil then
        self.fAttr = tonumber(data.attr)
    end
end

function modifier_bloodstone_strygwyr:InvokeAttribute()
    if IsServer() == true then
        self.fAttr = self.attr

        self:SendBuffRefreshToClients()
    end
end

function modifier_bloodstone_strygwyr:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()
    caster.bloodstone_respawn_reduction = nil

    local shield = caster:FindModifierByName("modifier_bloodstone_strygwyr_overheal_shield")
    if shield ~= nil then
        shield:Destroy()
    end

    local stacks = caster:FindModifierByName("modifier_bloodstone_strygwyr_kill_counter")
    if stacks ~= nil then
        stacks:Destroy()
    end
end

function modifier_bloodstone_strygwyr:GetModifierBonusStats_Intellect()
    local defaultValue = self:GetAbility():GetSpecialValueFor("bonus_intellect")

    if self.fAttr == DOTA_ATTRIBUTE_INTELLECT or self.fAttr == DOTA_ATTRIBUTE_ALL then
        local bonusValue = self:GetAbility():GetSpecialValueFor("int_amp_per_charge") * self:GetAbility():GetCurrentCharges()
        
        return defaultValue + bonusValue
    else
        return defaultValue
    end
end

function modifier_bloodstone_strygwyr:GetModifierManaBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana", (self:GetAbility():GetLevel() - 1))
end

function modifier_bloodstone_strygwyr:GetModifierMPRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("mana_regen_multiplier", (self:GetAbility():GetLevel() - 1))
end

function modifier_bloodstone_strygwyr:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("spell_lifesteal_amp", (self:GetAbility():GetLevel() - 1))
end

---
-- Charges
---

--- Modifiers ---


--- Events ---

function modifier_bloodstone_strygwyr:OnDeath(event)
    if not IsServer() then return end

    local caster = self:GetCaster()

    if event.attacker == caster or (IsSummonTCOTRPG(event.attacker) and event.attacker:GetOwner() == caster) then
        local target = event.unit

        if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end
        
        local ability = self:GetAbility()
        
        local charges = ability:GetCurrentCharges()

        local max_charges = ability:GetSpecialValueFor("max_charges")
        local maxStacks = ability:GetSpecialValueFor("max_stacks")

        local buff = caster:FindModifierByName("modifier_bloodstone_strygwyr_kill_counter")
        if not buff then
            buff = caster:AddNewModifier(caster, ability, "modifier_bloodstone_strygwyr_kill_counter", {})
        end

        if buff then
            if buff:GetStackCount() < max_charges then
                if IsCreepTCOTRPG(target) then
                    buff:IncrementStackCount()
                elseif IsBossTCOTRPG(target) then
                    buff:SetStackCount(max_charges)
                end
            end
            
            if buff:GetStackCount() >= max_charges then
                buff:SetStackCount(0)

                if _G.BloodstoneCharges[caster:entindex()] < maxStacks then
                    _G.BloodstoneCharges[caster:entindex()] = charges + ability:GetSpecialValueFor("kill_charges")

                    ability:SetCurrentCharges(_G.BloodstoneCharges[caster:entindex()])
                
                    caster:CalculateStatBonus(true)
                end
            end

            buff:ForceRefresh()
        end
    end
end

---
-- Charges End
---

---
-- Active Effect
---
function modifier_bloodstone_strygwyr_active:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
    }

    return funcs
end

function modifier_bloodstone_strygwyr_active:GetTexture()
    return "item_bloodstone"
end

function modifier_bloodstone_strygwyr_active:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    self.particle = ParticleManager:CreateParticle("particles/items_fx/bloodstone_heal.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
end

function modifier_bloodstone_strygwyr_active:OnRemoved()
    if not IsServer() then return end 

    if self.particle then
        ParticleManager:DestroyParticle(self.particle, false)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end
end

function modifier_bloodstone_strygwyr_active:GetModifierConstantHealthRegen()
    return self:GetCaster():GetMaxMana() * 0.15
end
------------
function modifier_bloodstone_strygwyr_kill_counter:GetPriority() return 9999 end
------------
function modifier_bloodstone_strygwyr_overheal_shield:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.overhealMagic = params.overhealMagic
    self.overhealPhysical = params.overhealPhysical

    self.shieldMagic = self.overhealMagic
    self.shieldPhysical = self.overhealPhysical
    self:InvokeShield()
end

function modifier_bloodstone_strygwyr_overheal_shield:OnRefresh()
    if not IsServer() then return end 

    self.shieldMagic = self.overhealMagic
    self.shieldPhysical = self.overhealPhysical

    self:InvokeShield()
end

function modifier_bloodstone_strygwyr_overheal_shield:AddCustomTransmitterData()
    return
    {
        shieldMagic = self.fShieldMagic,
        shieldPhysical = self.fShieldPhysical,
    }
end

function modifier_bloodstone_strygwyr_overheal_shield:HandleCustomTransmitterData(data)
    if data.shieldMagic ~= nil and data.shieldPhysical ~= nil then
        self.fShieldPhysical = tonumber(data.shieldPhysical)
        self.fShieldMagic = tonumber(data.shieldMagic)
    end
end

function modifier_bloodstone_strygwyr_overheal_shield:InvokeShield()
    if IsServer() == true then
        self.fShieldPhysical = self.shieldPhysical
        self.fShieldMagic = self.shieldMagic

        self:SendBuffRefreshToClients()
    end
end

function modifier_bloodstone_strygwyr_overheal_shield:DeclareFunctions()
    return {
        --MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT,
        MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT 
    }
end

function modifier_bloodstone_strygwyr_overheal_shield:GetModifierIncomingPhysicalDamageConstant(event)
    if not IsServer() then
        return self.fShieldPhysical
    end

    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end
    if self.overhealPhysical <= 0 then return end

    local block = 0
    local negated = self.overhealPhysical - event.damage 

    if negated <= 0 then
        block = self.overhealPhysical
    else
        block = event.damage
    end

    self.overhealPhysical = negated

    if self.overhealPhysical <= 0 then
        self.overhealPhysical = 0
        self.shieldPhysical = 0
    else
        self.shieldPhysical = self.overhealPhysical
    end

    self:InvokeShield()

    return -block
end

function modifier_bloodstone_strygwyr_overheal_shield:GetModifierIncomingSpellDamageConstant(event)
    if not IsServer() then
        return self.fShieldMagic
    end

    if event.attacker:GetTeam() == self:GetCaster():GetTeam() then return 0 end
    if self.overhealMagic <= 0 then return end

    local block = 0
    local negated = self.overhealMagic - event.damage 

    if negated <= 0 then
        block = self.overhealMagic
    else
        block = event.damage
    end

    self.overhealMagic = negated

    if self.overhealMagic <= 0 then
        self.overhealMagic = 0
        self.shieldMagic = 0
    else
        self.shieldMagic = self.overhealMagic
    end

    self:InvokeShield()

    return -block
end