--[[function OnSpellStart(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local level = ability:GetLevel() - 1
	local dummy = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_ward_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
	Timers:CreateTimer(0.3, function()
		UTIL_Remove(dummy)
	end)

	local blink_range = math.min(ability:GetLevelSpecialValueFor("base_range", ability:GetLevel() - 1) + (caster:GetAgility() * (ability:GetLevelSpecialValueFor("agi_to_range_pct", ability:GetLevel() - 1) * 0.01)), ability:GetAbilityValues("max_range"))
	local point = keys.target_points[1]
	local origin_point = caster:GetAbsOrigin()
	local difference_vector = point - origin_point

	if difference_vector:Length2D() > blink_range then
		point = origin_point + (point - origin_point):Normalized() * blink_range
	end

	ParticleManager:SetParticleControl(particle, 1, point)

	FindClearSpaceForUnit(caster, point, true)
end]]--

LinkLuaModifier("modifier_stargazer_warp", "heroes/hero_stargazer/warp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stargazer_warp_attack_cd", "heroes/hero_stargazer/warp.lua", LUA_MODIFIER_MOTION_NONE)


local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

stargazer_warp = class(BaseClass)

modifier_stargazer_warp_attack_cd = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

function stargazer_warp:GetIntrinsicModifierName()
    return "modifier_stargazer_warp"
end

function stargazer_warp:OnHeroCalculateStatBonus()
 if not IsServer() then return end
 local modif = self:GetCaster():FindModifierByNameAndCaster("modifier_stargazer_warp", self:GetCaster())
 if modif ~= nil then
 	modif:ForceRefresh()
 end
 -- should fix the skill not updating unless you die
end

modifier_stargazer_warp = class({
	IsPurgable = function() return false end,
})

function modifier_stargazer_warp:OnCreated( kv )
	if not IsServer() then return end
-- references
	self.crit_chance = self:GetAbility():GetSpecialValueFor( "crit_chance" )
	self.crit_dmg_max = self:GetAbility():GetSpecialValueFor( "crit_dmg_max" )
	self.crit_dmg_min = self:GetAbility():GetSpecialValueFor( "crit_dmg_min" )
	self.crit_mult = self:GetAbility():GetSpecialValueFor( "crit_mult" )
	self.agi = self:GetParent():GetAgility()
end

function modifier_stargazer_warp:OnRefresh( kv )
	if not IsServer() then return end
	-- references
	self.crit_chance = self:GetAbility():GetSpecialValueFor( "crit_chance" )
	self.crit_dmg_max = self:GetAbility():GetSpecialValueFor( "crit_dmg_max" )
	self.crit_dmg_min = self:GetAbility():GetSpecialValueFor( "crit_dmg_min" )
	self.crit_mult = self:GetAbility():GetSpecialValueFor( "crit_mult" )
	self.agi = self:GetParent():GetAgility()
	self.ability = self:GetAbility()
end

function modifier_stargazer_warp:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK
	}
end

function modifier_stargazer_warp:GetModifierPreAttack_CriticalStrike( params )
if IsServer() and (not self:GetParent():PassivesDisabled()) then
	if params.target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
		return
	end

	local critDmg = self.crit_mult * self.agi

	if critDmg < self.crit_dmg_min then
		critDmg = self.crit_dmg_min
	end

	-- Throw dice
	if RollPercentage(self.crit_chance) then
		self.record = params.record
		self.ability:UseResources(false, false, false, true)

		if not self:GetParent():HasModifier("modifier_stargazer_warp_attack_cd") and self:GetParent():HasModifier("modifier_item_aghanims_shard") then
			local ranged = self:GetParent():IsRangedAttacker()

			self:GetParent():PerformAttack(
				params.target,
				true,
				true,
				true,
				false,
				ranged,
				false,
				false
			)

			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_stargazer_warp_attack_cd", {
				duration = self:GetAbility():GetSpecialValueFor("cooldown")
			})
		end

		return critDmg
	end
end

function modifier_stargazer_warp:GetModifierProcAttack_Feedback( params )
	if IsServer() then
		if self.record and self.record == params.record then
			self.record = nil

			-- Play effects
			local sound_cast = "Hero_Juggernaut.BladeDance"
			EmitSoundOn( sound_cast, params.target )
		end
	end
end
end
