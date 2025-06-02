modifier_carl_exort = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_carl_exort:IsHidden()
	return false
end

function modifier_carl_exort:IsDebuff()
	return false
end

function modifier_carl_exort:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE 
end

function modifier_carl_exort:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_carl_exort:OnCreated( kv )
	-- references
	self.damage = self:GetAbility():GetSpecialValueFor( "bonus_damage_per_instance" ) -- special value
end

function modifier_carl_exort:OnRefresh( kv )
	-- references
	self.damage = self:GetAbility():GetSpecialValueFor( "bonus_damage_per_instance" ) -- special value	
end

function modifier_carl_exort:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_carl_exort:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}

	return funcs
end
function modifier_carl_exort:GetModifierDamageOutgoing_Percentage()
	return self.damage
end