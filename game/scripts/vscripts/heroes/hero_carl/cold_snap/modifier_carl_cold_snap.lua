modifier_carl_cold_snap = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_carl_cold_snap:IsHidden()
	return false
end

function modifier_carl_cold_snap:IsDebuff()
	return true
end

function modifier_carl_cold_snap:IsStunDebuff()
	return false
end

function modifier_carl_cold_snap:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_carl_cold_snap:OnCreated( kv )
	self:SetHasCustomTransmitterData(true)

	if IsServer() then
		-- references
		self.damage = self:GetAbility():GetOrbSpecialValueFor( "freeze_damage", "q" ) + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor( "int_to_damage" )/100))
		self.duration = self:GetAbility():GetOrbSpecialValueFor( "freeze_duration", "q" )
		self.cooldown = self:GetAbility():GetOrbSpecialValueFor( "freeze_cooldown", "q" )
		self.threshold = self:GetAbility():GetOrbSpecialValueFor( "damage_trigger", "q" )
		self.magicRes = self:GetAbility():GetOrbSpecialValueFor( "magic_res_reduction", "q" )

		self.onCooldown = false

		-- Start interval
		self:Freeze()
		self:InvokeBonusDamage()
	end
end

function modifier_carl_cold_snap:OnRefresh( kv )
	if IsServer() then
		-- references
		self.damage = self:GetAbility():GetOrbSpecialValueFor( "freeze_damage", "q" )
		self.duration = self:GetAbility():GetOrbSpecialValueFor( "freeze_duration", "q" )
		self.cooldown = self:GetAbility():GetOrbSpecialValueFor( "freeze_cooldown", "q" )
		self.threshold = self:GetAbility():GetOrbSpecialValueFor( "damage_trigger", "q" )
	end
end

function modifier_carl_cold_snap:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_carl_cold_snap:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
	}

	return funcs
end

function modifier_carl_cold_snap:GetModifierMagicalResistanceBonus( params )
	return self.fMagicRes
end

function modifier_carl_cold_snap:OnTakeDamage( params )
	if IsServer() then
		if params.unit~=self:GetParent() then return end
		if params.damage<self.threshold then return end
		if self.onCooldown then return end
		self:Freeze()

		self:PlayEffects( params.attacker )
	end
end

function modifier_carl_cold_snap:AddCustomTransmitterData()
    return
    {
        magicRes = self.fMagicRes
    }
end

function modifier_carl_cold_snap:HandleCustomTransmitterData(data)
    if data.magicRes ~= nil then
        self.fMagicRes = tonumber(data.magicRes)
    end
end

function modifier_carl_cold_snap:InvokeBonusDamage()
    if IsServer() == true then
        self.fMagicRes = self.magicRes

        self:SendBuffRefreshToClients()
    end
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_carl_cold_snap:OnIntervalThink()
	self.onCooldown = false
	self:StartIntervalThink(-1)
end

--------------------------------------------------------------------------------
-- Helper functions
function modifier_carl_cold_snap:Freeze()
	self.onCooldown = true
	self:GetParent():AddNewModifier(
		self:GetCaster(), -- player source
		self:GetAbility(), -- ability source
		"modifier_generic_stunned_lua", -- modifier name
		{ duration = self.duration } -- kv
	)
	ApplyDamage({
		attacker = self:GetCaster(),
		victim = self:GetParent(),
		damage = self.damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility()
	})
	self:StartIntervalThink( self.cooldown )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_carl_cold_snap:GetEffectName()
	return "particles/units/heroes/hero_invoker/invoker_cold_snap_status.vpcf"
end

function modifier_carl_cold_snap:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_carl_cold_snap:PlayEffects( attacker )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_invoker/invoker_cold_snap.vpcf"
	local sound_cast = "Hero_Invoker.ColdSnap.Freeze"

	-- Get Data
	local direction = self:GetParent():GetOrigin()-attacker:GetOrigin()

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControl( effect_cast, 1,  self:GetParent():GetOrigin()+direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetParent() )
end