LinkLuaModifier("modifier_item_socket_rune_legendary_faceless_void_time_lock", "modifiers/runes/heroes/faceless_void/modifier_item_socket_rune_legendary_faceless_void_time_lock", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_faceless_void_time_lock = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_faceless_void_time_lock:OnCreated()
    self.chronosphereRadius = 400
    self.chronosphereDuration = 1
    self.chronosphereCooldown = 3

    self.cooldownReady = true
end