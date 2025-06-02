modifier_saitama_limiter = class({
	IsPurgable    = function() return false end,
	RemoveOnDeath = function() return false end,
	GetTexture    = function() return "arena/modifier_saitama_limiter" end,
})

function modifier_saitama_limiter:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
		MODIFIER_PROPERTY_ATTACK_POINT_CONSTANT,
	}
end

local FRACTION_700 = 1/7

function modifier_saitama_limiter:OnCreated()
	self.BaseBAT = self:GetCaster():GetBaseAttackTime()
	self.BATMod = 1
end

function modifier_saitama_limiter:GetModifierBaseAttackTimeConstant()
	local AS = self:GetCaster():GetIncreasedAttackSpeed(true)
	if AS > 7 then
		local BATMod = (7 / AS)
		self.BATMod = BATMod
		return self.BaseBAT * BATMod
	end
end

function modifier_saitama_limiter:GetModifierAttackPointConstant()
	return 0.75 * self.BATMod --0.75 is the base attack point
end

if IsServer() then
	function modifier_saitama_limiter:OnDeath(keys)
		local caster = self:GetCaster()
		local ability = caster:FindAbilityByName("saitama_limiter")
		local level = ability and math.max(ability:GetLevel(), 1) or 1
		if keys.unit == caster then
			self:SetStackCount(math.ceil(self:GetStackCount() * (1 - ability:GetSpecialValueFor("loss_stacks_pct") * 0.01)))
		elseif (
			keys.attacker == caster and
			(IsCreepTCOTRPG(keys.unit) or IsBossTCOTRPG(keys.unit)) and
			caster:GetTeamNumber() ~= keys.unit:GetTeamNumber()
		) then
			self:SetStackCount(self:GetStackCount() + ability:GetSpecialValueFor("stacks_for_kill"))
		end
	end
end
