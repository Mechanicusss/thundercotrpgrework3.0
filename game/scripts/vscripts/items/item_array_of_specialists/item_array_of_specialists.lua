LinkLuaModifier("modifier_item_array_of_specialists", "items/item_array_of_specialists/item_array_of_specialists", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_array_of_specialists = class(ItemBaseClass)
modifier_item_array_of_specialists = class(item_array_of_specialists)
-------------
function item_array_of_specialists:GetIntrinsicModifierName()
    return "modifier_item_array_of_specialists"
end
-------------
function modifier_item_array_of_specialists:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_array_of_specialists:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_array_of_specialists:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_array_of_specialists:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_array_of_specialists:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end

function modifier_item_array_of_specialists:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(0.1)
end

function modifier_item_array_of_specialists:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    if not parent:IsAlive() or parent:IsIllusion() then return end

    if not parent:IsRangedAttacker() then return end 
    
    local enemies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            parent:Script_GetAttackRange()+50, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
            FIND_CLOSEST, false)

    if #enemies < 1 then return end

    for _,enemy in ipairs(enemies) do
        if enemy ~= nil and not enemy:IsNull() and enemy:IsAlive() then
            parent:PerformAttack(enemy, true, true, true, false, true, false, false)
            break
        end
    end

    ability:UseResources(false, false, false, true)
end