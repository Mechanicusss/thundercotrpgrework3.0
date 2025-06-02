LinkLuaModifier("modifier_player_difficulty_boon_weapon_destruction_30", "modifiers/modes/buffs/impossible/modifier_player_difficulty_boon_weapon_destruction_30", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_weapon_destruction_30 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_weapon_destruction_30 = class(ItemBaseClass)

function player_difficulty_boon_weapon_destruction_30:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_weapon_destruction_30"
end

function modifier_player_difficulty_boon_weapon_destruction_30:GetTexture() return "arena/apocalypse_weapon_break" end

function modifier_player_difficulty_boon_weapon_destruction_30:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
    }

    return funcs
end

function modifier_player_difficulty_boon_weapon_destruction_30:OnDeath(event)
    if event.unit ~= self:GetParent() then return end

    local parent = self:GetParent()
    local randomSlot = RandomInt(0, 6)
    local item = parent:GetItemInSlot(randomSlot)
    if item ~= nil then
        if RollPercentage(30) then
            parent:RemoveItem(item)
        end
    end
end
-------------