LinkLuaModifier("modifier_xp_agility_talent_12", "abilities/talents/agility/xp_agility_talent_12", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_agility_talent_12_buff", "abilities/talents/agility/xp_agility_talent_12", LUA_MODIFIER_MOTION_NONE)

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

xp_agility_talent_12 = class(ItemBaseClass)
modifier_xp_agility_talent_12 = class(xp_agility_talent_12)
modifier_xp_agility_talent_12_buff = class(ItemBaseClassBuff)
-------------
function xp_agility_talent_12:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_12"
end
-------------
function modifier_xp_agility_talent_12:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(FrameTime())
end

function modifier_xp_agility_talent_12:OnIntervalThink()
    local parent = self:GetParent()
    if parent:IsMoving() then
        if not parent:HasModifier("modifier_xp_agility_talent_12_buff") then
            local mod = parent:AddNewModifier(parent, nil, "modifier_xp_agility_talent_12_buff", {
                duration = 3
            })

            if mod ~= nil then
                mod:SetStackCount(self:GetStackCount())
            end
        end
    end
end

function modifier_xp_agility_talent_12:OnDestroy()
end
----------
function modifier_xp_agility_talent_12_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EVASION_CONSTANT    
    }
end

function modifier_xp_agility_talent_12_buff:GetModifierEvasion_Constant()
    return 6 * self:GetStackCount()
end

function modifier_xp_agility_talent_12_buff:CheckState()
    return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end