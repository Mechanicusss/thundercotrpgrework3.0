LinkLuaModifier("modifier_chicken_ability_6", "heroes/chicken/chicken_ability_6.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chicken_ability_6_buff", "heroes/chicken/chicken_ability_6.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

chicken_ability_6 = class(ItemBaseClass)
modifier_chicken_ability_6 = class(chicken_ability_6)

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_chicken_ability_6_buff = class(ItemBaseClassBuff)
-------------
function chicken_ability_6:GetIntrinsicModifierName()
    return "modifier_chicken_ability_6"
end

function modifier_chicken_ability_6:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:AddNewModifier(parent, self:GetAbility(), "modifier_chicken_ability_6_buff", {})
end


function modifier_chicken_ability_6_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_REINCARNATION,
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_chicken_ability_6_buff:OnDeath(event)
    if not IsServer() then return end
    if event.unit ~= self:GetParent() then return end

    if not event.unit:HasModifier("modifier_chicken_ability_1_self_transmute") then return end

    local ability = self:GetAbility()

    ability:UseResources(false, false, false, true)
end


function modifier_chicken_ability_6_buff:ReincarnateTime()
    if not self:GetAbility() or self:GetAbility() == nil then return end
    
    if not self:GetParent():HasModifier("modifier_chicken_ability_1_self_transmute") then return end
    if not self:GetAbility():IsCooldownReady() then return end

    return 5
end
