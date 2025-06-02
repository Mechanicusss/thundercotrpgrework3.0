LinkLuaModifier("modifier_saber_avalon", "heroes/hero_saber/avalon", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saber_avalon_invulnerability", "heroes/hero_saber/avalon", LUA_MODIFIER_MOTION_NONE)
saber_avalon = class({
	GetIntrinsicModifierName = function() return "modifier_saber_avalon" end,
})

if IsServer() then
	function saber_avalon:OnSpellStart()
		local caster = self:GetCaster()
		caster:AddNewModifier(caster, self, "modifier_saber_avalon_invulnerability", {duration = self:GetSpecialValueFor("duration")})
	end
	function saber_avalon:OnChannelFinish()
		self:GetCaster():RemoveModifierByName("modifier_saber_avalon_invulnerability")
	end
end


modifier_saber_avalon = class({
	IsPurgable       = function() return false end,
	DeclareFunctions = function() return {MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,MODIFIER_PROPERTY_REINCARNATION} end,
})

function modifier_saber_avalon:GetModifierHealthRegenPercentage()
	return self:GetAbility():GetSpecialValueFor("bonus_health_regen_max")
end

function modifier_saber_avalon:ReincarnateTime()
    if IsServer() then
        if not self:GetAbility():IsCooldownReady() then return end

        self:GetAbility():UseResources(false, false, false, true)
    end

    return 5.0
end

if IsServer() then
	
end


modifier_saber_avalon_invulnerability = class({
	GetAbsoluteNoDamageMagical  = function() return 1 end,
	GetAbsoluteNoDamagePhysical = function() return 1 end,
	GetAbsoluteNoDamagePure     = function() return 1 end,
	GetMinHealth                = function() return 1 end,
})
function modifier_saber_avalon_invulnerability:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	}
end

function modifier_saber_avalon_invulnerability:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_MIN_HEALTH,
		--MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}
end

--[[function modifier_saber_avalon_invulnerability:GetOverrideAnimation()
	return ACT_DOTA_CHANNEL_ABILITY_4
end]]
