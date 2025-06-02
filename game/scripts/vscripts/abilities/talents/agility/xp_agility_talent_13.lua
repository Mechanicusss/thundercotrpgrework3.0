LinkLuaModifier("modifier_xp_agility_talent_13", "abilities/talents/agility/xp_agility_talent_13", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_agility_talent_13_debuff", "abilities/talents/agility/xp_agility_talent_13", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_agility_talent_13 = class(ItemBaseClass)
modifier_xp_agility_talent_13 = class(xp_agility_talent_13)
modifier_xp_agility_talent_13_debuff = class(ItemBaseClassDebuff)
-------------
function xp_agility_talent_13:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_13"
end
-------------
function modifier_xp_agility_talent_13:OnCreated()
end

function modifier_xp_agility_talent_13:OnDestroy()
end

function modifier_xp_agility_talent_13:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_xp_agility_talent_13:OnAttackLanded(event)
    if not IsServer() then return end

	local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if parent:IsRangedAttacker() then return end
	if parent:IsIllusion() then return end 
    if not parent:IsRealHero() then return end 

    local debuff = target:FindModifierByName("modifier_xp_agility_talent_13_debuff")
    if not debuff then
        debuff = target:AddNewModifier(parent, nil, "modifier_xp_agility_talent_13_debuff", {
            duration = 3
        })
    end

    if debuff then
        debuff:ForceRefresh()
    end
end
------------
function modifier_xp_agility_talent_13_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_xp_agility_talent_13_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -4 * (self:GetStackCount())
end