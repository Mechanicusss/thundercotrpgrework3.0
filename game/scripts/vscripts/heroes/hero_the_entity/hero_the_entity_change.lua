LinkLuaModifier("modifier_hero_the_entity_change", "heroes/hero_the_entity/hero_the_entity_change", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

hero_the_entity_change = class(ItemBaseClass)
modifier_hero_the_entity_change = class(hero_the_entity_change)
-------------
function hero_the_entity_change:GetIntrinsicModifierName()
    return "modifier_hero_the_entity_change"
end

function hero_the_entity_change:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddItemByName("item_entity_book_change")
end

