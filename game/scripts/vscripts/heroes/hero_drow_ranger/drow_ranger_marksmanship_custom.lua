LinkLuaModifier("modifier_drow_ranger_marksmanship_custom", "heroes/hero_drow_ranger/drow_ranger_marksmanship_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_marksmanship_custom_debuff", "heroes/hero_drow_ranger/drow_ranger_marksmanship_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_marksmanship_custom_aura", "heroes/hero_drow_ranger/drow_ranger_marksmanship_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_marksmanship_custom_aura_crit", "heroes/hero_drow_ranger/drow_ranger_marksmanship_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_drow_ranger_multishot_custom", "heroes/hero_drow_ranger/drow_ranger_multishot_custom", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

drow_ranger_marksmanship_custom = class(ItemBaseClass)
modifier_drow_ranger_marksmanship_custom = class(drow_ranger_marksmanship_custom)
modifier_drow_ranger_marksmanship_custom_debuff = class(ItemBaseClassDebuff)
modifier_drow_ranger_marksmanship_custom_aura = class(ItemBaseClassBuff)
modifier_drow_ranger_marksmanship_custom_aura_crit = class(ItemBaseClassBuff)

function modifier_drow_ranger_marksmanship_custom_aura_crit:IsHidden() return true end
-------------
function drow_ranger_marksmanship_custom:GetIntrinsicModifierName()
    return "modifier_drow_ranger_marksmanship_custom"
end

function drow_ranger_marksmanship_custom:OnProjectileHit_ExtraData( target, location, data )
	if not target then return end

	-- perform attack
	self.split = true
	self.split_procs = data.procs==1
	self:GetCaster():PerformAttack( target, true, true, true, false, false, false, false )
	self.split = false
end
--------------
function modifier_drow_ranger_marksmanship_custom:GetPriority()
	return MODIFIER_PRIORITY_HIGH 
end

function modifier_drow_ranger_marksmanship_custom:OnCreated()
    self.chance = self:GetAbility():GetSpecialValueFor( "chance" )
	self.damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
	self.disable = self:GetAbility():GetSpecialValueFor( "disable_range" )
	self.radius = self:GetAbility():GetSpecialValueFor( "agility_range" )
	self.split_range = self:GetAbility():GetSpecialValueFor( "scepter_range" )
	self.split_count = self:GetAbility():GetSpecialValueFor( "split_count_scepter" )
	self.split_damage = self:GetAbility():GetSpecialValueFor( "damage_reduction_scepter" )

	self.active = true

	if not IsServer() then return end
	self.records = {}
	self.procs = false

	self.frostArrow = self:GetParent():FindAbilityByName("drow_ranger_frost_arrows_custom")
	self.originalProjectile = self:GetParent():GetRangedProjectileName()

	-- precache splinter
	self.info = {
		-- Target = target,
		-- Source = self:GetParent(),
		Ability = self:GetAbility(),	
		
		EffectName = self:GetParent():GetRangedProjectileName(),
		iMoveSpeed = self:GetParent():GetProjectileSpeed(),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,		
	
		bDodgeable = true,                           -- Optional
		bIsAttack = true,                                -- Optional

		ExtraData = {},
	}
	-- ProjectileManager:CreateTrackingProjectile(info)

	-- Start interval
	self:StartIntervalThink( 0.1 )

	-- play effects
	self:PlayEffects1()
end

function modifier_drow_ranger_marksmanship_custom:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,

		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,

		MODIFIER_PROPERTY_PROJECTILE_NAME,
	}

	return funcs
end

function modifier_drow_ranger_marksmanship_custom:OnAttackStart( params )
	if not IsServer() then return end
	if params.attacker~=self:GetParent() then return end

	-- cancel if inactive
	if not self.active then return end

	-- roll chance happens here, so that projectile_name can check if procs
	local rand = RandomInt( 0, 100 )
	if rand>self:GetAbility():GetSpecialValueFor( "chance" ) then return end
	self.procs = true

	params.attacker:SetRangedProjectileName("particles/units/heroes/hero_drow/drow_marksmanship_attack.vpcf")
end

function modifier_drow_ranger_marksmanship_custom:OnAttack( params )
	if not IsServer() then return end
	if params.attacker~=self:GetParent() then return end

	-- check if split shot and procs
	if self:GetAbility().split and self:GetAbility().split_procs then
		self.procs = true
	end

	-- check if procs
	if not self.procs then return end
	self.procs = false

	-- procs, record attack
	self.records[params.record] = true

	local caster = self:GetCaster()
	local runeMarksmanship = caster:FindModifierByName("modifier_item_socket_rune_legendary_drow_ranger_marksmanship")
    if runeMarksmanship and RollPercentage(runeMarksmanship.multishotChance) then
		local multishot = params.attacker:FindAbilityByName("drow_ranger_multishot_custom")
		if multishot and multishot:GetLevel() > 0 then
			local point = params.target:GetAbsOrigin()
			params.attacker:AddNewModifier(params.attacker, multishot, "modifier_drow_ranger_multishot_custom", {
				duration = multishot:GetSpecialValueFor("wave_interval"),
				x = point.x,
				y = point.y,
				z = point.z,
			})
		end
    end
