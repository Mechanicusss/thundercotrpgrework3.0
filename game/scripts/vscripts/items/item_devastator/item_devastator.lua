LinkLuaModifier("modifier_item_devastator", "items/item_devastator/item_devastator", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_buff", "items/item_devastator/item_devastator", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_debuff", "items/item_devastator/item_devastator", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
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

item_devastator = class(ItemBaseClass)
item_devastator_2 = item_devastator
item_devastator_3 = item_devastator
item_devastator_4 = item_devastator
item_devastator_5 = item_devastator
item_devastator_6 = item_devastator
modifier_item_devastator = class(item_devastator)
modifier_item_devastator_buff = class(ItemBaseClassBuff)
modifier_item_devastator_debuff = class(ItemBaseClassDebuff)
-------------
function item_devastator:GetIntrinsicModifierName()
    return "modifier_item_devastator"
end

function modifier_item_devastator:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_item_devastator:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker

    if self:GetParent() ~= attacker then
        return
    end

    if event.target:GetUnitName() == "npc_tcot_tormentor" then return end

    local lifestealAmount = self:GetAbility():GetSpecialValueFor("lifesteal")

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

function modifier_item_devastator:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_devastator:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_devastator:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_devastator:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_devastator:OnRemoved()
    if not IsServer() then return end
end

function modifier_item_devastator:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.chance = ability:GetSpecialValueFor("chance")
    self.hpCost = ability:GetSpecialValueFor("hp_cost_pct")

    self.woundedStackDuration = ability:GetSpecialValueFor("wounded_stack_duration")
    self.woundedDamageIncreasePerStack = ability:GetSpecialValueFor("wounded_stack_damage_increase")
    self.woundedMaxStacks = ability:GetSpecialValueFor("wounded_max_stacks")
end

function modifier_item_devastator:OnAttack(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if not RollPercentage(self.chance) or parent:HasModifier("modifier_item_devastator_buff") then return end

    local damage = parent:GetHealth() * (self.hpCost/100)

    ApplyDamage({
        victim = parent,
        attacker = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
    })

    if parent:HasModifier("modifier_item_devastator_buff") then
        parent:RemoveModifierByName("modifier_item_devastator_buff")
    end

    parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_devastator_buff", {
        damageBuff = damage
    })

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_DAMAGE,
        parent,
        damage,
        nil
    )
end

function modifier_item_devastator:GetModifierProcAttack_BonusDamage_Physical(params)
    if IsServer() then
        -- get target
        local target = params.target if target==nil then target = params.unit end
        if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
            return 0
        end

        if not self:GetAbility():IsCooldownReady() then return 0 end

        -- get modifier stack
        local stack = 0
        local modifier = target:FindModifierByNameAndCaster("modifier_item_devastator_debuff", self:GetAbility():GetCaster())

        -- add stack if not
        if modifier==nil then
            -- if does not have break
            if not self:GetParent():IsMuted() then
                -- determine duration if roshan/not

                -- add modifier
                local _mod = target:AddNewModifier(
                    self:GetAbility():GetCaster(),
                    self:GetAbility(),
                    "modifier_item_devastator_debuff",
                    { duration = self.woundedStackDuration }
                )

                _mod:IncrementStackCount()

                -- get stack number
                stack = 1
            end
        else
            modifier:IncrementStackCount()

            modifier:ForceRefresh()

            -- get stack number
            stack = modifier:GetStackCount()

            if modifier:GetStackCount() > self.woundedMaxStacks then
                self:GetAbility():UseResources(false, false, false, true)
                modifier:Destroy()
            end
        end

        -- return damage bonus
        local total = params.damage * ((self.woundedDamageIncreasePerStack * stack)/100)
        return total
    end
end
------------
function modifier_item_devastator_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_EVENT_ON_ATTACK_FINISHED 
    }

    return funcs
end

function modifier_item_devastator_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local parent = self:GetParent()

    self.damage = params.damageBuff

    self:InvokeBonusDamage()
end

function modifier_item_devastator_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage
    }
end

function modifier_item_devastator_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_item_devastator_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_devastator_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_item_devastator_buff:OnAttackFinished(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    self:Destroy()
end
---------
function modifier_item_devastator_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_devastator_debuff:GetTexture()
    return "item_devastator"
end

function modifier_item_devastator_debuff:OnRemoved()
    if not IsServer() then return end

    if self:GetAbility():IsCooldownReady() then
        self:GetAbility():UseResources(false, false, false, true)
    end
end