LinkLuaModifier("modifier_hero_the_entity_shuffle", "heroes/hero_the_entity/hero_the_entity_shuffle", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

hero_the_entity_shuffle = class(ItemBaseClass)
modifier_hero_the_entity_shuffle = class(hero_the_entity_shuffle)
-------------
function hero_the_entity_shuffle:GetIntrinsicModifierName()
    return "modifier_hero_the_entity_shuffle"
end

function hero_the_entity_shuffle:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddItemByName("item_entity_book")
end

