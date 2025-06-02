snapfire_lil_shredder_custom = class({})
LinkLuaModifier( "modifier_snapfire_lil_shredder_custom", "heroes/hero_snapfire/snapfire_lil_shredder_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_snapfire_lil_shredder_custom_debuff", "heroes/hero_snapfire/snapfire_lil_shredder_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function snapfire_lil_shredder_custom:OnToggle()
	-- unit identifier
	local caster = self:GetCaster()

	if self:GetToggleState() then
        -- addd buff
        caster:AddNewModifier(
            caster, -- player source
            self, -- ability source
            "modifier_snapfire_lil_shredder_custom", -- modifier name
            {} -- kv
        )
    else
        caster:RemoveModifierByName("modifier_snapfire_lil_shredder_custom")
    end
end

function snapfire_lil_shredder_custom:GetCastRange()
	return self:GetCaster():Script_GetAttackRange()
end

modifier_snapfire_lil_shredder_custom_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_snapfire_lil_shredder_custom_debuff:IsHidden()
	return false
end

function modifier_snapfire_lil_shredder_custom_debuff:IsDebuff()
	return true
end

function modifier_snapfire_lil_shredder_custom_debuff:IsStunDebuff()
	return false
end

function modifier_snapfire_lil_shredder_custom_debuff:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_snapfire_lil_shredder_custom_debuff:OnCreated( kv )
	self:SetHasCustomTransmitterData(true)

	if not IsServer() then return end
	
	-- references
	self.armor = self:GetAbility():GetSpecialValueFor( "armor_per_stack" )

	self.damage = self:GetParent():GetPhysicalArmorBaseValue() * (self.armor/100) * self:GetStackCount()

	self:InvokeBonusDamage()
end

function modifier_snapfire_lil_shredder_custom_debuff:OnRefresh( kv )
	if not IsServer() then return end

	-- references
	self.armor = self:GetAbility():GetSpecialValueFor( "armor_per_stack" )

	self.damage = self:GetParent():GetPhysicalArmorBaseValue() * (self.armor/100) * self:GetStackCount()

	self:InvokeBonusDamage()
end

function modifier_snapfire_lil_shredder_custom_debuff:OnRemoved()
end

function modifier_snapfire_lil_shredder_custom_debuff:OnDestroy()
end

function modifier_snapfire_lil_shredder_custom_debuff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_snapfire_lil_shredder_custom_debuff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_snapfire_lil_shredder_custom_debuff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_snapfire_lil_shredder_custom_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}

	return funcs
end

function modifier_snapfire_lil_shredder_custom_debuff:GetModifierPhysicalArmorBonus()
	return self.fDamage
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_snapfire_lil_shredder_custom_debuff:GetEffectName()
	-- return "particles/units/heroes/hero_snapfire/hero_snapfire_slow_debuff.vpcf"
	return "particles/units/heroes/hero_sniper/sniper_headshot_slow.vpcf"
end

function modifier_snapfire_lil_shredder_custom_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

modifier_snapfire_lil_shredder_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_snapfire_lil_shredder_custom:IsHidden()
	return false
end

function modifier_snapfire_lil_shredder_custom:IsDebuff()
	return false
end

function modifier_snapfire_lil_shredder_custom:IsStunDebuff()
	return false
end

function modifier_snapfire_lil_shredder_custom:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_snapfire_lil_shredder_custom:OnCreated( kv )
	-- references
	self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.as_bonus = self:GetAbility():GetSpecialValueFor( "attack_speed_bonus" )
	self.range_bonus = self:GetAbility():GetSpecialValueFor( "attack_range_bonus" )
	self.bat = self:GetAbility():GetSpecialValueFor( "base_attack_time" )

	self.slow = self:GetAbility():GetSpecialValueFor( "slow_duration" )

	if not IsServer() then return end

	self.records = {}
    self.target = nil

	-- play Effects & Sound
	self:PlayEffects()
	local sound_cast = "Hero_Snapfire.ExplosiveShells.Cast"
	EmitSoundOn( sound_cast, self:GetParent() )

    self:StartIntervalThink(FrameTime())
end

function modifier_snapfire_lil_shredder_custom:CheckState()
    return {
        [MODIFIER_STATE_IGNORING_STOP_ORDERS] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
    }
end

