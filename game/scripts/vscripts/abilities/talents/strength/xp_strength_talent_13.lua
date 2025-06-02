LinkLuaModifier("modifier_xp_strength_talent_13", "abilities/talents/strength/xp_strength_talent_13", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_strength_talent_13_buff", "abilities/talents/strength/xp_strength_talent_13", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_strength_talent_13_cd", "abilities/talents/strength/xp_strength_talent_13", LUA_MODIFIER_MOTION_NONE)

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

xp_strength_talent_13 = class(ItemBaseClass)
modifier_xp_strength_talent_13 = class(xp_strength_talent_13)
modifier_xp_strength_talent_13_buff = class(ItemBaseClassBuff)
modifier_xp_strength_talent_13_cd = class(ItemBaseClassBuff)
-------------
function xp_strength_talent_13:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_13"
end
-------------
function modifier_xp_strength_talent_13:OnCreated()
end

function modifier_xp_strength_talent_13:OnDestroy()
end

function modifier_xp_strength_talent_13:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_xp_strength_talent_13:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.target or parent == event.attacker then return end 

    local attacker = event.attacker 

    if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end 

    if parent:HasModifier("modifier_xp_strength_talent_13_cd") then return end

    local buff = parent:FindModifierByName("modifier_xp_strength_talent_13_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, nil, "modifier_xp_strength_talent_13_buff", {
            duration = 3
        })
    end

    if buff then
        buff:SetStackCount(self:GetStackCount())
        buff:ForceRefresh()
    end
end
-----------------
function modifier_xp_strength_talent_13_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE  
    }
end

function modifier_xp_strength_talent_13_buff:GetModifierDamageOutgoing_Percentage()
    return 2 * self:GetStackCount()
end

function modifier_xp_strength_talent_13_buff:OnDestroy()
    if not IsServer() then return end 

    self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_xp_strength_talent_13_cd", {
        duration = 10
    })
end