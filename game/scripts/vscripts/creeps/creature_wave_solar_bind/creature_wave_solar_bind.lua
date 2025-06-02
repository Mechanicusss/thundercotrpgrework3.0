LinkLuaModifier("modifier_creature_wave_solar_bind", "creeps/creature_wave_solar_bind/creature_wave_solar_bind", LUA_MODIFIER_MOTION_NONE)

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

creature_wave_solar_bind = class(ItemBaseClass)
modifier_creature_wave_solar_bind = class(ItemBaseClassDebuff)
-------------
function creature_wave_solar_bind:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    target:AddNewModifier(caster, self, "modifier_creature_wave_solar_bind", {
        duration = self:GetSpecialValueFor("duration")
    })

    EmitSoundOn("Hero_KeeperOfTheLight.SolarBind.Cast", caster)
    EmitSoundOn("Hero_KeeperOfTheLight.SolarBind.Target", target)
end
-----------
function modifier_creature_wave_solar_bind:OnCreated()
    if not IsServer() then return end 

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_radiant_bind_debuff.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		self.effect_cast,
		0,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector(5,5,5) )

	-- buff particle
	self:AddParticle(
		self.effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		true, -- bHeroEffect
		false -- bOverheadEffect
	)

    EmitSoundOn("Hero_KeeperOfTheLight.SolarBind", self:GetParent())
end

function modifier_creature_wave_solar_bind:OnRemoved()
    if not IsServer() then return end 

    local parent = self:GetParent()

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    StopSoundOn("Hero_KeeperOfTheLight.SolarBind", parent)
end

function modifier_creature_wave_solar_bind:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_creature_wave_solar_bind:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow") * self:GetElapsedTime()
end

function modifier_creature_wave_solar_bind:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("res") * self:GetElapsedTime()
end