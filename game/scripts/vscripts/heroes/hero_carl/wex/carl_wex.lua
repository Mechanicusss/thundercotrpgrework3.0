carl_wex = class({})
LinkLuaModifier( "modifier_carl_wex", "heroes/hero_carl/wex/modifier_carl_wex", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function carl_wex:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- add modifier
	local modifier = caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_carl_wex", -- modifier name
		{  } -- kv
	)

	-- register to invoke ability
	self.invoke:AddOrb( modifier )
end

--------------------------------------------------------------------------------
-- Ability Events
function carl_wex:OnUpgrade()
	if not self.invoke then
		-- if first time, upgrade and init Invoke
		local invoke = self:GetCaster():FindAbilityByName( "carl_invoke" )
		if invoke:GetLevel()<1 then invoke:UpgradeAbility(true) end
		self.invoke = invoke
	else
		-- update status
		self.invoke:UpdateOrb("modifier_carl_wex", self:GetLevel())
	end
end