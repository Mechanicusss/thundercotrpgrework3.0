LinkLuaModifier("modifier_item_akasha_conversion", "heroes/bosses/akasha/item_akasha_conversion", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_akasha_conversion = class(ItemBaseClass)
modifier_item_akasha_conversion = class(item_akasha_conversion)
-------------
function item_akasha_conversion:GetIntrinsicModifierName()
    return "modifier_item_akasha_conversion"
end

function item_akasha_conversion:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    SwapHeroWithTCOTRPG(caster, "npc_dota_hero_queenofpain", "npc_dota_hero_arena_hero_wearable_dummy_akasha")

    caster:RemoveItem(self)
end
