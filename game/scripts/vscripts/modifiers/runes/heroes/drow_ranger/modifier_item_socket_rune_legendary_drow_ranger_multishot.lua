LinkLuaModifier("modifier_item_socket_rune_legendary_drow_ranger_multishot", "modifiers/runes/heroes/drow_ranger/modifier_item_socket_rune_legendary_drow_ranger_multishot", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_drow_ranger_multishot = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_drow_ranger_multishot:OnCreated()
    self.arrowCount = 2
    self.damageIncrease = 150
    self.duration = 4
    self.increasePct = 60
    self.intervalDecrease = -0.35
end