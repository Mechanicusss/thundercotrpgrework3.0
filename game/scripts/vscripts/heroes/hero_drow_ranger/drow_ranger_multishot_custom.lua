-- Created by Elfansoer
--[[
Ability checklist (erase if done/checked):
- Scepter Upgrade
- Break behavior
- Linken/Reflect behavior
- Spell Immune/Invulnerable/Invisible behavior
- Illusion behavior
- Stolen behavior
]]
--------------------------------------------------------------------------------
drow_ranger_multishot_custom = class({})
LinkLuaModifier( "modifier_drow_ranger_multishot_custom", "heroes/hero_drow_ranger/drow_ranger_multishot_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_drow_ranger_multishot_custom_debuff", "heroes/hero_drow_ranger/drow_ranger_multishot_custom", LUA_MODIFIER_MOTION_NONE )

modifier_drow_ranger_multishot_custom_debuff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})
--------------------------------------------------------------------------------
-- Ability Start
drow_ranger_multishot_custom.targets = {}
function drow_ranger_multishot_custom:GetChannelTime()
    return self:GetSpecialValueFor("wave_interval") * self:GetSpecialValueFor("wave_count")
end

function drow_ranger_multishot_custom:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- load data
	local duration = self:GetChannelTime()

	self.targets = {}

	-- add modifier
	self.modifier = caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_drow_ranger_multishot_custom", -- modifier name
		{
			duration = duration,
			x = point.x,
			y = point.y,
			z = point.z,
		} -- kv
	)

end
--------------------------------------------------------------------------------
-- Projectile
function drow_ranger_multishot_custom:OnProjectileHit_ExtraData( target, location, data )
	if not target then return end
	-- check if already attacked on this wave
	--or not? that way you can hit enemies point blank for more damage!
	--if self.targets[ target ]==data.wave then return false end
	--self.targets[ target ] = data.wave

	-- Frost arrows
	if data.frost == 1 then
		local ability = self:GetCaster():FindAbilityByName("drow_ranger_frost_arrows_custom")
		local debuff = target:FindModifierByName("modifier_drow_ranger_frost_arrows_custom_debuff")
		if debuff == nil then
			debuff = target:AddNewModifier(self:GetCaster(), ability, "modifier_drow_ranger_frost_arrows_custom_debuff", { duration = ability:GetSpecialValueFor("stack_duration") })
		end

		if debuff ~= nil then
			if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
				debuff:IncrementStackCount()
			end

			debuff:ForceRefresh()
		end
	end

	local damage = self:GetSpecialValueFor("arrow_damage_pct")

    local caster = self:GetCaster()
	local runeMultishot = caster:FindModifierByName("modifier_item_socket_rune_legendary_drow_ranger_multishot")
    if runeMultishot then
		target:AddNewModifier(caster, self, "modifier_drow_ranger_multishot_custom_debuff", {
			duration = runeMultishot.duration
		})

		damage = damage + runeMultishot.increasePct
    end

	ApplyDamage({
		victim = target,
		attacker = caster,
		damage = caster:GetAttackDamage() * (damage/100) + (caster:GetAgility() * (self:GetSpecialValueFor("agi_to_damage")/100)),
		damage_type = DAMAGE_TYPE_PHYSICAL,
		ability = self
	})

	-- play effects
	local sound_cast = "Hero_DrowRanger.ProjectileImpact"
	EmitSoundOn( sound_cast, target )

    --we dont want to destroy it so comment this out
	--return true
end

--------------------------------------------------------------------------------
-- Ability Channeling
function drow_ranger_multishot_custom:OnChannelFinish( bInterrupted )
	-- destroy modifier
	if not self.modifier:IsNull() then self.modifier:Destroy() end
end

modifier_drow_ranger_multishot_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_drow_ranger_multishot_custom:IsHidden()
	return true
end

function modifier_drow_ranger_multishot_custom:IsDebuff()
	return false
end

function modifier_drow_ranger_multishot_custom:IsStunDebuff()
	return false
end

