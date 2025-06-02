LinkLuaModifier("modifier_creature_pitlord_pitofmalice", "creeps/creature_pitlord_pitofmalice/creature_pitlord_pitofmalice", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_creature_pitlord_pitofmalice_aura", "creeps/creature_pitlord_pitofmalice/creature_pitlord_pitofmalice", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

creature_pitlord_pitofmalice = class(ItemBaseClass)
modifier_creature_pitlord_pitofmalice = class(creature_pitlord_pitofmalice)
modifier_creature_pitlord_pitofmalice_aura = class(ItemBaseClassDebuff)
-------------
function creature_pitlord_pitofmalice:GetIntrinsicModifierName()
    return "modifier_creature_pitlord_pitofmalice"
end

function modifier_creature_pitlord_pitofmalice:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS 
    }

    return funcs
end

function modifier_creature_pitlord_pitofmalice:GetActivityTranslationModifiers()
    return "run"
end

function modifier_creature_pitlord_pitofmalice:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/underlord_pitofmalice_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    
    ParticleManager:SetParticleControl( self.effect_cast, 0, parent:GetOrigin() )
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( radius, 1, 1 ) )
	ParticleManager:SetParticleControl( self.effect_cast, 2, Vector( 99999, 0, 0 ) )

	-- buff particle
	self:AddParticle(
		self.effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)

    EmitSoundOn("Hero_AbyssalUnderlord.PitOfMalice", parent)
end

function modifier_creature_pitlord_pitofmalice:OnRemoved()
    if not IsServer() then return end 

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_creature_pitlord_pitofmalice:IsAura()
	return true
end

function modifier_creature_pitlord_pitofmalice:GetModifierAura()
	return "modifier_creature_pitlord_pitofmalice_aura"
end

function modifier_creature_pitlord_pitofmalice:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_creature_pitlord_pitofmalice:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_creature_pitlord_pitofmalice:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_creature_pitlord_pitofmalice:GetAuraEntityReject( hEntity )
    return false
end

function modifier_creature_pitlord_pitofmalice:RemoveOnDeath() return true end
----------
function modifier_creature_pitlord_pitofmalice_aura:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    EmitSoundOn("Hero_AbyssalUnderlord.Pit.TargetHero", parent)
end

function modifier_creature_pitlord_pitofmalice_aura:CheckState()
    return {
        [MODIFIER_STATE_INVISIBLE] = false,
		[MODIFIER_STATE_ROOTED] = true,
    }
end

function modifier_creature_pitlord_pitofmalice_aura:GetEffectName()
	return "particles/units/heroes/heroes_underlord/abyssal_underlord_pitofmalice_stun.vpcf"
end

function modifier_creature_pitlord_pitofmalice_aura:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end