LinkLuaModifier("modifier_xp_agility_talent_10", "abilities/talents/agility/xp_agility_talent_10", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_agility_talent_10_debuff", "abilities/talents/agility/xp_agility_talent_10", LUA_MODIFIER_MOTION_NONE)

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

xp_agility_talent_10 = class(ItemBaseClass)
modifier_xp_agility_talent_10 = class(xp_agility_talent_10)
modifier_xp_agility_talent_10_debuff = class(ItemBaseClassDebuff)
-------------
function xp_agility_talent_10:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_10"
end
-------------
function modifier_xp_agility_talent_10:OnCreated()
end

function modifier_xp_agility_talent_10:OnDestroy()
end

function modifier_xp_agility_talent_10:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_xp_agility_talent_10:OnAttackLanded(event)
    if not IsServer() then return end

	local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if parent:IsRangedAttacker() then return end
	if parent:IsIllusion() then return end 
    if not parent:IsRealHero() then return end 

    local debuff = target:FindModifierByName("modifier_xp_agility_talent_10_debuff")
    if not debuff then
        debuff = target:AddNewModifier(parent, nil, "modifier_xp_agility_talent_10_debuff", {
            duration = 3,
            damage = event.damage * ((5/100) * self:GetStackCount())
        })
    end

    if debuff then
        if debuff:GetStackCount() < 3 then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end
end
------------
function modifier_xp_agility_talent_10_debuff:OnCreated(params)
    if not IsServer() then return end 

    self.damage = params.damage

    self:StartIntervalThink(1)
end

function modifier_xp_agility_talent_10_debuff:OnIntervalThink()
    ApplyDamage({
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage = self.damage * self:GetStackCount(),
        damage_type = DAMAGE_TYPE_PHYSICAL
    })
end