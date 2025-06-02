function modifier_item_reverse:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_MAX ,
	}
 
	return funcs
end

function modifier_item_reverse:GetModifierMoveSpeed_Max(params)
	return 1000
end
