------------------------------------
--       REQUIEM OF SOULS         --
------------------------------------
nevermore_requiem_custom = nevermore_requiem_custom or class({})
LinkLuaModifier("modifier_tcotrpg_reqiuem_intrinsic", "heroes/hero_nevermore/nevermore_requiem_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tcotrpg_reqiuem_debuff", "heroes/hero_nevermore/nevermore_requiem_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassdeBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

modifier_tcotrpg_reqiuem_intrinsic = class(ItemBaseClass)
modifier_tcotrpg_reqiuem_debuff = class(ItemBaseClassdeBuff)

function nevermore_requiem_custom:GetIntrinsicModifierName()
    return "modifier_tcotrpg_reqiuem_intrinsic"
end

function nevermore_requiem_custom:GetAbilityTextureName()
   return "nevermore_requiem"
end

function nevermore_requiem_custom:IsHiddenWhenStolen()
	return false
end

function nevermore_requiem_custom:GetAssociatedSecondaryAbilities()
	return "nevermore_necromastery_custom"
end
-------------------
function modifier_tcotrpg_reqiuem_intrinsic:OnCreated()
    if not IsServer() then return end 

    self.proc = false
end 

function modifier_tcotrpg_reqiuem_intrinsic:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ATTACK_CANCELLED 
    }
end

function modifier_tcotrpg_reqiuem_intrinsic:OnAttackCancelled(event)
    if not IsServer() then return end 

    local parent = self:GetParent() 

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    self.proc = false

    self:GetCaster():StopSound(self.sound)
	
	if self.wings_particle then
		ParticleManager:DestroyParticle(self.wings_particle, true)
		ParticleManager:ReleaseParticleIndex(self.wings_particle)
	end
end

function modifier_tcotrpg_reqiuem_intrinsic:OnAttackStart(event)
    if not IsServer() then return end 

    local parent = self:GetParent() 

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    local necromasteryMod = parent:FindModifierByName("modifier_nevermore_necromastery_custom")
    if not necromasteryMod then return end
    if necromasteryMod:GetStackCount() < 1 then return end

    local ability = self:GetAbility()
    if not ability:IsCooldownReady() then return end
    if not ability:GetAutoCastState() then return end

    local chance = ability:GetSpecialValueFor("chance")

	if not RollPercentage(chance) then
        return
    end

    self.sound = "Hero_Nevermore.RequiemOfSoulsCast"

	-- Play sound
	self:GetCaster():EmitSound(self.sound)
	
	self.wings_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_wings.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())

    self.proc = true 
end 

