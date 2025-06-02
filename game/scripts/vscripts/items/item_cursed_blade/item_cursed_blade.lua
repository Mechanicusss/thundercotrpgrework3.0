LinkLuaModifier("modifier_item_cursed_blade", "items/item_cursed_blade/item_cursed_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_cursed_blade_damage_debuff", "items/item_cursed_blade/item_cursed_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_cursed_blade_damage_buff", "items/item_cursed_blade/item_cursed_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_cursed_blade_aura", "items/item_cursed_blade/item_cursed_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_cursed_blade_stacking_buff", "items/item_cursed_blade/item_cursed_blade", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_cursed_blade = class(ItemBaseClass)
modifier_item_cursed_blade = class(item_cursed_blade)
modifier_item_cursed_blade_damage_debuff = class(ItemBaseClassDebuff)
modifier_item_cursed_blade_damage_buff = class(ItemBaseClassBuff)
modifier_item_cursed_blade_aura = class(ItemBaseClassBuff)
modifier_item_cursed_blade_stacking_buff = class(ItemBaseClassBuff)
-------------
function item_cursed_blade:GetIntrinsicModifierName()
    return "modifier_item_cursed_blade"
end

function item_cursed_blade:GetAOERadius()
    return self:GetSpecialValueFor("buff_aura_radius")
end
-------------
function modifier_item_cursed_blade:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS  
    }
end

function modifier_item_cursed_blade:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_item_cursed_blade_stacking_buff")
    parent:RemoveModifierByName("modifier_item_cursed_blade_damage_buff")
end

function modifier_item_cursed_blade:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_magic_res")
end

function modifier_item_cursed_blade:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_cursed_blade:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_cursed_blade:bonus_mana_regen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_cursed_blade:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_cursed_blade:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_cursed_blade:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    local attacker = event.attacker 
    local target = event.unit 

    if parent ~= attacker then return end 
    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    local strength_bonus = ability:GetSpecialValueFor("strength_bonus")
    local intellect_bonus = ability:GetSpecialValueFor("intellect_bonus")
    local agility_bonus = ability:GetSpecialValueFor("agility_bonus")

    parent:ModifyStrength(strength_bonus)
    parent:ModifyIntellect(intellect_bonus)
    parent:ModifyAgility(agility_bonus)

    local buff = parent:FindModifierByName("modifier_item_cursed_blade_stacking_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_item_cursed_blade_stacking_buff", {})
    end

    if buff then
        if buff:GetStackCount() < ability:GetSpecialValueFor("debuff_reduction_amp_max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end

function modifier_item_cursed_blade:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    local attacker = event.attacker 
    local target = event.target 

    if parent ~= attacker then return end 
    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()
    local duration = ability:GetSpecialValueFor("debuff_attack_reduction_duration")

    if not parent:HasModifier("modifier_item_cursed_blade_damage_buff") and target:HasModifier("modifier_item_cursed_blade_damage_debuff") then
        target:RemoveModifierByName("modifier_item_cursed_blade_damage_debuff")
    end

    if not target:HasModifier("modifier_item_cursed_blade_damage_debuff") then
        target:AddNewModifier(parent, ability, "modifier_item_cursed_blade_damage_debuff", { duration = duration })
    end
end

function modifier_item_cursed_blade:IsAura()
    return true
end

function modifier_item_cursed_blade:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_item_cursed_blade:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_cursed_blade:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("buff_aura_radius")
end

function modifier_item_cursed_blade:GetModifierAura()
    return "modifier_item_cursed_blade_aura"
end

function modifier_item_cursed_blade:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE 
end

function modifier_item_cursed_blade:GetAuraEntityReject()
    return false
end
--------------
function modifier_item_cursed_blade_damage_debuff:GetEffectName()
    return "particles/items_fx/disperser_buff.vpcf"
end

function modifier_item_cursed_blade_damage_debuff:OnCreated()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.reduced_damage = ((parent:GetDamageMax()+parent:GetDamageMin())/2) * (self:GetAbility():GetSpecialValueFor("debuff_attack_reduction")/100)
    self.caster_damage_buff = math.abs(self.reduced_damage * (self:GetAbility():GetSpecialValueFor("buff_attack_reduction_steal")/100))

    if not IsServer() then return end 

    if caster:HasModifier("modifier_item_cursed_blade_damage_buff") then
        caster:RemoveModifierByName("modifier_item_cursed_blade_damage_buff")
    end

    caster:AddNewModifier(parent, ability, "modifier_item_cursed_blade_damage_buff", { duration = ability:GetSpecialValueFor("buff_attack_reduction_steal_duration"), damage = self.caster_damage_buff })
end

function modifier_item_cursed_blade_damage_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_cursed_blade_damage_debuff:GetModifierPreAttack_BonusDamage()
    return self.reduced_damage
end

function modifier_item_cursed_blade_damage_debuff:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.damage_type == DAMAGE_TYPE_MAGICAL then
        return self:GetAbility():GetSpecialValueFor("debuff_spell_damage")
    end
end
-----------------
function modifier_item_cursed_blade_damage_buff:OnCreated(props)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.damage = props.damage

    self:InvokeBonus()
end

function modifier_item_cursed_blade_damage_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }
end

function modifier_item_cursed_blade_damage_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_item_cursed_blade_damage_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage
    }
end

function modifier_item_cursed_blade_damage_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_item_cursed_blade_damage_buff:InvokeBonus()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
-------------
function modifier_item_cursed_blade_aura:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE  
    }
end

function modifier_item_cursed_blade_aura:GetModifierExtraHealthPercentage()
    local caster = self:GetCaster()
    local stacks = 0

    if caster:HasModifier("modifier_item_cursed_blade_stacking_buff") then
        stacks = caster:GetModifierStackCount("modifier_item_cursed_blade_stacking_buff", caster)
    end

    return self:GetAbility():GetSpecialValueFor("debuff_max_hp_reduction") - stacks
end

function modifier_item_cursed_blade_aura:GetModifierHPRegenAmplify_Percentage()
    local caster = self:GetCaster()
    local stacks = 0

    if caster:HasModifier("modifier_item_cursed_blade_stacking_buff") then
        stacks = caster:GetModifierStackCount("modifier_item_cursed_blade_stacking_buff", caster)
    end

    return self:GetAbility():GetSpecialValueFor("debuff_health_regen_reduction") - stacks
end

function modifier_item_cursed_blade_aura:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end

    local target = event.target
    local attacker = event.attacker
    local ability = self:GetAbility()

    if target:GetUnitName() == "npc_tcot_tormentor" then return end

    local lifestealAmount = self:GetAbility():GetSpecialValueFor("buff_lifesteal")

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
----------------
function modifier_item_cursed_blade_stacking_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_cursed_blade_stacking_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("buff_kill_attack_damage") * self:GetStackCount()
end

function modifier_item_cursed_blade_stacking_buff:RemoveOnDeath()
    return true
end