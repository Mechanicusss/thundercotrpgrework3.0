LinkLuaModifier("modifier_talent_tidehunter_1", "heroes/hero_tidehunter/talents/talent_tidehunter_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_tidehunter_1_debuff_frozen", "heroes/hero_tidehunter/talents/talent_tidehunter_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_generic_ring_lua", "modifiers/modifier_generic_ring_lua", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

talent_tidehunter_1 = class(ItemBaseClass)
modifier_talent_tidehunter_1 = class(talent_tidehunter_1)
modifier_talent_tidehunter_1_debuff_frozen = class(ItemBaseClassDebuff)
-------------
function talent_tidehunter_1:GetIntrinsicModifierName()
    return "modifier_talent_tidehunter_1"
end
-------------
function modifier_talent_tidehunter_1:OnCreated()
end

function modifier_talent_tidehunter_1:OnDestroy()
end

function modifier_talent_tidehunter_1:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED
    }
end

function modifier_talent_tidehunter_1:OnAbilityExecuted(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.unit ~= parent then return end 
    
    if event.ability:GetAbilityName() ~= "tidehunter_anchor_smash_custom" then return end 

    local ability = self:GetAbility()

    if not ability then return end 
    if ability:GetLevel() < 1 then return end

    self:CreateTsunami()
end

function modifier_talent_tidehunter_1:CalculateDamageMultiplier(distance_from_caster, max_distance, max_multiplier)
    -- Calculate linear damage reduction based on distance
    local linear_reduction = (max_distance - distance_from_caster) / max_distance

    -- Calculate exponential damage increase based on distance
    local decay_rate = -math.log(1 - (1 / max_multiplier)) / max_distance
    local exponential_increase = math.exp(-distance_from_caster * decay_rate)

    -- Combine linear and exponential factors
    local damage_multiplier = max_multiplier * linear_reduction * exponential_increase

    return damage_multiplier
end

function modifier_talent_tidehunter_1:CreateTsunami()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local startPosition = caster:GetAbsOrigin()

    local max_damage_multiplier = ability:GetSpecialValueFor("max_damage_multiplier")/100
    local damage = caster:GetStrength() * (ability:GetSpecialValueFor("attack_damage_pct")/100)
	local damage_type = ability:GetAbilityDamageType()
	local radius = ability:GetSpecialValueFor("radius")
	local speed = ability:GetSpecialValueFor("speed")
	local duration = ability:GetSpecialValueFor("freeze_duration")
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

		if ability:GetLevel() > 1 then
            EmitSoundOn("Hero_Ancient_Apparition.IceBlastRelease.Tick", enemy)
            -- stun
            enemy:AddNewModifier(
                caster, -- player source
                ability, -- ability source
                "modifier_talent_tidehunter_1_debuff_frozen", -- modifier name
                { duration = duration } -- kv
            )
        end

		-- play effects
		self:PlayEffects2( enemy )
	end)

	-- play effects
	self:PlayEffects1( caster:GetOrigin(), radius, speed )
end

function modifier_talent_tidehunter_1:PlayEffects1( center, radius, speed )
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

function modifier_talent_tidehunter_1:PlayEffects2( enemy )
	-- Get Resources
	local particle_cast = "particles/econ/items/tidehunter/tide_2021_immortal/tide_2021_ravage_hit_2.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, enemy )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end
------------
function modifier_talent_tidehunter_1_debuff_frozen:GetEffectName()
    return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_debuff.vpcf"
end

function modifier_talent_tidehunter_1_debuff_frozen:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DISABLE_HEALING,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_talent_tidehunter_1_debuff_frozen:GetDisableHealing()
    return 1
end

function modifier_talent_tidehunter_1_debuff_frozen:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("freeze_slow")
end

function modifier_talent_tidehunter_1_debuff_frozen:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    if ability:GetLevel() < 3 then return end 

    self:OnIntervalThink()
    self:StartIntervalThink(FrameTime())
end

function modifier_talent_tidehunter_1_debuff_frozen:OnIntervalThink()
    local ability = self:GetAbility()
    if ability:GetLevel() < 3 then 
        self:Destroy()
        return 
    end 

    local threshold = ability:GetSpecialValueFor("threshold")

    local parent = self:GetParent()

    if parent:GetHealthPercent() <= threshold then
        ApplyDamage({
            damage = parent:GetMaxHealth(),
            victim = parent,
            attacker = self:GetCaster(),
            damage_type = DAMAGE_TYPE_PURE
        })
    end
end