function modifier_tcotrpg_reqiuem_intrinsic:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent() 

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end
    if not self.proc then return end

    local ability = self:GetAbility()

    local caster = self:GetCaster()
	local cast_response = {"nevermore_nev_ability_requiem_01", "nevermore_nev_ability_requiem_02", "nevermore_nev_ability_requiem_03", "nevermore_nev_ability_requiem_04", "nevermore_nev_ability_requiem_05", "nevermore_nev_ability_requiem_06", "nevermore_nev_ability_requiem_07", "nevermore_nev_ability_requiem_08", "nevermore_nev_ability_requiem_11", "nevermore_nev_ability_requiem_12", "nevermore_nev_ability_requiem_13", "nevermore_nev_ability_requiem_14"}
	local sound_cast = "Hero_Nevermore.RequiemOfSouls"
	local particle_caster_souls = "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_a.vpcf"
	local particle_caster_ground = "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls.vpcf"
	local modifier_souls = "modifier_nevermore_necromastery_custom"

	-- Ability specials
	local souls_per_line = ability:GetSpecialValueFor("requiem_soul_conversion")
	local travel_distance = ability:GetSpecialValueFor("requiem_radius")

    local necromasteryMod = parent:FindModifierByName("modifier_nevermore_necromastery_custom")
    local necromasteryStacks = 0

    if necromasteryMod then
        necromasteryStacks = necromasteryMod:GetStackCount()
    end

    local line_count = math.floor(necromasteryStacks / souls_per_line)
    local line_max = ability:GetSpecialValueFor("max_lines")
    if line_count > line_max then
        line_count = line_max
    end

	-- Play cast response
	EmitSoundOn(cast_response[math.random(1, #cast_response)], caster)

	-- Play cast sound
	EmitSoundOn(sound_cast, caster)

	if self.wings_particle then
		ParticleManager:ReleaseParticleIndex(self.wings_particle)
	end

	-- Add particles for the caster and the ground
	local particle_caster_souls_fx = ParticleManager:CreateParticle(particle_caster_souls, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle_caster_souls_fx, 0, event.target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_caster_souls_fx, 1, Vector(line_count, 0, 0))
	ParticleManager:SetParticleControl(particle_caster_souls_fx, 2, event.target:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(particle_caster_souls_fx)

	local particle_caster_ground_fx = ParticleManager:CreateParticle(particle_caster_ground, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle_caster_ground_fx, 0, event.target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_caster_ground_fx, 1, Vector(line_count, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle_caster_ground_fx)

    local line_position = event.target:GetAbsOrigin() + caster:GetForwardVector() * travel_distance

	if necromasteryStacks >= 1 then
		-- Create the first line
		CreateRequiemSoulLine(event.target, caster, ability, line_position)
	end

	-- Calculate the location of every other line
	local qangle_rotation_rate = 360 / line_count
	for i = 1, line_count - 1 do
		local qangle = QAngle(0, qangle_rotation_rate, 0)
		line_position = RotatePosition(event.target:GetAbsOrigin(), qangle, line_position)

		-- Create every other line
		CreateRequiemSoulLine(event.target, caster, ability, line_position)
	end

    self.proc = false 

    self:GetCaster():StopSound(self.sound)
	
	if self.wings_particle then
		ParticleManager:DestroyParticle(self.wings_particle, true)
		ParticleManager:ReleaseParticleIndex(self.wings_particle)
	end

    ability:UseResources(false, false, false, true)
end 
-------------------
function nevermore_requiem_custom:OnProjectileHit_ExtraData(target, location, extra_data)
	-- If there was no target, do nothing
	if not target then
		return nil
	end

	-- Ability properties
	local caster = self:GetCaster()
	local ability = self
	local modifier_debuff = "modifier_tcotrpg_reqiuem_debuff"
	local scepter_line = extra_data.scepter_line

	-- Ability specials
	local damage = ((caster:GetAgility() * (ability:GetSpecialValueFor("all_to_damage")/100)) + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("all_to_damage")/100)) + (caster:GetStrength() * (ability:GetSpecialValueFor("all_to_damage")/100)))
	local slow_duration = ability:GetSpecialValueFor("requiem_slow_duration")
	local scepter_line_damage_pct = ability:GetSpecialValueFor("requiem_damage_pct_scepter")

	-- Convert from string to bool
	if scepter_line == 0 then
		scepter_line = false
	else
		scepter_line = true
	end

	-- Apply the debuff on enemies hit
	target:AddNewModifier(caster, ability, modifier_debuff, {duration = slow_duration})

	-- If this line is a scepter line, reduce the damage
	if scepter_line then
		damage = damage * (scepter_line_damage_pct * 0.01)
	end
	
	target:EmitSound("Hero_Nevermore.RequiemOfSouls.Damage")
	
	-- Damage the target
	local damageTable = {victim = target,
						damage = damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
						attacker = caster,
						ability = ability
						}

	local damage_dealt = ApplyDamage(damageTable)

    target:AddNewModifier(caster, ability, modifier_debuff, {
        duration = slow_duration
    })

	-- If this line is a scepter line, heal the caster for the actual damage dealt
	if scepter_line then
		caster:Heal(damage_dealt, caster)
	end
end


function CreateRequiemSoulLine(target, caster, ability, line_end_position)
	-- Ability properties
	local particle_lines = "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf"
	local scepter = caster:HasScepter()

	-- Ability specials
	local travel_distance = ability:GetSpecialValueFor("requiem_radius")
	local lines_starting_width = ability:GetSpecialValueFor("requiem_line_width_start")
	local lines_end_width = ability:GetSpecialValueFor("requiem_line_width_end")
	local travel_distance = ability:GetSpecialValueFor("requiem_radius")
	local lines_travel_speed = ability:GetSpecialValueFor("requiem_line_speed")

	-- Calculate the time that it would take to reach the maximum distance
	local max_distance_time = travel_distance / lines_travel_speed

	-- Calculate velocity
	local velocity = (line_end_position - target:GetAbsOrigin()):Normalized() * lines_travel_speed

	-- Launch the line
	projectile_info = {Ability = ability,
					   EffectName = particle_lines,
					   vSpawnOrigin = target:GetAbsOrigin(),
					   fDistance = travel_distance,
					   fStartRadius = lines_starting_width,
					   fEndRadius = lines_end_width,
					   Source = caster,
					   bHasFrontalCone = false,
					   bReplaceExisting = false,
					   iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
					   iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
					   iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
					   bDeleteOnHit = false,
					   vVelocity = velocity,
					   bProvidesVision = false,
					   ExtraData = {scepter_line = false }
					   }

	-- Create the projectile
	ProjectileManager:CreateLinearProjectile(projectile_info)

	-- Create the particle
	local particle_lines_fx = ParticleManager:CreateParticle(particle_lines, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle_lines_fx, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_lines_fx, 1, velocity)
	ParticleManager:SetParticleControl(particle_lines_fx, 2, Vector(0, max_distance_time, 0))
	ParticleManager:ReleaseParticleIndex(particle_lines_fx)

	-- If the caster has a Scepter, wait for line to finish, then summon the lines back to the caster
	-- Doesn't trigger when triggered from caster's death
	if scepter then
		Timers:CreateTimer(max_distance_time, function()
			-- Calculate velocity
			local velocity = (target:GetAbsOrigin() - line_end_position):Normalized() * lines_travel_speed

			-- Launch the line
			projectile_info = {Ability = ability,
							   EffectName = particle_lines,
							   vSpawnOrigin = line_end_position,
							   fDistance = travel_distance,
							   fStartRadius = lines_end_width,
							   fEndRadius = lines_starting_width,
							   Source = caster,
							   bHasFrontalCone = false,
							   bReplaceExisting = false,
							   iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
							   iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
							   iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
							   bDeleteOnHit = false,
							   vVelocity = velocity,
							   bProvidesVision = false,
							   ExtraData = {scepter_line = true}
							   }

			-- Create the projectile
			ProjectileManager:CreateLinearProjectile(projectile_info)

			-- Create the particle
			local particle_lines_fx = ParticleManager:CreateParticle(particle_lines, PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(particle_lines_fx, 0, line_end_position)
			ParticleManager:SetParticleControl(particle_lines_fx, 1, velocity)
			ParticleManager:SetParticleControl(particle_lines_fx, 2, Vector(0, max_distance_time, 0))
			ParticleManager:ReleaseParticleIndex(particle_lines_fx)
		end)
	end
end

----------------------
function modifier_tcotrpg_reqiuem_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_tcotrpg_reqiuem_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("requiem_reduction_mres")
end

function modifier_tcotrpg_reqiuem_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("requiem_reduction_ms")
end