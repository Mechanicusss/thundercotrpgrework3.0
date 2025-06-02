LinkLuaModifier("modifier_night_stalker_dark_ascension_custom", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_stacks_damage", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_stacks_bat", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_stacks_spell", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_stacks_mana", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_stacks_strength", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_stacks_strength_to_spell", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_debuff", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_talent_crit_buff", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

night_stalker_dark_ascension_custom = class(ItemBaseClass)
modifier_night_stalker_dark_ascension_custom = class(night_stalker_dark_ascension_custom)
modifier_night_stalker_dark_ascension_custom_debuff = class(ItemBaseClassDebuff)
modifier_night_stalker_dark_ascension_custom_stacks_damage = class(ItemBaseClassStacks)
modifier_night_stalker_dark_ascension_custom_stacks_bat = class(ItemBaseClassStacks)
modifier_night_stalker_dark_ascension_custom_stacks_spell = class(ItemBaseClassStacks)
modifier_night_stalker_dark_ascension_custom_stacks_mana = class(ItemBaseClassStacks)
modifier_night_stalker_dark_ascension_custom_stacks_strength = class(ItemBaseClassStacks)
modifier_night_stalker_dark_ascension_custom_stacks_strength_to_spell = class(ItemBaseClassStacks)
modifier_night_stalker_dark_ascension_custom_talent_crit_buff = class(ItemBaseClassDebuff)

function night_stalker_dark_ascension_custom:GetIntrinsicModifierName()
    return "modifier_night_stalker_dark_ascension_custom"
end

function night_stalker_dark_ascension_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function night_stalker_dark_ascension_custom:OnUpgrade()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local mod = caster:FindModifierByName("modifier_night_stalker_dark_ascension_custom")
    if not mod then return end

    local interval = self:GetSpecialValueFor("interval")

    mod:StartIntervalThink(-1)
    mod:StartIntervalThink(interval)
end
-------------
function modifier_night_stalker_dark_ascension_custom:OnCreated()
    if not IsServer() then return end
    
    local ability = self:GetAbility()
    local interval = ability:GetSpecialValueFor("interval")

    self:StartIntervalThink(interval)
end

function modifier_night_stalker_dark_ascension_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")
    local interval = ability:GetSpecialValueFor("interval")
    local parent = self:GetParent()

    -- Don't do anything if he has the talent at level 3
    local talent = parent:FindAbilityByName("talent_night_stalker_1")
    if talent and talent:GetLevel() > 2 then
        return
    end

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)
    
    victims = shuffleTable(victims)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() or enemy:HasModifier("modifier_night_stalker_dark_ascension_custom_debuff") or IsBossTCOTRPG(enemy) then break end

        enemy:AddNewModifier(parent, ability, "modifier_night_stalker_dark_ascension_custom_debuff", {
            duration = interval
        })
        break
    end
end

function modifier_night_stalker_dark_ascension_custom:IsAura()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_1")
    if talent and talent:GetLevel() > 2 then
        return true
    end

    return false
end

function modifier_night_stalker_dark_ascension_custom:GetAuraSearchType()
    return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_night_stalker_dark_ascension_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_night_stalker_dark_ascension_custom:GetAuraRadius()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_1")
    if talent and talent:GetLevel() > 2 then
        return talent:GetSpecialValueFor("prey_radius")
    end
end

function modifier_night_stalker_dark_ascension_custom:GetModifierAura()
    return "modifier_night_stalker_dark_ascension_custom_debuff"
end

function modifier_night_stalker_dark_ascension_custom:GetAuraSearchFlags()
 return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_night_stalker_dark_ascension_custom:GetAuraEntityReject()
    return false
end
-----------
function modifier_night_stalker_dark_ascension_custom_debuff:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self:GetParent():MakeVisibleToTeam(caster:GetTeam(), ability:GetSpecialValueFor("interval"))

    local talent = caster:FindAbilityByName("talent_night_stalker_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then return end

    if caster:HasModifier("modifier_night_stalker_dark_ascension_custom_talent_crit_buff") then
        caster:RemoveModifierByName("modifier_night_stalker_dark_ascension_custom_talent_crit_buff")
    end

    caster:AddNewModifier(caster, ability, "modifier_night_stalker_dark_ascension_custom_talent_crit_buff", {
        duration = talent:GetSpecialValueFor("prey_duration")
    })
end

function modifier_night_stalker_dark_ascension_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION 
    }
end

function modifier_night_stalker_dark_ascension_custom_debuff:GetModifierProvidesFOWVision()
    return 1
end

function modifier_night_stalker_dark_ascension_custom_debuff:GetEffectName()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then
        return "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track__2shield.vpcf"
    end
end

