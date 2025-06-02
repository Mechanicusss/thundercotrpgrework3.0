LinkLuaModifier("modifier_item_socket_rune_legendary_axe_counter_helix", "modifiers/runes/heroes/axe/modifier_item_socket_rune_legendary_axe_counter_helix", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_axe_counter_helix = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_axe_counter_helix:OnCreated()
    self.manaPerSec = 5
    self.interval = 0.25
end