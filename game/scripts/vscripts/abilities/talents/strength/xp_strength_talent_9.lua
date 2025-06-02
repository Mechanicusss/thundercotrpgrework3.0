LinkLuaModifier("modifier_xp_strength_talent_9", "abilities/talents/strength/xp_strength_talent_9", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_strength_talent_9_buff", "abilities/talents/strength/xp_strength_talent_9", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_strength_talent_9 = class(ItemBaseClass)
modifier_xp_strength_talent_9 = class(xp_strength_talent_9)
modifier_xp_strength_talent_9_buff = class(ItemBaseClassBuff)
-------------
function xp_strength_talent_9:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_9"
end
-------------
function modifier_xp_strength_talent_9:OnCreated()
end

function modifier_xp_strength_talent_9:OnDestroy()
end

function modifier_xp_strength_talent_9:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_MODIFIER_ADDED   
    }
end

function modifier_xp_strength_talent_9:OnModifierAdded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    local mod = event.added_buff

    if not mod then return end 

    if not mod:IsDebuff() then return end 

    local caster = mod:GetCaster()

    if caster == parent or caster:GetTeam() == parent:GetTeam() then return end 

    if not IsCreepTCOTRPG(caster) and not IsBossTCOTRPG(caster) then return end 

    if not RollPercentage(3.5 * self:GetStackCount()) then return end

    mod:Destroy()

    local buff = parent:FindModifierByName("modifier_xp_strength_talent_9_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, nil, "modifier_xp_strength_talent_9_buff", {
            duration = 10
        })
    end

    if buff then
        buff:ForceRefresh()
    end
end
------------
function modifier_xp_strength_talent_9_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE 
    }
end

function modifier_xp_strength_talent_9_buff:GetModifierHealthRegenPercentage()
    return 1
end