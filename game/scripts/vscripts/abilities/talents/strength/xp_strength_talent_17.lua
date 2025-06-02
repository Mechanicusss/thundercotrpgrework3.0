LinkLuaModifier("modifier_xp_strength_talent_17", "abilities/talents/strength/xp_strength_talent_17", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_strength_talent_17_debuff", "abilities/talents/strength/xp_strength_talent_17", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_strength_talent_17 = class(ItemBaseClass)
modifier_xp_strength_talent_17 = class(xp_strength_talent_17)
modifier_xp_strength_talent_17_debuff = class(ItemBaseClassDebuff)
-------------
function xp_strength_talent_17:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_17"
end
-------------
function modifier_xp_strength_talent_17:OnCreated()
end

function modifier_xp_strength_talent_17:OnDestroy()
end

function modifier_xp_strength_talent_17:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

local function FindNearestPointFromLine(caster, dir, affected)
	local castertoaffected = affected - caster
	local len = castertoaffected:Dot(dir)
	local ntgt = Vector(dir.x * len, dir.y * len, caster.z)
	return caster + ntgt
end

function modifier_xp_strength_talent_17:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    if not RollPercentage(1) then return end

    -- Ability properties
	local caster = self:GetCaster()
	local caster_position = caster:GetAbsOrigin()
	local target_point = target:GetAbsOrigin()

	-- Ability specials
	local slow_duration = 3
	local effect_delay = 2.7182
	local crack_width = 315
	local crack_distance = 1050
    local hpdmgpct = 15
	local crack_damage = hpdmgpct / 2
	local caster_fw = caster:GetForwardVector()
	local crack_ending = caster_position + caster_fw * crack_distance

	-- Play cast sound
	EmitSoundOn("Hero_ElderTitan.EarthSplitter.Cast", caster)

	-- Add start particle effect
	local particle_start_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(particle_start_fx, 0, caster_position)
	ParticleManager:SetParticleControl(particle_start_fx, 1, crack_ending)
	ParticleManager:SetParticleControl(particle_start_fx, 3, Vector(0, effect_delay, 0))

	-- Wait for the effect delay
	Timers:CreateTimer(effect_delay, function()
		EmitSoundOn("Hero_ElderTitan.EarthSplitter.Destroy", caster)

		local enemies = FindUnitsInLine(caster:GetTeamNumber(), caster_position, crack_ending, nil, crack_width, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE)
		for _, enemy in pairs(enemies) do
			enemy:Interrupt()
			enemy:AddNewModifier(caster, nil, "modifier_xp_strength_talent_17_debuff", {duration = slow_duration})

			ApplyDamage({victim = enemy, attacker = caster, damage = enemy:GetMaxHealth() * crack_damage * 0.01, damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION })
			ApplyDamage({victim = enemy, attacker = caster, damage = enemy:GetMaxHealth() * crack_damage * 0.01, damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION })
			local closest_point = FindNearestPointFromLine(caster_position, caster_fw, enemy:GetAbsOrigin())
			FindClearSpaceForUnit(enemy, closest_point, false)
		end

		ParticleManager:ReleaseParticleIndex(particle_start_fx)
	end)
end
-----------
function modifier_xp_strength_talent_17_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_xp_strength_talent_17_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -40
end