function modifier_snapfire_lil_shredder_custom:OnIntervalThink()
    local ability = self:GetAbility()
    local manaCost = ability:GetSpecialValueFor("mana_cost_pct") + (ability:GetSpecialValueFor("mana_cost_pct_incrase_sec")*self:GetElapsedTime())
    
    local parent = self:GetParent()
    local cost = parent:GetMaxMana() * (manaCost/100) * 0.1

	local range = ability:GetEffectiveCastRange(parent:GetAbsOrigin(), nil)

    if (cost > parent:GetMana() or parent:IsSilenced() or parent:IsHexed()) and ability:GetToggleState() then
        self:StartIntervalThink(-1)
        ability:ToggleAbility()
        self:Destroy()
        return
    end
	
    if not self.target then
        local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
			range, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
            FIND_CLOSEST, false)

        for _,enemy in ipairs(victims) do
            if not enemy:IsAlive() or ((parent:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D() > parent:Script_GetAttackRange()) then break end

            self.target = enemy 
            break
        end
    end

    if self.target ~= nil and not self.target:IsNull() then
        if not self.target:IsAlive() then
            self.target = nil
        else
            parent:MoveToTargetToAttack(self.target)
        end
    end

    parent:SpendMana(cost, ability)
end

function modifier_snapfire_lil_shredder_custom:OnRefresh( kv )
	-- references
	self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.as_bonus = self:GetAbility():GetSpecialValueFor( "attack_speed_bonus" )
	self.range_bonus = self:GetAbility():GetSpecialValueFor( "attack_range_bonus" )
	self.bat = self:GetAbility():GetSpecialValueFor( "base_attack_time" )

	self.slow = self:GetAbility():GetSpecialValueFor( "slow_duration" )

	if not IsServer() then return end

	-- play sound
	local sound_cast = "Hero_Snapfire.ExplosiveShells.Cast"
	EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_snapfire_lil_shredder_custom:OnRemoved()
end

function modifier_snapfire_lil_shredder_custom:OnDestroy()
	if not IsServer() then return end

	-- stop sound
	local sound_cast = "Hero_Snapfire.ExplosiveShells.Cast"
	StopSoundOn( sound_cast, self:GetParent() )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_snapfire_lil_shredder_custom:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,

		MODIFIER_PROPERTY_PROJECTILE_NAME,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		--MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
	}

	return funcs
end

function modifier_snapfire_lil_shredder_custom:GetPriority() return 999 end

function modifier_snapfire_lil_shredder_custom:OnAttack( params )
	if params.attacker~=self:GetParent() then return end

	-- record attack
	self.records[params.record] = true

	-- play sound
	local sound_cast = "Hero_Snapfire.ExplosiveShellsBuff.Attack"
	EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_snapfire_lil_shredder_custom:OnAttackLanded( params )
	if self.records[params.record] then
		-- add modifier
		local debuff = params.target:FindModifierByName("modifier_snapfire_lil_shredder_custom_debuff")
		
		if not debuff then
			debuff = params.target:AddNewModifier(
				self:GetParent(), -- player source
				self:GetAbility(), -- ability source
				"modifier_snapfire_lil_shredder_custom_debuff", -- modifier name
				{ duration = self.slow } -- kv
			)
		end

		if debuff then
			if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
				debuff:IncrementStackCount()
			end
			
			debuff:ForceRefresh()
		end
	end

	-- play sound
	local sound_cast = "Hero_Snapfire.ExplosiveShellsBuff.Target"
	EmitSoundOn( sound_cast, params.target )
end

function modifier_snapfire_lil_shredder_custom:OnAttackRecordDestroy( params )
	if self.records[params.record] then
		self.records[params.record] = nil
	end
end

function modifier_snapfire_lil_shredder_custom:GetModifierProjectileName()
	return "particles/units/heroes/hero_snapfire/hero_snapfire_shells_projectile.vpcf"
end

function modifier_snapfire_lil_shredder_custom:GetModifierPreAttack_BonusDamage()
	return self.damage
end

function modifier_snapfire_lil_shredder_custom:GetModifierAttackRangeBonus()
	return self.range_bonus
end

function modifier_snapfire_lil_shredder_custom:GetModifierAttackSpeedBonus_Constant()
	return self.as_bonus
end

function modifier_snapfire_lil_shredder_custom:GetModifierBaseAttackTimeConstant()
	return self.bat
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_snapfire_lil_shredder_custom:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_snapfire/hero_snapfire_shells_buff.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		3,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		4,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		5,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
end