end

function modifier_drow_ranger_marksmanship_custom:OnAttackLanded( params )
	if not self.records[params.record] then return end

	-- add ignore armor modifier
	local modifier = params.target:AddNewModifier(
		self:GetParent(), -- player source
		self:GetAbility(), -- ability source
		"modifier_drow_ranger_marksmanship_custom_debuff", -- modifier name
		{ duration = 0.5 } -- kv
	)

	self.records[params.record] = modifier
end

function modifier_drow_ranger_marksmanship_custom:GetModifierProcAttack_BonusDamage_Physical( params )
	if not IsServer() then return end
	if not self.records[params.record] then return end
	return self.damage
end

function modifier_drow_ranger_marksmanship_custom:OnAttackRecordDestroy( params )
	if not self.records[params.record] then return end

	-- destroy record, and immediately destroy ignore armor modifier
	local modifier = self.records[params.record]
	if type(modifier)=='table' and not modifier:IsNull() then modifier:Destroy() end
	self.records[params.record] = nil
	params.attacker:SetRangedProjectileName(self.originalProjectile)
end

function modifier_drow_ranger_marksmanship_custom:GetModifierProjectileName( params )
	if not IsServer() then return end
	
	-- check procs
	if self.frostArrow ~= nil and not self.frostArrow:IsNull() then
		if self.frostArrow:GetLevel() > 0 and self.frostArrow:GetAutoCastState() and not self:GetCaster():IsSilenced() then
			if self.procs then
				return "particles/units/heroes/hero_drow/drow_marksmanship_frost_arrow.vpcf"
			else
				return "particles/units/heroes/hero_drow/drow_frost_arrow.vpcf"
			end
		end
	end
end

function modifier_drow_ranger_marksmanship_custom:GetModifierProcAttack_Feedback( params )
	if not IsServer() then return end

	-- for scepter
	if not self:GetParent():HasScepter() then return end
	-- does not trigger during multishot
	if self:GetParent():HasModifier("modifier_drow_ranger_multishot_custom") then return end 

	-- check if this is split shot
	if self:GetAbility().split then return end

	-- find enemies
	local enemies = FindUnitsInRadius(
		self:GetParent():GetTeamNumber(),	-- int, your team number
		params.target:GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.split_range,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,	-- int, flag filter
		FIND_CLOSEST,	-- int, order filter
		false	-- bool, can grow cache
	)

	local count = 0
	for _,enemy in pairs(enemies) do
		if enemy~=params.target and count<self.split_count then

			-- roll pierce armor chance
			local procs = false
			local rand = RandomInt( 0, 100 )
			if self.active and rand<=self:GetAbility():GetSpecialValueFor( "chance" ) then
				procs = true
			end

			-- launch projectile
			self.info.Target = enemy
			self.info.Source = params.target
			if procs then
				self.info.EffectName = "particles/units/heroes/hero_drow/drow_marksmanship_attack.vpcf"
				self.info.ExtraData = {
					procs = true,
				}
			else
				self.info.EffectName = self:GetParent():GetRangedProjectileName()
				self.info.ExtraData = {
					procs = false,
				}
			end
			ProjectileManager:CreateTrackingProjectile( self.info )

			count = count+1
		end
	end
end

function modifier_drow_ranger_marksmanship_custom:GetModifierDamageOutgoing_Percentage()
	if not IsServer() then return end
	
	-- check if split shot
	if self:GetAbility().split then
		return -self.split_damage
	end
end

function modifier_drow_ranger_marksmanship_custom:OnIntervalThink()
	-- check for enemy
	local enemies = FindUnitsInRadius(
		self:GetParent():GetTeamNumber(),	-- int, your team number
		self:GetParent():GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.disable,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	local no_enemies = #enemies==0

	-- check if change state
	if self.active ~= no_enemies then
		self:PlayEffects2( no_enemies )
		self.active = no_enemies
	end
end

function modifier_drow_ranger_marksmanship_custom:IsAura()
	return self.active
end

function modifier_drow_ranger_marksmanship_custom:GetModifierAura()
	return "modifier_drow_ranger_marksmanship_custom_aura"
end

function modifier_drow_ranger_marksmanship_custom:GetAuraRadius()
	return self.radius
end

function modifier_drow_ranger_marksmanship_custom:GetAuraDuration()
	return 0.5
end

function modifier_drow_ranger_marksmanship_custom:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_drow_ranger_marksmanship_custom:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_drow_ranger_marksmanship_custom:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_RANGED_ONLY
end

function modifier_drow_ranger_marksmanship_custom:GetAuraEntityReject( hEntity )
	return hEntity:HasModifier("modifier_chicken_ability_1_self_transmute") and self:GetCaster():HasModifier("modifier_chicken_ability_1_target_transmute")
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_drow_ranger_marksmanship_custom:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_drow/drow_marksmanship.vpcf"
 
	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )

	-- set glowing
	ParticleManager:SetParticleControl( self.effect_cast, 2, Vector(2,0,0) )

	-- skip bow particle CP
	-- ParticleManager:SetParticleControlEnt(
	-- 	effect_cast,
	-- 	3,
	-- 	self:GetParent(),
	-- 	PATTACH_POINT_FOLLOW,
	-- 	"bow_top",
	-- 	Vector(0,0,0), -- unknown
	-- 	true -- unknown, true
	-- )
	-- ParticleManager:SetParticleControlEnt(
	-- 	effect_cast,
	-- 	5,
	-- 	self:GetParent(),
	-- 	PATTACH_POINT_FOLLOW,
	-- 	"bow_bot",
	-- 	Vector(0,0,0), -- unknown
	-- 	true -- unknown, true
	-- )

	-- buff particle
	self:AddParticle(
		self.effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)

	self:PlayEffects2( true )
