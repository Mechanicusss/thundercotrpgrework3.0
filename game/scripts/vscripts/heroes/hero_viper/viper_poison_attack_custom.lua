viper_poison_attack_custom = class({})
LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_viper_poison_attack_custom", "heroes/hero_viper/viper_poison_attack_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_viper_poison_attack_custom_debuff", "heroes/hero_viper/viper_poison_attack_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_viper_poison_attack_custom_thinker", "heroes/hero_viper/viper_poison_attack_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_viper_poison_attack_custom_thinker_cd", "heroes/hero_viper/viper_poison_attack_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_obsidian_essence_flux", "heroes/hero_viper/obsidian_essence_flux.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

modifier_viper_poison_attack_custom_debuff = class(ItemBaseClassDebuff)
modifier_viper_poison_attack_custom_thinker = class(ItemBaseClassDebuff)
modifier_viper_poison_attack_custom_thinker_cd = class(ItemBaseClassDebuff)
--------------------------------------------------------------------------------
-- Passive Modifier
function viper_poison_attack_custom:GetIntrinsicModifierName()
    return "modifier_generic_orb_effect_lua"
end

--------------------------------------------------------------------------------
-- Ability Start
function viper_poison_attack_custom:OnSpellStart()
end
--------------------------------------------------------------------------------
-- Orb Effects
function viper_poison_attack_custom:GetProjectileName()
    return "particles/units/heroes/hero_viper/viper_poison_attack.vpcf"
end

function viper_poison_attack_custom:OnOrbFire( params )
    -- play effects
    local sound_cast = "hero_viper.poisonAttack.Cast"
    EmitSoundOn( sound_cast, self:GetCaster() )
end

function viper_poison_attack_custom:OnOrbImpact( params )
    local caster = self:GetCaster()

    local target = params.target 
    
    local debuff = target:FindModifierByName("modifier_viper_poison_attack_custom_debuff")
    if not debuff then
        debuff = target:AddNewModifier(caster, self, "modifier_viper_poison_attack_custom_debuff", { duration = self:GetSpecialValueFor("duration") })
    end

    if debuff then
        if debuff:GetStackCount() < self:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()

        if (debuff:GetStackCount() % self:GetSpecialValueFor("stack_trigger_count") == 0) and not caster:HasModifier("modifier_viper_poison_attack_custom_thinker_cd") then
            CreateModifierThinker(
                caster, -- player source
                self, -- ability source
                "modifier_viper_poison_attack_custom_thinker", -- modifier name
                {
                    duration = self:GetSpecialValueFor("pool_duration"),
                    stackCount = debuff:GetStackCount()
                }, -- kv
                target:GetAbsOrigin(),
                caster:GetTeamNumber(),
                false
            )

            caster:AddNewModifier(caster, self, "modifier_viper_poison_attack_custom_thinker_cd", { duration = self:GetSpecialValueFor("pool_duration") })
        end
    end

    -- play effects
    local sound_cast = "hero_viper.PoisonAttack.Target"
    EmitSoundOn( sound_cast, params.target )
end
-------------------
function modifier_viper_poison_attack_custom_debuff:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(1)
end

function modifier_viper_poison_attack_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local damage = (ability:GetSpecialValueFor("damage") + (caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("damage_from_attack")/100))) * self:GetStackCount()

    if parent:IsMagicImmune() then return end

    if parent:HasModifier("modifier_viper_viper_strike_custom_debuff") and caster:HasScepter() then
        local viperStrike = caster:FindAbilityByName("viper_viper_strike_custom")
        if viperStrike ~= nil and viperStrike:GetLevel() > 0 then
            damage = damage * viperStrike:GetSpecialValueFor("damage_multiplier")
        end
    end
    
    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, parent, damage, nil)
end

function modifier_viper_poison_attack_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_viper_poison_attack_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    local slow = self:GetAbility():GetSpecialValueFor("slow") * self:GetStackCount()
    local maxSlow = self:GetAbility():GetSpecialValueFor("max_slow")

    if slow <= maxSlow then
        slow = maxSlow
    end

    return slow
end

function modifier_viper_poison_attack_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_viper/viper_poison_debuff.vpcf"
end
--------------------
function modifier_viper_poison_attack_custom_thinker:OnCreated(params)
    if not IsServer() then return end 

    self.stacks = params.stackCount

    -- references
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    self.damage = (ability:GetSpecialValueFor("damage") + (caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("damage_from_attack")/100))) * self.stacks

    self.radius = ability:GetSpecialValueFor("pool_radius")
    
    local vision = 200

    -- Start interval
    self:StartIntervalThink( 1 )

    -- Create fow viewer
    AddFOWViewer( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), vision, 3, true)

    EmitSoundOn("Hero_Viper.NetherToxin.Cast", self:GetParent())
    EmitSoundOn("Hero_Viper.NetherToxin", self:GetParent())

    local particle_cast = "particles/units/heroes/hero_viper/viper_nethertoxin.vpcf"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( self.radius, 1, 1 ) )
end

function modifier_viper_poison_attack_custom_thinker:OnIntervalThink()
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
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(), --Optional.
	}

	for _,enemy in pairs(enemies) do
        if not enemy:IsMagicImmune() then
            -- damage
            damageTable.victim = enemy

            if enemy:HasModifier("modifier_viper_viper_strike_custom_debuff") and self:GetCaster():HasScepter() then
                local viperStrike = self:GetCaster():FindAbilityByName("viper_viper_strike_custom")
                if viperStrike ~= nil and viperStrike:GetLevel() > 0 then
                    damageTable.damage = damageTable.damage * viperStrike:GetSpecialValueFor("damage_multiplier")
                end
            end

            ApplyDamage(damageTable)

            EmitSoundOn("Hero_Viper.NetherToxin.Damage", enemy)

            SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, enemy, self.damage, nil)
        end
	end
end

function modifier_viper_poison_attack_custom_thinker:OnRemoved()
    if not IsServer() then return end 

    StopSoundOn("Hero_Viper.NetherToxin", self:GetParent())

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    UTIL_Remove(self:GetParent())
end
--------
function modifier_viper_poison_attack_custom_thinker_cd:IsHidden() return true end