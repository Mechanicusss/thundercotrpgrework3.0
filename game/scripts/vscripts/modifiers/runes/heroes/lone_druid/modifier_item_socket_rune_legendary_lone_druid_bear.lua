LinkLuaModifier("modifier_item_socket_rune_legendary_lone_druid_bear", "modifiers/runes/heroes/lone_druid/modifier_item_socket_rune_legendary_lone_druid_bear", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_lone_druid_bear = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_lone_druid_bear:OnCreated()
    
end