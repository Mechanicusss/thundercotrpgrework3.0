modifier_carl_chaos_meteor_burn = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_carl_chaos_meteor_burn:IsHidden()
	return false
end

function modifier_carl_chaos_meteor_burn:IsDebuff()
	return true
end

function modifier_carl_chaos_meteor_burn:IsStunDebuff()
	return false
end

function modifier_carl_chaos_meteor_burn:GetAttributes()
	return MODIFIER_ATTRIBUTE_NONE  
end

function modifier_carl_chaos_meteor_burn:IsPurgable()
	return true
end

function modifier_carl_chaos_meteor_burn:IsStackable()
	return false
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_carl_chaos_meteor_burn:OnCreated( kv )
	if IsServer() then
		-- references
		local damage = self:GetAbility():GetOrbSpecialValueFor( "burn_dps", "e" )
		local damageInterval = self:GetAbility():GetOrbSpecialValueFor( "damage_interval", "q" )

		self.damageTable = {
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			damage = (damage + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor( "int_to_damage" )/100))) * damageInterval * self:GetStackCount(),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(), --Optional.
		}

		-- Start interval
		self:StartIntervalThink( damageInterval )
	end
end

function modifier_carl_chaos_meteor_burn:OnRefresh( kv )
	
end

function modifier_carl_chaos_meteor_burn:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_carl_chaos_meteor_burn:OnIntervalThink()
	-- damage
	ApplyDamage( self.damageTable )

	-- play effects
	local sound_tick = "Hero_Invoker.ChaosMeteor.Damage"
	EmitSoundOn( sound_tick, self:GetParent() )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_carl_chaos_meteor_burn:GetEffectName()
	return "particles/units/heroes/hero_invoker/invoker_chaos_meteor_burn_debuff.vpcf"
end

function modifier_carl_chaos_meteor_burn:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

-- function modifier_carl_chaos_meteor_burn:PlayEffects()
-- 	-- Get Resources
-- 	local particle_cast = "string"
-- 	local sound_cast = "string"

-- 	-- Get Data

-- 	-- Create Particle
-- 	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_NAME, hOwner )
-- 	ParticleManager:SetParticleControl( effect_cast, iControlPoint, vControlVector )
-- 	ParticleManager:SetParticleControlEnt(
-- 		effect_cast,
-- 		iControlPoint,
-- 		hTarget,
-- 		PATTACH_NAME,
-- 		"attach_name",
-- 		vOrigin, -- unknown
-- 		bool -- unknown, true
-- 	)
-- 	ParticleManager:SetParticleControlForward( effect_cast, iControlPoint, vForward )
-- 	SetParticleControlOrientation( effect_cast, iControlPoint, vForward, vRight, vUp )
-- 	ParticleManager:ReleaseParticleIndex( effect_cast )

-- 	-- buff particle
-- 	self:AddParticle(
-- 		nFXIndex,
-- 		bDestroyImmediately,
-- 		bStatusEffect,
-- 		iPriority,
-- 		bHeroEffect,
-- 		bOverheadEffect
-- 	)

-- 	-- Create Sound
-- 	EmitSoundOnLocationWithCaster( vTargetPosition, sound_location, self:GetCaster() )
-- 	EmitSoundOn( sound_target, target )
-- end