LinkLuaModifier("modifier_jagged_blade", "items/item_jagged_blade/item_jagged_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jagged_blade_debuff", "items/item_jagged_blade/item_jagged_blade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jagged_blade_disarmor", "items/item_jagged_blade/item_jagged_blade", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end
}

item_jagged_blade = class(ItemBaseClass)
item_jagged_blade_2 = item_jagged_blade
item_jagged_blade_3 = item_jagged_blade
modifier_jagged_blade_debuff = class(ItemBaseDebuffClass)
modifier_jagged_blade_disarmor = class(ItemBaseDebuffClass)
modifier_jagged_blade = class(item_jagged_blade)
-------------
function item_jagged_blade:GetIntrinsicModifierName()
    return "modifier_jagged_blade"
end
------------
function modifier_jagged_blade_disarmor:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus (flat)
    }

    return funcs
end

function modifier_jagged_blade_disarmor:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("corruption_armor_base")
end
------------
function modifier_jagged_blade_debuff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local ability = self:GetAbility()
    
    self.maxPct = ability:GetSpecialValueFor("corruption_armor_pct_max")
    self.corAmt = ability:GetSpecialValueFor("corruption_armor_pct")
    self.corAmtBonus = ability:GetSpecialValueFor("corruption_armor")
    self.corMax = ability:GetSpecialValueFor("corruption_max")

    self:OnRefresh()
end

function modifier_jagged_blade_debuff:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    local baseArmor = parent:GetPhysicalArmorBaseValue()
    local stacks = self:GetStackCount()
    local limit = false

    if stacks >= self.maxPct then
        limit = true
        stacks = self.maxPct
    end

    local reduction = (self.corAmt * stacks)/100
    local armor = baseArmor * reduction

    self.pctArmor = armor
    self.baseArmor = 0 

    if limit then
        local bonusArmorRemoval = self.corAmtBonus * (self:GetStackCount()-stacks)

        self.baseArmor = bonusArmorRemoval
    end

    self.totalArmor = self.baseArmor + self.pctArmor

    self:InvokeArmor()
end

function modifier_jagged_blade_debuff:AddCustomTransmitterData()
    return
    {
        baseArmor = self.fBaseArmor,
        pctArmor = self.fPctArmor,
        totalArmor = self.fTotalArmor,
    }
end

function modifier_jagged_blade_debuff:HandleCustomTransmitterData(data)
    if data.pctArmor ~= nil and data.baseArmor ~= nil and data.totalArmor ~= nil then
        self.fBaseArmor = tonumber(data.baseArmor)
        self.fPctArmor = tonumber(data.pctArmor)
        self.fTotalArmor = tonumber(data.totalArmor)
    end
end

function modifier_jagged_blade_debuff:InvokeArmor()
    if IsServer() == true then
        self.fPctArmor = self.pctArmor
        self.fBaseArmor = self.baseArmor
        self.fTotalArmor = self.totalArmor

        self:SendBuffRefreshToClients()
    end
end

function modifier_jagged_blade_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_jagged_blade_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus (flat)
    }

    return funcs
end

function modifier_jagged_blade_debuff:GetModifierPhysicalArmorBonus()
    return self.fTotalArmor
end
------------
function modifier_jagged_blade:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        --MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        --MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        --MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        --MODIFIER_PROPERTY_EVASION_CONSTANT, --GetModifierEvasion_Constant
        
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_jagged_blade:OnCreated()
    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.damage = self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
        self.attackspeed = self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
        self.movespeed = self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
        self.agility = self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
        self.evasion = self:GetAbility():GetLevelSpecialValueFor("bonus_evasion", (self:GetAbility():GetLevel() - 1))
        self.duration = self:GetAbility():GetLevelSpecialValueFor("corruption_duration", (self:GetAbility():GetLevel() - 1))
        self.maxStacks = self:GetAbility():GetLevelSpecialValueFor("corruption_max", (self:GetAbility():GetLevel() - 1))
        self.pctMaxStacks = self:GetAbility():GetLevelSpecialValueFor("corruption_armor_pct_max", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_jagged_blade:OnRemoved()
    if not IsServer() then return end
end

function modifier_jagged_blade:OnTakeDamage(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.unit

    if self:GetCaster() ~= attacker or attacker == victim then
        return
    end

    if not attacker:IsRealHero() or attacker:IsIllusion() or not UnitIsNotMonkeyClone(attacker) or attacker:IsMuted() then return end
    if victim:IsMagicImmune() or (not IsBossTCOTRPG(victim) and not IsCreepTCOTRPG(victim)) or victim:IsBuilding() then return end

    local disarm = victim:FindModifierByName("modifier_jagged_blade_disarmor")
    
    if not disarm then
        disarm = victim:AddNewModifier(attacker, self:GetAbility(), "modifier_jagged_blade_disarmor", { duration = self.duration })
    end

    if disarm ~= nil then
        disarm:ForceRefresh()
    end

    local debuff = victim:FindModifierByName("modifier_jagged_blade_debuff")
    if debuff == nil then
        debuff = victim:AddNewModifier(attacker, self:GetAbility(), "modifier_jagged_blade_debuff", { duration = self.duration })
    end

    if debuff ~= nil then
        if debuff:GetStackCount() < (self.maxStacks+self.pctMaxStacks) then
            debuff:IncrementStackCount()
        end
        debuff:ForceRefresh()
    end
end

function modifier_jagged_blade:GetModifierPreAttack_BonusDamage()
    return self.damage or self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_jagged_blade:GetModifierAttackSpeedBonus_Constant()
    return self.attackspeed or self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_jagged_blade:GetModifierMoveSpeedBonus_Percentage()
    return self.movespeed or self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_jagged_blade:GetModifierBonusStats_Agility()
    return self.agility or self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_jagged_blade:GetModifierEvasion_Constant()
    return self.evasion or self:GetAbility():GetLevelSpecialValueFor("bonus_evasion", (self:GetAbility():GetLevel() - 1))
end