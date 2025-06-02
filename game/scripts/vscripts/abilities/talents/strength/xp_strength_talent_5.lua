LinkLuaModifier("modifier_xp_strength_talent_5", "abilities/talents/strength/xp_strength_talent_5", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_strength_talent_5_debuff", "abilities/talents/strength/xp_strength_talent_5", LUA_MODIFIER_MOTION_NONE)

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

xp_strength_talent_5 = class(ItemBaseClass)
modifier_xp_strength_talent_5 = class(xp_strength_talent_5)
modifier_xp_strength_talent_5_debuff = class(ItemBaseClassBuff)
-------------
function xp_strength_talent_5:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_5"
end
-------------
function modifier_xp_strength_talent_5:OnCreated()
end

function modifier_xp_strength_talent_5:OnDestroy()
end

function modifier_xp_strength_talent_5:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_xp_strength_talent_5:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local debuff = target:FindModifierByName("modifier_xp_strength_talent_5_debuff")
    if not debuff then
        debuff = target:AddNewModifier(parent, nil, "modifier_xp_strength_talent_5_debuff", {
            duration = 3
        })
    end

    if debuff then
        if debuff:GetStackCount() < 3 then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end
end
-----------------
function modifier_xp_strength_talent_5_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE 
    }
end

function modifier_xp_strength_talent_5_debuff:GetModifierIncomingPhysicalDamage_Percentage()
    if IsServer() then
        local parent = self:GetParent()
        local mod = parent:FindModifierByName("modifier_xp_strength_talent_5")
        if mod then
            return 1.5 * mod:GetStackCount()
        end
    end
end