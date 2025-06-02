LinkLuaModifier("modifier_hero_the_entity_change_primary", "heroes/hero_the_entity/hero_the_entity_change_primary", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

hero_the_entity_change_primary = class(ItemBaseClass)
modifier_hero_the_entity_change_primary = class(hero_the_entity_change_primary)

THE_ENTITY_SELECTED_ATTRIBUTE = DOTA_ATTRIBUTE_INTELLECT
-------------
function hero_the_entity_change_primary:GetIntrinsicModifierName()
    return "modifier_hero_the_entity_change_primary"
end

function hero_the_entity_change_primary:GetAbilityTextureName()
    if self:GetTheEntityAttribute() == DOTA_ATTRIBUTE_INTELLECT then
        return "entityint"
    end

    if self:GetTheEntityAttribute() == DOTA_ATTRIBUTE_STRENGTH then
        return "entitystr"
    end

    if self:GetTheEntityAttribute() == DOTA_ATTRIBUTE_AGILITY then
        return "entityagi"
    end
end

function hero_the_entity_change_primary:GetTheEntityAttribute()
    return THE_ENTITY_SELECTED_ATTRIBUTE
end

function hero_the_entity_change_primary:OnSpellStart()
    if THE_ENTITY_SELECTED_ATTRIBUTE == DOTA_ATTRIBUTE_STRENGTH then
        THE_ENTITY_SELECTED_ATTRIBUTE = DOTA_ATTRIBUTE_AGILITY
    elseif THE_ENTITY_SELECTED_ATTRIBUTE == DOTA_ATTRIBUTE_AGILITY then
        THE_ENTITY_SELECTED_ATTRIBUTE = DOTA_ATTRIBUTE_INTELLECT
    elseif THE_ENTITY_SELECTED_ATTRIBUTE == DOTA_ATTRIBUTE_INTELLECT then
        THE_ENTITY_SELECTED_ATTRIBUTE = DOTA_ATTRIBUTE_STRENGTH
    end

    if not IsServer() then return end

    local caster = self:GetCaster()

    local primaryAttribute = caster:GetPrimaryAttribute()

    if primaryAttribute == DOTA_ATTRIBUTE_STRENGTH then
        primaryAttribute = DOTA_ATTRIBUTE_AGILITY
    elseif primaryAttribute == DOTA_ATTRIBUTE_AGILITY then
        primaryAttribute = DOTA_ATTRIBUTE_INTELLECT
    elseif primaryAttribute == DOTA_ATTRIBUTE_INTELLECT then
        primaryAttribute = DOTA_ATTRIBUTE_STRENGTH
    end

    caster:SetPrimaryAttribute(primaryAttribute)
end

