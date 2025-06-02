LinkLuaModifier("modifier_gun_joe_explosive_debuff", "heroes/hero_sniper/modifiers/modifier_gun_joe_explosive", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

modifier_gun_joe_explosive = modifier_gun_joe_explosive or class({})
modifier_gun_joe_explosive_debuff = class(ItemBaseClassDebuff)
local mod = modifier_gun_joe_explosive

function mod:IsHidden()
	return false
end

function mod:IsPurgable()
	return false
end

function mod:DestroyOnExpire()
	return true
end

if IsServer() then 
	function mod:DeclareFunctions()
		return { MODIFIER_EVENT_ON_ATTACK_LANDED, }
	end

	function mod:OnAttackLanded( params )
		if not self or self:IsNull() then return end

		local parent = self:GetParent()

		if params.attacker ~= parent or not parent or parent:IsNull() then return end

		local ability = self:GetAbility()

		if not ability or ability:IsNull() then return end

		local target = params.target

		if not target or target:IsNull() then return end

		local radius = ability:GetSpecialValueFor( "radius" ) + parent:GetTalentSpecialValueFor("gun_joe_special_bonus_explosive_bullets_radius")

		local damage = ability:GetSpecialValueFor("bonus_damage")

		damage = damage + (parent:GetAgility() * (ability:GetSpecialValueFor("agility_damage")/100))

		self:DecrementStackCount()

		local nFXIndex = ParticleManager:CreateParticle( "particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_guided_missile_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)

		ParticleManager:SetParticleControlEnt( nFXIndex, 2, target, PATTACH_POINT_FOLLOW, "attach_head", target:GetOrigin(), true )
		ParticleManager:ReleaseParticleIndex( nFXIndex )

		parent:EmitSound( "Hero_Techies.Pick")

		local enemies = FindUnitsInRadius( parent:GetTeamNumber(), target:GetOrigin(), target, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )

		for _,enemy in pairs(enemies) do
			if enemy and not enemy:IsNull() and IsValidEntity(enemy) and ( not enemy:IsMagicImmune() ) and ( not enemy:IsInvulnerable() ) then

				local tbl = {
					victim 	 	= enemy,
					attacker 	= parent,
					damage 		= damage,
					damage_type = DAMAGE_TYPE_MAGICAL,
					ability 	= self,
				}

				ApplyDamage( tbl )
				enemy:AddNewModifier(parent, ability, "modifier_gun_joe_explosive_debuff", {
					duration = ability:GetSpecialValueFor("debuff_duration")
				})
				enemy:AddNewModifier(parent, nil, "modifier_stunned", {
					duration = ability:GetSpecialValueFor("debuff_duration")
				})
			end
		end


		if self:GetStackCount() == 0 then
			self:Destroy()
		end
	end
end

function modifier_gun_joe_explosive_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
	}

	return funcs
end

function modifier_gun_joe_explosive_debuff:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_gun_joe_explosive_debuff:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("magic_reduction")
end