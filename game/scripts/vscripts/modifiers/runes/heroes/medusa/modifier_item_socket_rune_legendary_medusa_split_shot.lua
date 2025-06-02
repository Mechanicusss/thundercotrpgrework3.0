LinkLuaModifier("modifier_item_socket_rune_legendary_medusa_split_shot", "modifiers/runes/heroes/medusa/modifier_item_socket_rune_legendary_medusa_split_shot", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_medusa_split_shot = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_medusa_split_shot:OnCreated()
end