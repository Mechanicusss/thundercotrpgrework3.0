LinkLuaModifier("modifier_item_ancient_crossbow", "items/item_ancient_crossbow/item_ancient_crossbow.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_crossbow_debuff", "items/item_ancient_crossbow/item_ancient_crossbow.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_crossbow_active", "items/item_ancient_crossbow/item_ancient_crossbow.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_crossbow_crit_stack", "items/item_ancient_crossbow/item_ancient_crossbow.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_ancient_crossbow_buff", "items/item_ancient_crossbow/item_ancient_crossbow.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_ancient_crossbow = class(ItemBaseClass)
item_ancient_crossbow_2 = item_ancient_crossbow
item_ancient_crossbow_3 = item_ancient_crossbow
item_ancient_crossbow_4 = item_ancient_crossbow
item_ancient_crossbow_5 = item_ancient_crossbow
modifier_item_ancient_crossbow = class(ItemBaseClass)
modifier_item_ancient_crossbow_debuff = class(ItemBaseClassDebuff)
modifier_item_ancient_crossbow_active = class(ItemBaseClassBuff)
modifier_item_ancient_crossbow_crit_stack = class(ItemBaseClassBuff)
modifier_item_ancient_crossbow_buff = class(ItemBaseClassBuff)
-------------
function item_ancient_crossbow:GetIntrinsicModifierName()
    return "modifier_item_ancient_crossbow"
end

function item_ancient_crossbow:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function item_ancient_crossbow:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_item_ancient_crossbow_active", {
        duration = self:GetSpecialValueFor("active_duration")
    })

    EmitSoundOn("Item.Brooch.Cast", caster)
end

function modifier_item_ancient_crossbow:GetEffectName() 
    if self:GetAbility():GetLevel() == 8 then
        return "particles/units/heroes/hero_clinkz/clinkz_burning_army_ambient_2.vpcf"
    end
end

function modifier_item_ancient_crossbow:GetModifierProjectileName() 
    if self:GetAbility():GetLevel() == 8 and self:GetParent():IsRangedAttacker() then
        return "particles/econ/items/clinkz/clinkz_maraxiform/clinkz_ti9_summon_projectile_arrow.vpcf"
    end
end

function modifier_item_ancient_crossbow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE_POST_CRIT,
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK
    }
    return funcs
end

function modifier_item_ancient_crossbow:OnAttackRecordDestroy(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target

    target:RemoveModifierByName("modifier_item_ancient_crossbow_debuff")
end

function modifier_item_ancient_crossbow:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_ancient_crossbow:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_ancient_crossbow:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
            
            local ability = self:GetAbility()
            
            EmitSoundOn("DOTA_Item.Daedelus.Crit", params.target)

            local buff = self:GetParent():FindModifierByName("modifier_item_ancient_crossbow_crit_stack")
            if not buff then
                buff = self:GetParent():AddNewModifier(self:GetParent(), ability, "modifier_item_ancient_crossbow_crit_stack", { duration = ability:GetSpecialValueFor("stack_duration") })
            end

            if buff then
                if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
                    buff:IncrementStackCount()
                end

                buff:ForceRefresh()
            end
        end
    end
end

function modifier_item_ancient_crossbow:GetModifierPreAttack_CriticalStrike(keys)
    if not IsServer() then return end 
    
    local ability = self:GetAbility()
    local unit = self:GetParent()

    local crit = ability:GetSpecialValueFor("crit_chance")

    local buff = self:GetParent():FindModifierByName("modifier_item_ancient_crossbow_crit_stack")
    if buff then
        crit = crit + (buff:GetStackCount() * (ability:GetSpecialValueFor("stack_crit_chance")))
    end

    if RollPercentage(crit) then
        local victimArmor = keys.target:GetPhysicalArmorValue(false)
        local reducedArmor = victimArmor * (ability:GetSpecialValueFor("ignore_armor_pct")/100)
        
        keys.target:AddNewModifier(unit, ability, "modifier_item_ancient_crossbow_debuff", {
            armor = -reducedArmor,
            duration = 0.5
        })

        self.record = keys.record

        local critDmg = ability:GetSpecialValueFor("crit_multiplier")

        critDmg = critDmg + (unit:GetAgility() * ability:GetSpecialValueFor("bonus_crit_per_agi"))

        if unit:HasModifier("modifier_item_ancient_crossbow_active") then
            critDmg = critDmg * ability:GetSpecialValueFor("active_multiplier")
        end

        -- Ancient
        if ability:GetLevel() == 5 then
            local ancientBuff = unit:FindModifierByName("modifier_item_ancient_crossbow_buff")
            if not ancientBuff then
                ancientBuff = unit:AddNewModifier(unit, ability, "modifier_item_ancient_crossbow_buff", { duration = ability:GetSpecialValueFor("bonus_agi_stack_duration") })
            end

            if ancientBuff then
                ancientBuff:IncrementStackCount()
            end
        end
        -------

        return critDmg
    end
end

function modifier_item_ancient_crossbow:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_MISS] = true
    }
end
-----------
function modifier_item_ancient_crossbow_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_item_ancient_crossbow_debuff:OnCreated(props)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.armor = props.armor
    self:InvokeBonus()
end

function modifier_item_ancient_crossbow_debuff:GetModifierPhysicalArmorBonus()
    if IsServer() then
        return self.fArmor
    end
end

function modifier_item_ancient_crossbow_debuff:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
    }
end

function modifier_item_ancient_crossbow_debuff:HandleCustomTransmitterData(data)
    if data.armor ~= nil then
        self.fArmor = tonumber(data.armor)
    end
end

function modifier_item_ancient_crossbow_debuff:InvokeBonus()
    if IsServer() == true then
        self.fArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end
----------
function modifier_item_ancient_crossbow_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
    }
end

function modifier_item_ancient_crossbow_buff:GetModifierBonusStats_Agility()
    if self.lock then return 0 end

    self.lock = true

    local agility = self:GetParent():GetAgility()

    self.lock = false

    local bonus = agility * (self:GetAbility():GetSpecialValueFor("bonus_agi_per_stack_pct")/100) * self:GetStackCount()
    
    return bonus
end