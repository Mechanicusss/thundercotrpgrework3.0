LinkLuaModifier("modifier_mercure", "mercure", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mercure_boost", "mercure", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBoost = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return true end,
}

item_mercure = class(ItemBaseClass)
item_mercure2 = item_mercure
item_mercure3 = item_mercure
item_mercure4 = item_mercure
item_mercure5 = item_mercure
item_mercure6 = item_mercure
item_mercure7 = item_mercure
item_mercure8 = item_mercure
modifier_mercure = class(item_mercure)
modifier_mercure_boost = class(ItemBaseClassBoost)

function modifier_mercure_boost:GetTexture()
    return "mercure"
end
-------------
function item_mercure:GetIntrinsicModifierName()
    return "modifier_mercure"
end
------------
function modifier_mercure_boost:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_mercure_boost:OnCreated()
    if not IsServer() then return end
    self.agility = self:GetParent():GetBaseAgility()
end

function modifier_mercure_boost:OnRefresh()
    if not IsServer() then return end
    self.agility = self:GetParent():GetBaseAgility()
end

function modifier_mercure_boost:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
    }

    return funcs
end

function modifier_mercure_boost:GetModifierBonusStats_Agility()
    if IsServer() and self.agility then
        if not self:GetCaster():HasItemInInventory(self:GetAbility():GetAbilityName()) then
            if self:GetCaster():HasModifier("modifier_mercure_boost") then
                self:GetCaster():RemoveModifierByNameAndCaster("modifier_mercure_boost", self:GetCaster())
            end
            return
        end
        
        local amount = (self.agility * (self:GetAbility():GetSpecialValueFor("boost_agility_pct")/100)) * self:GetStackCount()
        local limit = 2147483647

        if amount > limit or amount < 0 then
            amount = limit
        end

        return amount
    end
end
-----------
function modifier_mercure:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_EVASION_CONSTANT, --GetModifierEvasion_Constant
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_mercure:OnCreated()
    if not IsServer() then return end

    --self:StartIntervalThink(0.1)
end

function modifier_mercure:OnIntervalThink()
    local caster = self:GetCaster()

    if caster:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_AGILITY then
        caster:DropItemAtPositionImmediate(self:GetAbility(), caster:GetAbsOrigin())
        DisplayError(caster:GetPlayerID(), "#primary_agility_item")
    end

    self:StartIntervalThink(-1)
end

function modifier_mercure:OnRemove()
    if not IsServer() then return end

    local parent = self:GetParent()
    parent:RemoveModifierByNameAndCaster("modifier_mercure_boost", parent)
end

function modifier_mercure:OnAttack(event)
    if event.attacker ~= self:GetParent() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not RollPercentage(ability:GetSpecialValueFor("boost_chance")) then return end

    local buff = parent:FindModifierByNameAndCaster("modifier_mercure_boost", parent)
    local stacks = parent:GetModifierStackCount("modifier_mercure_boost", parent)
    
    if not buff then
        parent:AddNewModifier(parent, ability, "modifier_mercure_boost", { duration = ability:GetSpecialValueFor("boost_duration") })
    end

    if stacks < ability:GetSpecialValueFor("boost_max_stacks") then
        parent:SetModifierStackCount("modifier_mercure_boost", parent, (stacks + 1))
    end

    if buff ~= nil then
        buff:ForceRefresh()
    end
end

function modifier_mercure:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1)) + (self:GetParent():GetAgility() * (self:GetAbility():GetSpecialValueFor("agi_dmg")))
end

function modifier_mercure:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_mercure:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("movement_speed_percent_bonus", (self:GetAbility():GetLevel() - 1))
end

function modifier_mercure:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_mercure:GetModifierEvasion_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_evasion", (self:GetAbility():GetLevel() - 1))
end