LinkLuaModifier("modifier_item_carl_conversion", "heroes/hero_carl/item_carl_conversion/item_carl_conversion", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_carl_conversion = class(ItemBaseClass)
modifier_item_carl_conversion = class(item_carl_conversion)
-------------
function item_carl_conversion:GetIntrinsicModifierName()
    return "modifier_item_carl_conversion"
end

function item_carl_conversion:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    SwapHeroWithTCOTRPG(caster, "npc_dota_hero_invoker", "npc_dota_hero_arena_hero_wearable_dummy_carl")

    caster:RemoveItem(self)
end