function modifier_night_stalker_dark_ascension_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_night_stalker_dark_ascension_custom_debuff:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end

    local caster = self:GetCaster()

    if caster ~= event.attacker then return end 

    local talent = caster:FindAbilityByName("talent_night_stalker_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then
        local buffs = {
            "modifier_night_stalker_dark_ascension_custom_stacks_damage",
            "modifier_night_stalker_dark_ascension_custom_stacks_bat",
            "modifier_night_stalker_dark_ascension_custom_stacks_spell",
        }

        local talent2 = caster:FindAbilityByName("talent_night_stalker_2")
        if talent2 and talent2:GetLevel() > 0 then
            table.insert(buffs, "modifier_night_stalker_dark_ascension_custom_stacks_mana")
            table.insert(buffs, "modifier_night_stalker_dark_ascension_custom_stacks_strength")
        end

        local buffName = ""

        buffs = shuffleTable(buffs)

        for _,randomBuff in ipairs(buffs) do
            local exists = caster:FindModifierByName(randomBuff)

            if not exists then
                buffName = randomBuff
                break
            end

            if exists then
                if exists:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
                    buffName = randomBuff
                    break
                end
            end
        end

        local stack = caster:FindModifierByName(buffName)
        if not stack then
            stack = caster:AddNewModifier(caster, self:GetAbility(), buffName, {})
        end

        if stack then
            if stack:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
                stack:IncrementStackCount()
            end

            stack:ForceRefresh()
        end

        local tonightWeHunt = caster:FindModifierByName("modifier_night_stalker_dark_ascension_custom")
        if not tonightWeHunt then return end
        if tonightWeHunt:IsAura() then return end

        local interval = self:GetAbility():GetSpecialValueFor("interval")

        -- When a prey has been killed, we stop the interval and re-start it so it begins to find a new one
        tonightWeHunt:StartIntervalThink(-1) 
        tonightWeHunt:OnIntervalThink()
        tonightWeHunt:StartIntervalThink(interval)
    end
end
-------------------
function modifier_night_stalker_dark_ascension_custom_stacks_damage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_night_stalker_dark_ascension_custom_stacks_damage:GetModifierDamageOutgoing_Percentage()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then
        return self:GetAbility():GetSpecialValueFor("stack_outgoing_damage") * self:GetStackCount()
    end
end

function modifier_night_stalker_dark_ascension_custom_stacks_damage:IsHidden()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then
        return false
    end

    return true
end

function modifier_night_stalker_dark_ascension_custom_stacks_damage:GetPriority() return 9999 end
-------------------
function modifier_night_stalker_dark_ascension_custom_stacks_bat:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT  
    }
end

function modifier_night_stalker_dark_ascension_custom_stacks_bat:GetModifierAttackSpeedBonus_Constant()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then
        return self:GetAbility():GetSpecialValueFor("stack_attack_speed") * self:GetStackCount()
    end
end

function modifier_night_stalker_dark_ascension_custom_stacks_bat:IsHidden()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then
        return false
    end

    return true
end

function modifier_night_stalker_dark_ascension_custom_stacks_bat:GetPriority() return 9999 end
-------------------
function modifier_night_stalker_dark_ascension_custom_stacks_spell:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE  
    }
end

function modifier_night_stalker_dark_ascension_custom_stacks_spell:GetModifierSpellAmplify_Percentage()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then
        return self:GetAbility():GetSpecialValueFor("stack_spell_amp") * self:GetStackCount()
    end
end

function modifier_night_stalker_dark_ascension_custom_stacks_spell:IsHidden()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then
        return false
    end

    return true
end

function modifier_night_stalker_dark_ascension_custom_stacks_spell:GetPriority() return 9999 end
----------
function modifier_night_stalker_dark_ascension_custom_talent_crit_buff:IsHidden() return true end 

function modifier_night_stalker_dark_ascension_custom_talent_crit_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }
end

function modifier_night_stalker_dark_ascension_custom_talent_crit_buff:GetModifierPreAttack_CriticalStrike(params)
    if IsServer() then
        local caster = self:GetCaster()
        local talent = caster:FindAbilityByName("talent_night_stalker_1")

        if talent and talent:GetLevel() > 0 and params.target:HasModifier("modifier_night_stalker_dark_ascension_custom_debuff") then
            self.record = params.record

            return talent:GetSpecialValueFor("crit_damage") + (caster:GetStrength() * talent:GetSpecialValueFor("crit_damage_per_str"))
        end
    end
end

function modifier_night_stalker_dark_ascension_custom_talent_crit_buff:GetModifierProcAttack_Feedback(params)
    if IsServer() then
        if self.record then
            self.record = nil
        end
    end
end
-------------------
function modifier_night_stalker_dark_ascension_custom_stacks_mana:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MANA_BONUS
    }
end

function modifier_night_stalker_dark_ascension_custom_stacks_mana:GetModifierManaBonus()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_2")
    if talent and talent:GetLevel() > 0 then
        return talent:GetSpecialValueFor("mana_per_kill") * self:GetStackCount()
    end
end

function modifier_night_stalker_dark_ascension_custom_stacks_mana:IsHidden()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_2")
    if talent and talent:GetLevel() > 0 then
        return false
    end

    return true
end

function modifier_night_stalker_dark_ascension_custom_stacks_mana:GetPriority() return 9999 end
-------------------
function modifier_night_stalker_dark_ascension_custom_stacks_strength:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS 
    }
end

function modifier_night_stalker_dark_ascension_custom_stacks_strength:GetModifierBonusStats_Strength()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_2")
    if talent and talent:GetLevel() > 1 then
        return talent:GetSpecialValueFor("strength_per_kill") * self:GetStackCount()
    end
end

function modifier_night_stalker_dark_ascension_custom_stacks_strength:IsHidden()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_2")
    if talent and talent:GetLevel() > 1 then
        return false
    end

    return true
end

function modifier_night_stalker_dark_ascension_custom_stacks_strength:GetPriority() return 9999 end
-------------------
function modifier_night_stalker_dark_ascension_custom_stacks_strength_to_spell:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE  
    }
end

function modifier_night_stalker_dark_ascension_custom_stacks_strength_to_spell:GetModifierSpellAmplify_Percentage()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_2")
    if talent and talent:GetLevel() > 2 then
        return talent:GetSpecialValueFor("spell_amp_per_strength") * self:GetCaster():GetStrength()
    end
end

function modifier_night_stalker_dark_ascension_custom_stacks_strength_to_spell:IsHidden()
    local talent = self:GetCaster():FindAbilityByName("talent_night_stalker_2")
    if talent and talent:GetLevel() > 2 then
        return false
    end

    return true
end

function modifier_night_stalker_dark_ascension_custom_stacks_strength_to_spell:GetPriority() return 9999 end