modifier_carl_alacrity = class({})
local intPack = require("util/intPack")
--------------------------------------------------------------------------------
-- Classifications
function modifier_carl_alacrity:IsHidden()
	return false
end

function modifier_carl_alacrity:IsDebuff()
	return false
end

function modifier_carl_alacrity:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_carl_alacrity:OnCreated( kv )
	self:SetHasCustomTransmitterData(true)

	if IsServer() then
		-- get references
		self.damage = self:GetAbility():GetOrbSpecialValueFor( "bonus_spell_amp", "e" )
		self.cdr = self:GetAbility():GetOrbSpecialValueFor( "bonus_cdr", "w" )

		self:InvokeBonusDamage()

		-- Effects
		self:PlayEffects()
	end
end

function modifier_carl_alacrity:OnRefresh( kv )
	if IsServer() then
		-- get references
		self.damage = self:GetAbility():GetOrbSpecialValueFor( "bonus_spell_amp", "e" )
		self.cdr = self:GetAbility():GetOrbSpecialValueFor( "bonus_cdr", "w" )

		self:InvokeBonusDamage()

		-- Effects
		self:PlayEffects()
	end
end

function modifier_carl_alacrity:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_carl_alacrity:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_COOLDOWN_REDUCTION_CONSTANT,
	}

	return funcs
end
function modifier_carl_alacrity:GetModifierSpellAmplify_Percentage()
	return self.fDamage
end
function modifier_carl_alacrity:GetModifierCooldownReduction_Constant()
	return self.fCdr
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_carl_alacrity:GetEffectName()
	return "particles/units/heroes/hero_invoker/invoker_alacrity_buff.vpcf"
end

function modifier_carl_alacrity:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

--------------------------------------------------------------------------------
function modifier_carl_alacrity:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_invoker/invoker_alacrity.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )

	-- buff particle
	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	-- Emit Sounds
	local sound_cast = "Hero_Invoker.Alacrity"
	EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_carl_alacrity:AddCustomTransmitterData()
    return
    {
        cdr = self.fCdr,
        damage = self.fDamage,
    }
end

function modifier_carl_alacrity:HandleCustomTransmitterData(data)
    if data.damage ~= nil and data.cdr ~= nil then
        self.fDamage = tonumber(data.damage)
        self.fCdr = tonumber(data.cdr)
    end
end

function modifier_carl_alacrity:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage
        self.fCdr = self.cdr

        self:SendBuffRefreshToClients()
    end
end