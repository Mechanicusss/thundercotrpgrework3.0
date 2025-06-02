

LinkLuaModifier("modifier_stargazer_inverse_field", "heroes/hero_stargazer/inverse_field.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

stargazer_inverse_field = class(ItemBaseClass)
modifier_stargazer_inverse_field = class(stargazer_inverse_field)
-------------
function stargazer_inverse_field:GetIntrinsicModifierName()
    return "modifier_stargazer_inverse_field"
end
-------------
function modifier_stargazer_inverse_field:OnCreated()
end

function modifier_stargazer_inverse_field:OnDestroy()
end

function modifier_stargazer_inverse_field:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_stargazer_inverse_field:OnAttackLanded(keys)
	if not IsServer() then return end 

	local caster = self:GetParent()

	if caster ~= keys.target or caster == keys.attacker then return end 

	local attacker = keys.attacker

	if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end 

	local ability = self:GetAbility()

	local level = ability:GetLevel() - 1

	local strMultiplier = caster:GetStrength() * ability:GetSpecialValueFor("str_to_reflection_pct") * 0.01 

	local multiplier = ((ability:GetSpecialValueFor("base_reflection") + strMultiplier) * 0.01) 

	local return_damage = keys.original_damage * multiplier  
	if attacker:GetTeamNumber() ~= caster:GetTeamNumber() and not attacker:IsBoss() and not attacker:IsMagicImmune() and not caster:IsIllusion() and not caster:IsTempestDouble() and not caster:PassivesDisabled() then
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_return.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(pfx, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)

		ApplyDamage({
			victim = attacker,
			attacker = caster,
			damage = return_damage,
			damage_type = keys.damage_type,
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
			ability = ability
		})
	end
end