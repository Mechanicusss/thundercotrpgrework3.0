LinkLuaModifier("modifier_item_refreshing_spring_water", "items/item_refreshing_spring_water/item_refreshing_spring_water", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_refreshing_spring_water_buff", "items/item_refreshing_spring_water/item_refreshing_spring_water", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

item_refreshing_spring_water = class(ItemBaseClass)
modifier_item_refreshing_spring_water = class(item_refreshing_spring_water)
modifier_item_refreshing_spring_water_buff = class(ItemBaseClassBuff)
-------------
function item_refreshing_spring_water:GetIntrinsicModifierName()
    return "modifier_item_refreshing_spring_water"
end

function item_refreshing_spring_water:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_item_refreshing_spring_water_buff", {
        duration = 300
    })

    caster:RemoveItem(self)
end

function modifier_item_refreshing_spring_water_buff:GetTexture()
    return "refreshing_spring_water"
end