LinkLuaModifier("modifier_xp_strength_talent_11", "abilities/talents/strength/xp_strength_talent_11", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_strength_talent_11_buff", "abilities/talents/strength/xp_strength_talent_11", LUA_MODIFIER_MOTION_NONE)

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

xp_strength_talent_11 = class(ItemBaseClass)
modifier_xp_strength_talent_11 = class(xp_strength_talent_11)
modifier_xp_strength_talent_11_buff = class(ItemBaseClassBuff)
-------------
function xp_strength_talent_11:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_11"
end
-------------
function modifier_xp_strength_talent_11:OnCreated()
end

function modifier_xp_strength_talent_11:OnDestroy()
end

function modifier_xp_strength_talent_11:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH  
    }
end

function modifier_xp_strength_talent_11:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    local victim = event.unit 

    if not IsCreepTCOTRPG(victim) and IsBossTCOTRPG(victim) then return end 

    local buff = parent:FindModifierByName("modifier_xp_strength_talent_11_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, nil, "modifier_xp_strength_talent_11_buff", {
            duration = 15
        })
    end

    if buff then
        if buff:GetStackCount() < 3 then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end
------------
function modifier_xp_strength_talent_11_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET 
    }
end

function modifier_xp_strength_talent_11_buff:GetModifierTotalDamageOutgoing_Percentage()
    return 2 * self:GetStackCount()
end

function modifier_xp_strength_talent_11_buff:GetModifierHealAmplify_PercentageTarget()
    return 2 * self:GetStackCount()
end