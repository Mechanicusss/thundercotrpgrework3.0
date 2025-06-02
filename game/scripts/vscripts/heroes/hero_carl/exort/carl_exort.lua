carl_exort = class({})
LinkLuaModifier( "modifier_carl_exort", "heroes/hero_carl/exort/modifier_carl_exort", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function carl_exort:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- add modifier
	local modifier = caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_carl_exort", -- modifier name
		{  } -- kv
	)

	-- register to invoke ability
	self.invoke:AddOrb( modifier )
end

--------------------------------------------------------------------------------
-- Ability Events
function carl_exort:OnUpgrade()
	if not self.invoke then
		-- if first time, upgrade and init Invoke
		local invoke = self:GetCaster():FindAbilityByName( "carl_invoke" )
		if invoke:GetLevel()<1 then invoke:UpgradeAbility(true) end
		self.invoke = invoke
	else
		-- update status
		self.invoke:UpdateOrb("modifier_carl_exort", self:GetLevel())
	end
end