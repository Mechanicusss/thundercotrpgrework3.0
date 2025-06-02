LinkLuaModifier("modifier_xp_agility_talent_4", "abilities/talents/agility/xp_agility_talent_4", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_agility_talent_4_haste", "abilities/talents/agility/xp_agility_talent_4", LUA_MODIFIER_MOTION_NONE)

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

xp_agility_talent_4 = class(ItemBaseClass)
modifier_xp_agility_talent_4 = class(xp_agility_talent_4)
modifier_xp_agility_talent_4_haste = class(ItemBaseClassBuff)
-------------
function xp_agility_talent_4:GetIntrinsicModifierName()
    return "modifier_xp_agility_talent_4"
end
-------------
function modifier_xp_agility_talent_4:OnCreated()
    if not IsServer() then return end

    self.isCooldown = false
end

function modifier_xp_agility_talent_4:OnRemoved()
    if not IsServer() then return end
	if (self:GetParent():FindModifierByName("modifier_xp_agility_talent_4_haste")) then
		self:GetParent():FindModifierByName("modifier_xp_agility_talent_4_haste"):Destroy()
	end
end

function modifier_xp_agility_talent_4:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK   
    }
end

function modifier_xp_agility_talent_4:OnAttack(event)
    if not IsServer() then return end

	local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if parent:IsRangedAttacker() then return end
	if parent:IsIllusion() then return end 
    if not parent:IsRealHero() then return end 

    local cooldown = 30 - (2 * self:GetStackCount())
    
    if not self.isCooldown then
        parent:AddNewModifier(parent, nil, "modifier_xp_agility_talent_4_haste", {})

        self.isCooldown = true

        Timers:CreateTimer(cooldown, function()
            self.isCooldown = false
        end)
    end

    local mod = parent:FindModifierByName("modifier_xp_agility_talent_4_haste")
    if mod ~= nil then
        mod:DecrementStackCount()
        if mod:GetStackCount() < 1 then
            mod:Destroy()
        end
    end
end
----------------
function modifier_xp_agility_talent_4_haste:OnCreated()
    if not IsServer() then return end 

	self.parent = self:GetParent()
	
    local current_speed = self.parent:GetIncreasedAttackSpeed()
		
    current_speed = current_speed * 2
    
    self.max_hits = 3

    self:SetStackCount(self.max_hits)
    
    self.attack_speed_buff = math.max(400, current_speed)
end

function modifier_xp_agility_talent_4_haste:OnRefresh()
	self:OnCreated()
end

function modifier_xp_agility_talent_4_haste:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
	}
end

function modifier_xp_agility_talent_4_haste:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed_buff
end

function modifier_xp_agility_talent_4_haste:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end 
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end 

    local bonus = 2 * (self.max_hits - self:GetStackCount() + 1)

    return bonus
end