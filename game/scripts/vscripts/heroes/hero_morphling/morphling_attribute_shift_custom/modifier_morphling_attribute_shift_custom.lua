modifier_morphling_attribute_shift_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_morphling_attribute_shift_custom:IsPassive()
	return true
end
function modifier_morphling_attribute_shift_custom:IsPurgable()
	return false
end
function modifier_morphling_attribute_shift_custom:RemoveOnDeath()
	return false
end
function modifier_morphling_attribute_shift_custom:IsDebuff()
	return false
end
function modifier_morphling_attribute_shift_custom:IsHidden()
	return true
end
function modifier_morphling_attribute_shift_custom:IsStackable()
	return false
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_morphling_attribute_shift_custom:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
	}

	return funcs
end

function modifier_morphling_attribute_shift_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    local caster = self:GetCaster()

    self.defaultBat = caster:GetBaseAttackTime()

    if not IsServer() then return end

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_morphling_attribute_shift_custom:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.bat = self.defaultBat - ability:GetSpecialValueFor("attribute_shift_base_attack_time")

    self:InvokeBATChanges()
end

function modifier_morphling_attribute_shift_custom:AddCustomTransmitterData()
    return
    {
        bat = self.fBat,
    }
end

function modifier_morphling_attribute_shift_custom:HandleCustomTransmitterData(data)
    if data.bat ~= nil then
        self.fBat = tonumber(data.bat)
    end
end

function modifier_morphling_attribute_shift_custom:InvokeBATChanges()
    if IsServer() == true then
        self.fBat = self.bat

        self:SendBuffRefreshToClients()
    end
end

-- Agility bonus
function modifier_morphling_attribute_shift_custom:GetModifierBonusStats_Agility()
	local value = self:GetAbility():GetSpecialValueFor("attribute_shift_attributes_bonus")
	return value
end

-- Strength bonus
function modifier_morphling_attribute_shift_custom:GetModifierBonusStats_Strength()
	local value = self:GetAbility():GetSpecialValueFor("attribute_shift_attributes_bonus")
	return value
end

-- Bonus attack damage = base coefficient attack damage * strength pct + base coefficient * agility
function modifier_morphling_attribute_shift_custom:GetModifierPreAttack_BonusDamage()
	local damage_agi = self:GetCaster():GetAgility() / 100 * self:GetAbility():GetSpecialValueFor("attribute_shift_attributes_to_damage_pct")
	local damage_str = self:GetCaster():GetStrength() / 100 * self:GetAbility():GetSpecialValueFor("attribute_shift_attributes_to_damage_pct")
	local value = damage_agi + damage_str
	return value
end

-- Bonus base attack time
function modifier_morphling_attribute_shift_custom:GetModifierBaseAttackTimeConstant()
    if self:GetCaster():GetAgility() > self:GetCaster():GetStrength() then
		return self.fBat
   	else
   		return self.defaultBat
   	end
end

-- Bonus pure damage pct
function modifier_morphling_attribute_shift_custom:GetModifierProcAttack_BonusDamage_Pure()
	if self:GetCaster():GetAgility() < self:GetCaster():GetStrength() then
    	local value = self:GetAbility():GetSpecialValueFor("attribute_shift_attack_damage_is_pure_pct") * self:GetCaster():GetAttackDamage()
        return value
    else
   		return nil
   	end
end