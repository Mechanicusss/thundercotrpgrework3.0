local _base_gun_modifier = _base_gun_modifier or {}

local mod = _base_gun_modifier

function mod:IsHidden() 		return true end
function mod:IsPurgable() 		return false end
function mod:DestroyOnExpire() 	return false end
function mod:IsPurgeException() return false end

function mod:OnCreated( kv )
	if not self or self:IsNull() then return end

	local ability = self:GetAbility()

	if not ability or ability:IsNull() then return end

	self.bat 			= ability:GetSpecialValueFor(self.batName)
	self.damageModifier = ability:GetSpecialValueFor(self.damageModifierName)
	self.rangeBonus		= ability:GetSpecialValueFor(self.rangeBonusName)

	if not IsServer() then return end

	local name = self:GetName()
	local caster = self:GetCaster()

	--[[
	if name == "modifier_gun_joe_rifle" then
		local explosiveBullets = caster:FindAbilityByName("sniper_explosive_bullets_custom")
		local rapidMachinery = caster:FindAbilityByName("sniper_rapid_machinery_custom")
		local shrapnel = caster:FindAbilityByName("sniper_shrapnel_custom")

		-- Explosive Bullets/Armor Bullets
		local armorBullets = caster:FindAbilityByName("sniper_armor_bullets_custom")
		if not armorBullets then
			armorBullets = caster:AddAbility("sniper_armor_bullets_custom")
		end

		if armorBullets ~= nil and armorBullets:IsHidden() then
			caster:SwapAbilities(
				"sniper_explosive_bullets_custom",
				"sniper_armor_bullets_custom",
				false,
				true
			)

			armorBullets:SetActivated(true)
			armorBullets:SetHidden(false)

			if explosiveBullets:GetLevel() > armorBullets:GetLevel() then
				armorBullets:SetLevel(explosiveBullets:GetLevel())
			end

			if explosiveBullets ~= nil then
				explosiveBullets:SetActivated(false)
				explosiveBullets:SetHidden(true)
			end
		end

		-- Rapid Machinery/Take Aim
		local takeAim = caster:FindAbilityByName("sniper_take_aim_custom")
		if not takeAim then
			takeAim = caster:AddAbility("sniper_take_aim_custom")
		end

		if takeAim ~= nil and takeAim:IsHidden() then
			caster:SwapAbilities(
				"sniper_rapid_machinery_custom",
				"sniper_take_aim_custom",
				false,
				true
			)

			takeAim:SetActivated(true)
			takeAim:SetHidden(false)
			if rapidMachinery:GetLevel() > takeAim:GetLevel() then
				takeAim:SetLevel(rapidMachinery:GetLevel())
			end

			if rapidMachinery ~= nil then
				rapidMachinery:SetActivated(false)
				rapidMachinery:SetHidden(true)
			end
		end

		-- Ultimate
		local LongRangeAdvantage = caster:FindAbilityByName("sniper_long_range_advantage_custom")
		if not LongRangeAdvantage then
			LongRangeAdvantage = caster:AddAbility("sniper_long_range_advantage_custom")
		end

		if LongRangeAdvantage ~= nil and LongRangeAdvantage:IsHidden() then
			caster:SwapAbilities(
				"shrapnel",
				"sniper_long_range_advantage_custom",
				false,
				true
			)

			LongRangeAdvantage:SetActivated(true)
			LongRangeAdvantage:SetHidden(false)

			if shrapnel:GetLevel() > LongRangeAdvantage:GetLevel() then
				LongRangeAdvantage:SetLevel(shrapnel:GetLevel())
			end

			if shrapnel ~= nil then
				shrapnel:SetActivated(false)
				shrapnel:SetHidden(true)
			end
		end
	end
	--]]
end

