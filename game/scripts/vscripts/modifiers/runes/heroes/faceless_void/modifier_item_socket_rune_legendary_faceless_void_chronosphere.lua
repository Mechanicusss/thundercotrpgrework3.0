LinkLuaModifier("modifier_item_socket_rune_legendary_faceless_void_chronosphere", "modifiers/runes/heroes/faceless_void/modifier_item_socket_rune_legendary_faceless_void_chronosphere", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_faceless_void_chronosphere = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_faceless_void_chronosphere:OnCreated()
    self.damageIncrease = 60
end