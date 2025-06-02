LinkLuaModifier("modifier_item_socket_rune_legendary_tidehunter_anchor_smash", "modifiers/runes/heroes/tidehunter/modifier_item_socket_rune_legendary_tidehunter_anchor_smash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_generic_ring_lua", "modifiers/modifier_generic_ring_lua", LUA_MODIFIER_MOTION_NONE )

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_tidehunter_anchor_smash = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_tidehunter_anchor_smash:OnCreated()
    self.maxDamageMultiplier = 100
    self.interval = 1.0
    self.speed = 725
    self.radius = 1250
    self.attackDamagePct = 100
end

function modifier_item_socket_rune_legendary_tidehunter_anchor_smash:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED
    }
end

function modifier_item_socket_rune_legendary_tidehunter_anchor_smash:OnAbilityExecuted(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.unit ~= parent then return end 
    
    if event.ability:GetAbilityName() ~= "tidehunter_anchor_smash_custom" then return end 

    self:CreateTsunami()
end

function modifier_item_socket_rune_legendary_tidehunter_anchor_smash:CalculateDamageMultiplier(distance_from_caster, max_distance, max_multiplier)
    -- Calculate linear damage reduction based on distance
    local linear_reduction = (max_distance - distance_from_caster) / max_distance

    -- Calculate exponential damage increase based on distance
    local decay_rate = -math.log(1 - (1 / max_multiplier)) / max_distance
    local exponential_increase = math.exp(-distance_from_caster * decay_rate)

    -- Combine linear and exponential factors
    local damage_multiplier = max_multiplier * linear_reduction * exponential_increase

    return damage_multiplier
end

function modifier_item_socket_rune_legendary_tidehunter_anchor_smash:CreateTsunami()
    local caster = self:GetCaster()
    local ability = caster:FindAbilityByName("tidehunter_anchor_smash_custom")

    local startPosition = caster:GetAbsOrigin()

    local max_damage_multiplier = self.maxDamageMultiplier/100
    local damage = caster:GetStrength() * (self.attackDamagePct/100)
	local damage_type = DAMAGE_TYPE_MAGICAL
	local radius = self.radius
	local speed = self.speed
    local width = 250
	local height = 350

    local damageTable = {
		attacker = caster,
		damage = damage,
		damage_type = damage_type,
		ability = ability,
	}

    local thinker = CreateModifierThinker(
		caster, -- player source
		ability, -- ability source
		"modifier_generic_ring_lua", -- modifier name
		{
			start_radius = width,
			end_radius = radius,
			speed = speed,
			width = width,
			target_team = DOTA_UNIT_TARGET_TEAM_ENEMY,
			target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		}, -- kv
		caster:GetOrigin(),
		caster:GetTeamNumber(),
		false
	)
	ring = thinker:FindModifierByName( "modifier_generic_ring_lua" )

	ring:SetCallback( function( enemy )
        local distance = (startPosition-enemy:GetAbsOrigin()):Length2D()

        -- damage
		damageTable.victim = enemy
        damageTable.damage = damageTable.damage * self:CalculateDamageMultiplier(distance, radius, max_damage_multiplier)

        ApplyDamage( damageTable )

        -- play effects
        local sound_target = "Ability.GushImpact"
        EmitSoundOn( sound_target, enemy )

		-- play effects
		self:PlayEffects2( enemy )
	end)

	-- play effects
	self:PlayEffects1( caster:GetOrigin(), radius, speed )
end

function modifier_item_socket_rune_legendary_tidehunter_anchor_smash:PlayEffects1( center, radius, speed )
	-- Get Resources
	local particle_cast = "particles/econ/items/tidehunter/tide_2021_immortal/tide_2021_ravage_2.vpcf"
	local sound_cast = "Hero_Tidehunter.Gush.AghsProjectile"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, center )
	for i=1,5 do
		-- local pos = actual_radius/5*i
		local pos = radius/5*i
		ParticleManager:SetParticleControl( effect_cast, i, Vector( pos, 1, 1 ) )
	end
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( center, sound_cast, self:GetCaster() )
end

function modifier_item_socket_rune_legendary_tidehunter_anchor_smash:PlayEffects2( enemy )
	-- Get Resources
	local particle_cast = "particles/econ/items/tidehunter/tide_2021_immortal/tide_2021_ravage_hit_2.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, enemy )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end