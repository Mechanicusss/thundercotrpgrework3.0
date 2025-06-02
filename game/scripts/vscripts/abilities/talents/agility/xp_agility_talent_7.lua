LinkLuaModifier("modifier_xp_agility_talent_7", "abilities/talents/agility/xp_agility_talent_7", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_agility_talent_7_debuff", "abilities/talents/agility/xp_agility_talent_7", LUA_MODIFIER_MOTION_NONE)

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

xp_agility_talent_7 = class(ItemBaseClass)
modifier_xp_agility_talent_7 = class(xp_agility_talent_7)
modifier_xp_agility_talent_7_debuff = class(ItemBaseClassDebuff)
-------------
function xp_agility_talent_7:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_7"
end
-------------
function modifier_xp_agility_talent_7:OnCreated()
    if not IsServer() then return end 

    self.attacks = 0
    self.requiredAttacks = 3
end

function modifier_xp_agility_talent_7:OnDestroy()
end

function modifier_xp_agility_talent_7:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY 
    }
end

function modifier_xp_agility_talent_7:OnAttackRecordDestroy(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target

    if target:HasModifier("modifier_xp_agility_talent_7_debuff") then
        target:RemoveModifierByName("modifier_xp_agility_talent_7_debuff")
    end
end

function modifier_xp_agility_talent_7:OnAttack(event)
    if not IsServer() then return end

	local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if parent:IsRangedAttacker() then return end
	if parent:IsIllusion() then return end 
    if not parent:IsRealHero() then return end 
    
    self.attacks = self.attacks + 1

    if self.attacks >= self.requiredAttacks then
        self.attacks = 0

        target:AddNewModifier(parent, nil, "modifier_xp_agility_talent_7_debuff", {
            duration = 0.5
        })
    end
end
-----------
function modifier_xp_agility_talent_7_debuff:DeclareFunctions()
	local funcs = {
		-- MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE, -- for base armor only
		MODIFIER_PROPERTY_IGNORE_PHYSICAL_ARMOR, -- for all armor
	}

	return funcs
end

function modifier_xp_agility_talent_7_debuff:GetModifierIgnorePhysicalArmor()
	if not IsServer() then return end
    if self:GetParent():IsRangedAttacker() then return end
	-- strip base armor
	return 1
end

function modifier_xp_agility_talent_7_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE 
end