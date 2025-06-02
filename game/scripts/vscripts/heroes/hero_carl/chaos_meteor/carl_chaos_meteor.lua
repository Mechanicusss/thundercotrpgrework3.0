carl_chaos_meteor = class({})
LinkLuaModifier( "modifier_carl_chaos_meteor_thinker", "heroes/hero_carl/chaos_meteor/modifier_carl_chaos_meteor_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_carl_chaos_meteor_burn", "heroes/hero_carl/chaos_meteor/modifier_carl_chaos_meteor_burn", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function carl_chaos_meteor:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local count = self:GetOrbSpecialValueFor( "meteor_count", "e" )
	local landTime = self:GetSpecialValueFor( "land_time" )

	-- Fire initial meteor without delay!
	CreateModifierThinker(
		caster, -- player source
		self, -- ability source
		"modifier_carl_chaos_meteor_thinker", -- modifier name
		{}, -- kv
		point,
		self:GetCaster():GetTeamNumber(),
		false
	)

	for i = 2, count, 1 do
        Timers:CreateTimer(i*(landTime/count), function()
        	if not caster:IsAlive() then return end
            -- create thinker
			CreateModifierThinker(
				caster, -- player source
				self, -- ability source
				"modifier_carl_chaos_meteor_thinker", -- modifier name
				{}, -- kv
				point,
				self:GetCaster():GetTeamNumber(),
				false
			)
        end)
    end
end
--------------------------------------------------------------------------------
-- Projectile
function carl_chaos_meteor:OnStolen( hAbility )
	self.orbs = hAbility.orbs
end

function carl_chaos_meteor:GetOrbSpecialValueFor( key_name, orb_name )
	if not IsServer() then return 0 end
	if not self.orbs[orb_name] then return 0 end
	return self:GetLevelSpecialValueFor( key_name, self.orbs[orb_name] )
end