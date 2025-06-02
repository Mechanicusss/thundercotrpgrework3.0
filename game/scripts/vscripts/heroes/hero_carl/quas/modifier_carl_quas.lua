modifier_carl_quas = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_carl_quas:IsHidden()
	return false
end

function modifier_carl_quas:IsDebuff()
	return false
end

function modifier_carl_quas:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE 
end

function modifier_carl_quas:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_carl_quas:OnCreated( kv )
	-- references
	self.regen = self:GetAbility():GetSpecialValueFor( "health_regen_per_instance" ) -- special value
end

function modifier_carl_quas:OnRefresh( kv )
	-- references
	self.regen = self:GetAbility():GetSpecialValueFor( "health_regen_per_instance" ) -- special value	
end

function modifier_carl_quas:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_carl_quas:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
	}

	return funcs
end

function modifier_carl_quas:GetModifierHealthRegenPercentage()
	return self.regen
end