modifier_carl_wex = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_carl_wex:IsHidden()
	return false
end

function modifier_carl_wex:IsDebuff()
	return false
end

function modifier_carl_wex:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE 
end

function modifier_carl_wex:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_carl_wex:OnCreated( kv )
	-- references
	self.as_bonus = self:GetAbility():GetSpecialValueFor( "attack_speed_per_instance" ) -- special value
	self.ms_bonus = self:GetAbility():GetSpecialValueFor( "move_speed_per_instance" ) -- special value
end

function modifier_carl_wex:OnRefresh( kv )
	-- references
	self.as_bonus = self:GetAbility():GetSpecialValueFor( "attack_speed_per_instance" ) -- special value
	self.ms_bonus = self:GetAbility():GetSpecialValueFor( "move_speed_per_instance" ) -- special value
end

function modifier_carl_wex:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_carl_wex:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
	}

	return funcs
end

function modifier_carl_wex:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_bonus
end
function modifier_carl_wex:GetModifierAttackSpeedPercentage()
	return self.as_bonus
end
