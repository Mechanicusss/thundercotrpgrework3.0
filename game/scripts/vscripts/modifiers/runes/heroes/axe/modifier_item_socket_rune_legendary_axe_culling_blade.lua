LinkLuaModifier("modifier_item_socket_rune_legendary_axe_culling_blade", "modifiers/runes/heroes/axe/modifier_item_socket_rune_legendary_axe_culling_blade", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_axe_culling_blade = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_axe_culling_blade:OnCreated()
    self.radius = 300
    self.executeChance = 24
    self.executeThreshold = 50
end