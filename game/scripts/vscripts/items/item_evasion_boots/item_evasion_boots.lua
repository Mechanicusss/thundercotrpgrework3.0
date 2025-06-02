LinkLuaModifier("modifier_item_evasion_boots", "items/item_evasion_boots/item_evasion_boots", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_evasion_boots = class(ItemBaseClass)
modifier_item_evasion_boots = class(item_evasion_boots)
-------------
function item_evasion_boots:GetIntrinsicModifierName()
    return "modifier_item_evasion_boots"
end

function modifier_item_evasion_boots:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_IGNORE_PHYSICAL_ARMOR,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_item_evasion_boots:GetModifierIgnorePhysicalArmor()
    return 1
end

function modifier_item_evasion_boots:GetModifierIncomingDamage_Percentage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker:GetTeam() == parent:GetTeam() then return end 
    if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then return end 
    
    if not IsCreepTCOTRPG(event.attacker) and not IsBossTCOTRPG(event.attacker) then return end

    local agility = parent:GetAgility()
    local strength = parent:GetStrength()
    local intellect = parent:GetBaseIntellect()

    if agility < strength or agility < intellect then return end

    local evasion = (parent:GetEvasion() * 100)

    if evasion >= 100 then
        evasion = 99
    end

    if not RollPercentage(evasion) then return end 

    return -9999
end