end

function modifier_drow_ranger_marksmanship_custom:PlayEffects2( start )
	-- turn on/off cold effect
	local state = 1
	if start then state = 2 end
	ParticleManager:SetParticleControl( self.effect_cast, 2, Vector(state,0,0) )

	-- play start effect
	if not start then return end

	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_drow/drow_marksmanship_start.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_drow_ranger_marksmanship_custom_aura:OnCreated( kv )
	-- references
	self.agility = self:GetAbility():GetSpecialValueFor( "agility_multiplier" )

	if not IsServer() then return end
end

function modifier_drow_ranger_marksmanship_custom_aura:OnRefresh( kv )
	-- references
	self.agility = self:GetAbility():GetSpecialValueFor( "agility_multiplier" )
end

function modifier_drow_ranger_marksmanship_custom_aura:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_drow_ranger_marksmanship_custom_aura:OnCreated( kv )
	-- references
	self.agility = self:GetAbility():GetSpecialValueFor( "agility_multiplier" )

	if not IsServer() then return end

	local parent = self:GetParent()
	local caster = self:GetCaster()

	if parent ~= caster then return end

	caster:AddNewModifier(caster, talent, "modifier_drow_ranger_marksmanship_custom_aura_crit", {})
end

function modifier_drow_ranger_marksmanship_custom_aura:OnRefresh( kv )
	-- references
	self.agility = self:GetAbility():GetSpecialValueFor( "agility_multiplier" )
end

function modifier_drow_ranger_marksmanship_custom_aura:OnRemoved( kv )
	if not IsServer() then return end

	local parent = self:GetParent()
	local caster = self:GetCaster()

	if parent ~= caster then return end

	parent:RemoveModifierByName("modifier_drow_ranger_marksmanship_custom_aura_crit")
end

function modifier_drow_ranger_marksmanship_custom_aura:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_TOOLTIP 
	}

	return funcs
end

function modifier_drow_ranger_marksmanship_custom_aura:OnTooltip()
    if self:GetCaster()==self:GetParent() then
        local agi = self:GetCaster():GetAgility()
        return self.agility*agi/100
    else
        local agi = self:GetCaster():GetAgility()
		agi = 100/(100+self.agility)*agi

		local bonus = self.agility*agi/100
        return bonus
    end
end

function modifier_drow_ranger_marksmanship_custom_aura:GetModifierBonusStats_Agility()
	if not IsServer() then return end


	if self:GetCaster()==self:GetParent() then
		-- use lock mechanism to prevent infinite recursive
		if self.lock1 then return end

		-- calculate bonus
		self.lock1 = true
		local agi = self:GetCaster():GetAgility()
		self.lock1 = false

		local bonus = self.agility*agi/100

		return bonus
	else
		-- this agi includes bonus from this ability, which should be excluded
		local agi = self:GetCaster():GetAgility()
		agi = 100/(100+self.agility)*agi

		local bonus = self.agility*agi/100

		return bonus
	end

end

function modifier_drow_ranger_marksmanship_custom_debuff:DeclareFunctions()
	local funcs = {
		-- MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE, -- for base armor only
		MODIFIER_PROPERTY_IGNORE_PHYSICAL_ARMOR, -- for all armor
	}

	return funcs
end

function modifier_drow_ranger_marksmanship_custom_debuff:GetModifierIgnorePhysicalArmor()
	if not IsServer() then return end
	-- strip base armor
	return 1
end

--function modifier_drow_ranger_marksmanship_custom_debuff:GetModifierPhysicalArmorBase_Percentage()
--	-- strip base armor
--	return 0
--end

function modifier_drow_ranger_marksmanship_custom_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE 
end
-------------
function modifier_drow_ranger_marksmanship_custom_aura_crit:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }

    return funcs
end

function modifier_drow_ranger_marksmanship_custom_aura_crit:GetModifierPreAttack_CriticalStrike( params )
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
		local caster = self:GetCaster()
		local runeMarksmanship = caster:FindModifierByName("modifier_item_socket_rune_legendary_drow_ranger_marksmanship")
		if runeMarksmanship then
			if RollPercentage(runeMarksmanship.critChance) then
				self.record = params.record
				return runeMarksmanship.critDamage
			end
		end
    end
end

function modifier_drow_ranger_marksmanship_custom_aura_crit:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
            EmitSoundOn("DOTA_Item.Daedelus.Crit", params.target)
        end
    end
end