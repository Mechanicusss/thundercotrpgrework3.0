LinkLuaModifier("modifier_item_socket_rune_legendary_lina_light_strike_array", "modifiers/runes/heroes/lina/modifier_item_socket_rune_legendary_lina_light_strike_array", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_lina_light_strike_array = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_lina_light_strike_array:OnCreated()
    self.stunDuration = 2
    self.stunChance = 20
end