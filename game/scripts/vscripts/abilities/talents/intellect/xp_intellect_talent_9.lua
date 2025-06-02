LinkLuaModifier("modifier_xp_intellect_talent_9", "abilities/talents/intellect/xp_intellect_talent_9", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_9 = class(ItemBaseClass)
modifier_xp_intellect_talent_9 = class(xp_intellect_talent_9)
-------------
function xp_intellect_talent_9:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_9"
end
-------------
function modifier_xp_intellect_talent_9:OnCreated()
end

function modifier_xp_intellect_talent_9:OnDestroy()
end

function modifier_xp_intellect_talent_9:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST 
    }
end

function modifier_xp_intellect_talent_9:OnAbilityFullyCast(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.unit ~= parent then return end 

    local inflictor = event.ability 
    if not inflictor then return end

    if not RollPercentage(15) then return end

    local manaCost = inflictor:GetEffectiveManaCost(inflictor:GetLevel())
    if manaCost < 1 then return end

    manaCost = manaCost * ((20*self:GetStackCount())/100)
    parent:GiveMana(manaCost)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, parent, manaCost, nil)
end