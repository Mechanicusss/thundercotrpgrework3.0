LinkLuaModifier("modifier_extra_life_buff", "items/extra_life/item_extra_life", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

item_extra_life = class(ItemBaseClass)
modifier_extra_life_buff = class(ItemBaseClassBuff)
-------------
function item_extra_life:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if not caster:HasModifier("modifier_limited_lives") then
        DisplayError(player:GetPlayerID(), "Cannot Be Used On This Difficulty.")
    else
        local lives = caster:FindModifierByName("modifier_limited_lives")
        if lives ~= nil then
            lives:IncrementStackCount()
        end
    end

    caster:RemoveItem(self)
end