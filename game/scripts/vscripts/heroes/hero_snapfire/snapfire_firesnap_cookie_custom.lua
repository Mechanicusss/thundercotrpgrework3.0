LinkLuaModifier("modifier_snapfire_firesnap_cookie_custom", "heroes/hero_snapfire/snapfire_firesnap_cookie_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_snapfire_firesnap_cookie_custom_buff", "heroes/hero_snapfire/snapfire_firesnap_cookie_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_snapfire_firesnap_cookie_custom_aura", "heroes/hero_snapfire/snapfire_firesnap_cookie_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

snapfire_firesnap_cookie_custom = class(ItemBaseClass)
modifier_snapfire_firesnap_cookie_custom = class(snapfire_firesnap_cookie_custom)
modifier_snapfire_firesnap_cookie_custom_buff = class(ItemBaseClassBuff)
modifier_snapfire_firesnap_cookie_custom_aura = class(ItemBaseClassAura)
-------------
function snapfire_firesnap_cookie_custom:GetIntrinsicModifierName()
    return "modifier_snapfire_firesnap_cookie_custom"
end

function snapfire_firesnap_cookie_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function snapfire_firesnap_cookie_custom:OnProjectileHit_ExtraData(hTarget, hLoc, extraData)
    if not hTarget then return end 

    local caster = self:GetCaster()

    if hTarget:IsOutOfGame() then return end

    local effect_cast = self:PlayEffects2(hTarget)

    local heal = hTarget:GetMaxHealth() * (self:GetSpecialValueFor("max_heal_pct")/100)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, hTarget, heal, nil)

    hTarget:Heal(heal, self)

    hTarget:AddNewModifier(caster, self, "modifier_snapfire_firesnap_cookie_custom_buff", {
        duration = self:GetSpecialValueFor("duration")
    })

    ParticleManager:DestroyParticle(effect_cast, false)
    ParticleManager:ReleaseParticleIndex(effect_cast)
    self:PlayEffects3(hTarget, 300)

    if extraData.bonusTargets == 1 then return end
    
    local mod = caster:FindModifierByName("modifier_snapfire_firesnap_cookie_custom_aura")
    if not mod then return end

    if caster:HasModifier("modifier_item_aghanims_shard") then
        local allies = FindUnitsInRadius(caster:GetTeam(), hTarget:GetAbsOrigin(), nil,
			self:GetSpecialValueFor("search_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        local count = 0

        for _,ally in ipairs(allies) do
            if ally:IsAlive() and ally ~= hTarget then
                if count < self:GetSpecialValueFor("extra_targets") then
                    mod:ThrowCookie(hTarget, ally, 1)
                end

                count = count + 1
            end
        end
    end
end

function snapfire_firesnap_cookie_custom:PlayEffects2( target )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_snapfire/hero_snapfire_cookie_buff.vpcf"
	local particle_cast2 = "particles/units/heroes/hero_snapfire/hero_snapfire_cookie_receive.vpcf"
	local sound_target = "Hero_Snapfire.FeedCookie.Consume"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	local effect_cast = ParticleManager:CreateParticle( particle_cast2, PATTACH_ABSORIGIN_FOLLOW, target )

	-- Create Sound
	EmitSoundOn( sound_target, target )

	return effect_cast
end

function snapfire_firesnap_cookie_custom:PlayEffects3( target, radius )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_snapfire/hero_snapfire_cookie_landing.vpcf"
	local sound_location = "Hero_Snapfire.FeedCookie.Impact"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, target )
	ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_location, target )
end

-------------
function modifier_snapfire_firesnap_cookie_custom:IsAura()
    return true
end

function modifier_snapfire_firesnap_cookie_custom:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_snapfire_firesnap_cookie_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_snapfire_firesnap_cookie_custom:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_snapfire_firesnap_cookie_custom:GetModifierAura()
    return "modifier_snapfire_firesnap_cookie_custom_aura"
end

function modifier_snapfire_firesnap_cookie_custom:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE 
end

function modifier_snapfire_firesnap_cookie_custom:GetAuraEntityReject(target)
    return false
end
----------------------------------
function modifier_snapfire_firesnap_cookie_custom_aura:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end 

function modifier_snapfire_firesnap_cookie_custom_aura:ThrowCookie(source, target, bonusTargets)
    local projectileSpeed = self:GetAbility():GetSpecialValueFor("projectile_speed")

    local info = {
		Target = target,
		Source = source,
		Ability = self:GetAbility(),	
		
		EffectName = "particles/units/heroes/hero_snapfire/hero_snapfire_cookie_projectile.vpcf",
		iMoveSpeed = projectileSpeed,
		bDodgeable = false,                           -- Optional
        ExtraData = {
            bonusTargets = bonusTargets
        }
	}

	ProjectileManager:CreateTrackingProjectile(info)
end

function modifier_snapfire_firesnap_cookie_custom_aura:OnTakeDamage(event)
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local target = event.unit 

    if target ~= self:GetParent() then return end
    if target:GetTeam() ~= caster:GetTeam() then return end 
    if not target:IsRealHero() or target:IsIllusion() then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    local chance = ability:GetSpecialValueFor("chance")
    local range = ability:GetSpecialValueFor("radius")

    if not RollPercentage(chance) then return end

    self:PlayEffects1()

    caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)
    
    self:ThrowCookie(self:GetCaster(), target, 0)

	-- Play sound
	local sound_cast = "Hero_Snapfire.FeedCookie.Cast"
	EmitSoundOn( sound_cast, parent )

    ability:UseResources(false, false, false, true)
end

function modifier_snapfire_firesnap_cookie_custom_aura:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_snapfire/hero_snapfire_cookie_selfcast.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end
-------------------
function modifier_snapfire_firesnap_cookie_custom_buff:OnCreated()
    if not IsServer() then return end
    
    self:StartIntervalThink(1)
end

function modifier_snapfire_firesnap_cookie_custom_buff:OnIntervalThink()
    local heal = self:GetParent():GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("max_heal_overtime_pct")/100)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetParent(), heal, nil)

    self:GetParent():Heal(heal, self:GetAbility())
end

function modifier_snapfire_firesnap_cookie_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_snapfire_firesnap_cookie_custom_buff:GetModifierAttackSpeedBonus_Constant()
    if self:GetCaster():HasScepter() then
        return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
    end
end

function modifier_snapfire_firesnap_cookie_custom_buff:GetModifierDamageOutgoing_Percentage()
    if self:GetCaster():HasScepter() then
        return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
    end
end