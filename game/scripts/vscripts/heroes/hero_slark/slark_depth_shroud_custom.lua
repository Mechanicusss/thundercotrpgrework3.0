LinkLuaModifier("modifier_slark_depth_shroud_custom", "heroes/hero_slark/slark_depth_shroud_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slark_depth_shroud_custom_buff", "heroes/hero_slark/slark_depth_shroud_custom", LUA_MODIFIER_MOTION_NONE)

slark_depth_shroud_custom = class({})

function slark_depth_shroud_custom:OnSpellStart()
    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_slark_depth_shroud_custom", {duration = self:GetSpecialValueFor("duration")})
end

modifier_slark_depth_shroud_custom = class({
    IsPurgable = function(self) return false end
})

function modifier_slark_depth_shroud_custom:GetPriority()
	return MODIFIER_PRIORITY_HIGH
end

function modifier_slark_depth_shroud_custom:IsAura()
	return true
end

function modifier_slark_depth_shroud_custom:GetModifierAura()
	return "modifier_slark_depth_shroud_custom_buff"
end

function modifier_slark_depth_shroud_custom:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_slark_depth_shroud_custom:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_slark_depth_shroud_custom:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_slark_depth_shroud_custom:GetAuraDuration()
	return self:GetAbility():GetSpecialValueFor("fade_time")
end

function modifier_slark_depth_shroud_custom:OnCreated(keys)
    if not IsServer() then return end

    self:PlayEffects()
	self:PlayEffects2()

    self:StartIntervalThink(FrameTime())
end

function modifier_slark_depth_shroud_custom:OnRefresh(keys)
    if IsServer() then
        self:GetParent():StopSound("Hero_Slark.ShadowDance")
    end
end

function modifier_slark_depth_shroud_custom:OnIntervalThink()
	ParticleManager:SetParticleControl(self.effect_cast, 1, self:GetParent():GetOrigin())
end

function modifier_slark_depth_shroud_custom:PlayEffects()
    local parent = self:GetParent()

    local effect_cast = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_slark/slark_shadow_dance.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent, parent:GetTeamNumber())
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		parent,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0),
		true
	)
    ParticleManager:SetParticleControlEnt(
		effect_cast,
		3,
		parent,
		PATTACH_POINT_FOLLOW,
		"attach_eyeR",
		Vector(0,0,0),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		4,
		parent,
		PATTACH_POINT_FOLLOW,
		"attach_eyeL",
		Vector(0,0,0),
		true
	)
	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

    parent:EmitSound("Hero_Slark.ShadowDance")
end

function modifier_slark_depth_shroud_custom:PlayEffects2()
    local parent = self:GetParent()

    local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_shadow_dance_dummy.vpcf", PATTACH_WORLDORIGIN, parent)
	ParticleManager:SetParticleControl(effect_cast, 0, parent:GetOrigin())
	ParticleManager:SetParticleControl(effect_cast, 1, parent:GetOrigin())

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	self.effect_cast = effect_cast
end

modifier_slark_depth_shroud_custom_buff = class({
    IsPurgable = function(self) return false end
})

function modifier_slark_depth_shroud_custom_buff:GetStatusEffectName()
	return "particles/status_fx/status_effect_slark_shadow_dance.vpcf"
end

function modifier_slark_depth_shroud_custom_buff:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end

function modifier_slark_depth_shroud_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
    }
end

function modifier_slark_depth_shroud_custom_buff:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_regen_pct")
end

function modifier_slark_depth_shroud_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

function modifier_slark_depth_shroud_custom_buff:GetModifierPreAttack_BonusDamage()
    local caster = self:GetCaster()
    if not caster then return end

    local damage = caster:GetAgility() / 100 * self:GetAbility():GetSpecialValueFor("agi_to_bonus_damage")

    return damage
end