function mod:OnRemoved()
	if not self or self:IsNull() then return end

	local ability = self:GetAbility()

	if not ability or ability:IsNull() then return end

	if not IsServer() then return end

	local caster = self:GetCaster()
	local name = self:GetName()

	--[[
	local explosiveBullets = caster:FindAbilityByName("sniper_explosive_bullets_custom")

	if name == "modifier_gun_joe_rifle" then
		local explosiveBullets = caster:FindAbilityByName("sniper_explosive_bullets_custom")
		local armorBullets = caster:FindAbilityByName("sniper_armor_bullets_custom")

		if explosiveBullets ~= nil and armorBullets ~= nil then
			if explosiveBullets:GetLevel() < armorBullets:GetLevel() then
				explosiveBullets:SetLevel(armorBullets:GetLevel())
			end
		end

		--------
		local takeAim = caster:FindAbilityByName("sniper_take_aim_custom")
		local rapidMachinery = caster:FindAbilityByName("sniper_rapid_machinery_custom")

		if takeAim ~= nil and rapidMachinery ~= nil then
			if rapidMachinery:GetLevel() < takeAim:GetLevel() then
				rapidMachinery:SetLevel(takeAim:GetLevel())
			end
		end

		--------
		local shrapnel = caster:FindAbilityByName("sniper_shrapnel_custom")
		local LongRangeAdvantage = caster:FindAbilityByName("sniper_long_range_advantage_custom")

		if shrapnel ~= nil and LongRangeAdvantage ~= nil then
			if shrapnel:GetLevel() < LongRangeAdvantage:GetLevel() then
				shrapnel:SetLevel(LongRangeAdvantage:GetLevel())
			end
		end
	end

	-- Reset the rifle abilities back to machine gun if they're present
	local armorBullets = caster:FindAbilityByName("sniper_armor_bullets_custom")
	if name == "modifier_gun_joe_rifle" and armorBullets ~= nil then
		caster:SwapAbilities(
			"sniper_explosive_bullets_custom",
			"sniper_armor_bullets_custom",
			true,
			false
		)

		armorBullets:SetActivated(false)
		armorBullets:SetHidden(true)

		explosiveBullets:SetActivated(true)
		explosiveBullets:SetHidden(false)
	end

	local rapidMachinery = caster:FindAbilityByName("sniper_rapid_machinery_custom")
	local takeAim = caster:FindAbilityByName("sniper_take_aim_custom")
	if name == "modifier_gun_joe_rifle" and takeAim ~= nil then
		caster:SwapAbilities(
			"sniper_rapid_machinery_custom",
			"sniper_take_aim_custom",
			true,
			false
		)

		takeAim:SetActivated(false)
		takeAim:SetHidden(true)

		rapidMachinery:SetActivated(true)
		rapidMachinery:SetHidden(false)
	end

	local shrapnel = caster:FindAbilityByName("sniper_shrapnel_custom")
	local LongRangeAdvantage = caster:FindAbilityByName("sniper_long_range_advantage_custom")
	if name == "modifier_gun_joe_rifle" and LongRangeAdvantage ~= nil then
		caster:SwapAbilities(
			"sniper_shrapnel_custom",
			"sniper_long_range_advantage_custom",
			true,
			false
		)

		LongRangeAdvantage:SetActivated(false)
		LongRangeAdvantage:SetHidden(true)

		shrapnel:SetActivated(true)
		shrapnel:SetHidden(false)
	end
	--]]
end

mod.OnRefresh = mod.OnCreated

function mod:DeclareFunctions() return 
{
	MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
	MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
}
end

function mod:GetModifierAttackRangeBonus()
	return self.rangeBonus
end

function mod:GetModifierBaseAttackTimeConstant()
	return self.bat
end

function mod:GetModifierDamageOutgoing_Percentage(event)
	return self.damageModifier
end

function MakeBaseGunModifier( rangeBonusName, batName, damageModifierName, stance )
	local result = class({})

	for i,x in pairs(mod) do
		result[i] = x
	end

	result.batName 			  = batName
	result.damageModifierName = damageModifierName
	result.rangeBonusName 	  = rangeBonusName

	return result
end

function mod:GetPriority()
	return 10001
end