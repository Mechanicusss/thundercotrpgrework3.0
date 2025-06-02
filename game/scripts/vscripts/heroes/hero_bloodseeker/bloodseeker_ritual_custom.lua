LinkLuaModifier("modifier_bloodseeker_ritual_custom", "heroes/hero_bloodseeker/bloodseeker_ritual_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodseeker_ritual_custom_thinker", "heroes/hero_bloodseeker/bloodseeker_ritual_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodseeker_ritual_custom_debuff", "heroes/hero_bloodseeker/bloodseeker_ritual_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassThinker = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
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

bloodseeker_ritual_custom = class(ItemBaseClass)
modifier_bloodseeker_ritual_custom = class(bloodseeker_ritual_custom)
modifier_bloodseeker_ritual_custom_thinker = class(ItemBaseClassThinker)
modifier_bloodseeker_ritual_custom_debuff = class(ItemBaseClassDebuff)
-------------
function bloodseeker_ritual_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function bloodseeker_ritual_custom:GetHealthCost()
    return self:GetCaster():GetMaxHealth() * (self:GetSpecialValueFor("health_cost_pct")/100)
end

function bloodseeker_ritual_custom:OnSpellStart()
    if not IsServer() then return end
    
    local caster = self:GetCaster()

    local point = self:GetCursorPosition()

    self.damage = self:GetHealthCost(-1)

    CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_bloodseeker_ritual_custom_thinker", -- modifier name
        {}, -- kv
        point,
        caster:GetTeamNumber(),
        false
    )
end
-----------
function modifier_bloodseeker_ritual_custom_thinker:OnCreated()
    if not IsServer() then return end 

    -- references
    local delay = self:GetAbility():GetSpecialValueFor("delay")
    self.damage = self:GetAbility().damage
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.duration = self:GetAbility():GetSpecialValueFor("debuff_duration")
    local vision = 200

    -- Start interval
    self:StartIntervalThink( delay )

    -- Create fow viewer
    AddFOWViewer( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), vision, 3, true)

    -- effects
    self:PlayEffects1()
end

function modifier_bloodseeker_ritual_custom_thinker:OnIntervalThink()
	-- find enemies
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self:GetParent():GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	local damageTable = {
		-- victim = target,
		attacker = self:GetCaster(),
		damage = self.damage,
		damage_type = DAMAGE_TYPE_PURE,
		ability = self:GetAbility(), --Optional.
	}
	for _,enemy in pairs(enemies) do
		-- damage
		damageTable.victim = enemy
		ApplyDamage(damageTable)

        if self:GetCaster():HasScepter() then
		-- silence
            enemy:AddNewModifier(
                self:GetCaster(), -- player source
                self:GetAbility(), -- ability source
                "modifier_bloodseeker_ritual_custom_debuff", -- modifier name
                { duration = self.duration } -- kv
            )
        end

		-- effects
		self:PlayEffects3( enemy )
	end

	self:PlayEffects2()
	self:Destroy()
end

function modifier_bloodseeker_ritual_custom_thinker:OnRemoved()
    if not IsServer() then return end 

    UTIL_Remove(self:GetParent())
end

function modifier_bloodseeker_ritual_custom_thinker:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodritual_ring.vpcf"
	local sound_cast = "Hero_Bloodseeker.BloodRite"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( self.radius, self.radius, self.radius ) )

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end

function modifier_bloodseeker_ritual_custom_thinker:PlayEffects2()
	-- Get Resources
	-- local sound_cast = 

	ParticleManager:DestroyParticle( self.effect_cast, false )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

	-- Create Sound
	-- EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end

function modifier_bloodseeker_ritual_custom_thinker:PlayEffects3( target )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodritual_impact.vpcf"
	local sound_cast = "hero_bloodseeker.bloodRite.silence"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( sound_cast, target )
end
------------------
function modifier_bloodseeker_ritual_custom_debuff:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

function modifier_bloodseeker_ritual_custom_debuff:OnCreated()
    if not IsServer() then return end 

    self.ability = self:GetAbility()

    local interval = self.ability:GetSpecialValueFor("rupture_interval")

    self.ruptureDamage = self.ability:GetSpecialValueFor("rupture_current_hp_pct")

    self:StartIntervalThink(interval)
end

function modifier_bloodseeker_ritual_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    local damage = parent:GetHealth() * (self.ruptureDamage/100)

    local talent = caster:FindAbilityByName("talent_bloodseeker_1")
    if talent ~= nil and talent:GetLevel() > 1 then
        print("bonus damage:",self:GetAbility().damage)
        damage = damage + self:GetAbility().damage
    end

    ApplyDamage({
        victim = parent,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
        ability = self.ability
    })
end

function modifier_bloodseeker_ritual_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end