function modifier_drow_ranger_multishot_custom:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_drow_ranger_multishot_custom:GetAttributes()
	--this is for the marksmanship talent
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_drow_ranger_multishot_custom:OnCreated( kv )
	-- references
	local count = self:GetAbility():GetSpecialValueFor( "arrow_count" )
	local range = self:GetAbility():GetSpecialValueFor( "arrow_range_multiplier" )
	local width = self:GetAbility():GetSpecialValueFor( "arrow_width" )
	self.speed = self:GetAbility():GetSpecialValueFor( "arrow_speed" )
	self.angle = self:GetAbility():GetSpecialValueFor( "arrow_angle" )
	--self.angle = 33.33

	if not IsServer() then return end

	-- none provided in kv file. shame on you volvo
	local vision = 100
	local delay = 0.1
	local wave_interval = self:GetAbility():GetSpecialValueFor( "wave_interval" )

    local caster = self:GetCaster()
	local runeMultishot = caster:FindModifierByName("modifier_item_socket_rune_legendary_drow_ranger_multishot")
    if runeMultishot then
        wave_interval = wave_interval + runeMultishot.intervalDecrease
    end

	self.arrow_delay = 0.033

	-- calculate stuff
	self.arrows = count
	self.wave_delay = wave_interval - self.arrow_delay*(self.arrows-1)

	-- get projectile main direction
	local point = Vector(kv.x, kv.y, kv.z)
	self.direction = point-self:GetCaster():GetOrigin()
	self.direction.z = 0
	self.direction = self.direction:Normalized()

	-- set states
	self.state = STATE_SALVO
	self.current_arrows = 0
	self.current_wave = 0
	self.frost = false

	-- check frost arrows ability
	local ability = self:GetCaster():FindAbilityByName( "drow_ranger_frost_arrows_custom" )
	if ability and ability:GetLevel()>0 then
		self.frost = true
	end

	-- precache projectile
	local caster = self:GetCaster()
	local projectile_name
	if self.frost then
		projectile_name = "particles/units/heroes/hero_drow/drow_multishot_proj_linear_proj.vpcf"
	else
		projectile_name = "particles/units/heroes/hero_drow/drow_base_attack_linear_proj.vpcf"
	end

	self.info = {
		Source = caster,
		Ability = self:GetAbility(),
		vSpawnOrigin = caster:GetAttachmentOrigin( caster:ScriptLookupAttachment( "attach_attack1" ) ),
		
	    bDeleteOnHit = false, -- allow it to penetrate multiple targets
	    
	    iUnitTargetTeam = self:GetAbility():GetAbilityTargetTeam(),
	    iUnitTargetType = self:GetAbility():GetAbilityTargetType(),
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,

	    EffectName = projectile_name,
	    fDistance = caster:Script_GetAttackRange() * range,
	    fStartRadius = width,
	    fEndRadius = width,
		-- vVelocity = projectile_direction * self.speed,
	
		bProvidesVision = true,
		iVisionRadius = vision,
		iVisionTeamNumber = caster:GetTeamNumber()
	}
	-- ProjectileManager:CreateLinearProjectile(info)

	-- Start interval
	self:StartIntervalThink( delay )

	-- play effects
	local sound_cast = "Hero_DrowRanger.Multishot.Channel"
	EmitSoundOn( sound_cast, caster )
end

function modifier_drow_ranger_multishot_custom:OnRefresh( kv )
end

function modifier_drow_ranger_multishot_custom:OnRemoved()
end

function modifier_drow_ranger_multishot_custom:OnDestroy()
	if not IsServer() then return end

	-- stop effects
	local sound_cast = "Hero_DrowRanger.Multishot.Channel"
	StopSoundOn( sound_cast, self:GetCaster() )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_drow_ranger_multishot_custom:OnIntervalThink()
	-- count arrows
	if self.current_arrows<self.arrows then

		self:StartIntervalThink( self.arrow_delay )
	else
		self.current_arrows = 0
		self.current_wave = self.current_wave+1

        local caster = self:GetCaster()
		local runeMultishot = caster:FindModifierByName("modifier_item_socket_rune_legendary_drow_ranger_multishot")
        if runeMultishot then
			local dist = caster:Script_GetAttackRange() * self:GetAbility():GetSpecialValueFor("arrow_range_multiplier")
			
            local maxUnits = runeMultishot.arrowCount
            local radius = caster:Script_GetAttackRange()
            local i = 0
            local victims = FindUnitsInCone(
				caster:GetTeamNumber(), -- nTeamNumber
				caster:GetOrigin(), -- vCenterPos
				caster:GetOrigin(), -- vStartPos
				caster:GetOrigin() + self.direction*dist,    -- vEndPos
				1,   -- fStartRadius
				358.5, -- fEndRadius
				nil,    -- hCacheUnit
				DOTA_UNIT_TARGET_TEAM_ENEMY,    -- nTeamFilter
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- nTypeFilter
				0,  -- nFlagFilter
				FIND_CLOSEST,   -- nOrderFilter
				false   -- bCanGrowCache
			)

            for _,enemy in ipairs(victims) do
                if enemy:IsAlive() and not enemy:IsInvulnerable() and not enemy:IsAttackImmune() and i < maxUnits then
                    i = i + 1
                    caster:PerformAttack(
                        enemy,
                        true,
                        true,
                        true,
                        false,
                        true,
                        false,
                        false
                    )
                end
            end
        end

		self:StartIntervalThink( self.wave_delay )
		return
	end

	-- calculate relative angle of current arrow against cast direction
	local step = self.angle/(self.arrows-1)
	local angle = -self.angle/2 + self.current_arrows*step

	-- calculate actual direction
	local projectile_direction = RotatePosition( Vector(0,0,0), QAngle( 0, angle, 0 ), self.direction )

	-- launch projectile
	self.info.vVelocity = projectile_direction * self.speed
	self.info.ExtraData = {
		arrow = self.current_arrows,
		wave = self.current_wave,
		frost = self.frost,
	}
	ProjectileManager:CreateLinearProjectile(self.info)

	self:PlayEffects()

	self.current_arrows = self.current_arrows+1
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_drow_ranger_multishot_custom:PlayEffects()
	-- Get Resources
	local sound_cast
	if self.frost then
		sound_cast = "Hero_DrowRanger.Multishot.FrostArrows"
	else
		sound_cast = "Hero_DrowRanger.Multishot.Attack"
	end

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
end
--------------
function modifier_drow_ranger_multishot_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_drow_ranger_multishot_custom_debuff:GetModifierIncomingDamage_Percentage()
	if IsServer() then
		local caster = self:GetCaster()
		local runeMultishot = caster:FindModifierByName("modifier_item_socket_rune_legendary_drow_ranger_multishot")
		if runeMultishot then
			return runeMultishot.damageIncrease
		end
	end
end
