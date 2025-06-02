LinkLuaModifier("modifier_item_witch_blade_custom", "items/item_witch_blade_custom/item_witch_blade_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_witch_blade_custom_poison", "items/item_witch_blade_custom/item_witch_blade_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_witch_blade_custom_thinker", "items/item_witch_blade_custom/item_witch_blade_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_witch_blade_custom_thinker_debuff", "items/item_witch_blade_custom/item_witch_blade_custom", LUA_MODIFIER_MOTION_NONE)

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

item_witch_blade_custom = class(ItemBaseClass)
item_witch_blade_custom2 = item_witch_blade_custom
item_witch_blade_custom3 = item_witch_blade_custom
item_witch_blade_custom4 = item_witch_blade_custom
item_witch_blade_custom5 = item_witch_blade_custom
item_witch_blade_custom6 = item_witch_blade_custom
item_witch_blade_custom7 = item_witch_blade_custom
item_witch_blade_custom8 = item_witch_blade_custom
item_witch_blade_custom9 = item_witch_blade_custom
modifier_item_witch_blade_custom = class(item_witch_blade_custom)
modifier_item_witch_blade_custom_poison = class(ItemBaseClassDebuff)
modifier_item_witch_blade_custom_thinker = class(ItemBaseClassDebuff)
modifier_item_witch_blade_custom_thinker_debuff = class(ItemBaseClassDebuff)
-------------
function item_witch_blade_custom:GetIntrinsicModifierName()
    return "modifier_item_witch_blade_custom"
end

function modifier_item_witch_blade_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, --GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS, --GetModifierProjectileSpeedBonus

        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_witch_blade_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_witch_blade_custom:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_witch_blade_custom:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_witch_blade_custom:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_witch_blade_custom:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

function modifier_item_witch_blade_custom:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end

function modifier_item_witch_blade_custom:GetModifierProjectileSpeedBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_projectile_speed")
end

function modifier_item_witch_blade_custom:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    local duration = ability:GetSpecialValueFor("poison_duration")

    local debuff = target:FindModifierByName("modifier_item_witch_blade_custom_poison")
    if not debuff then
        debuff = target:AddNewModifier(parent, ability, "modifier_item_witch_blade_custom_poison", {
            duration = duration
        })
    end

    if debuff then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("poison_max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end

    ability:UseResources(false, false, false, true)
end
----------------
function modifier_item_witch_blade_custom_poison:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_item_witch_blade_custom_poison:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    CreateModifierThinker(
        self:GetCaster(), -- player source
        self:GetAbility(), -- ability source
        "modifier_item_witch_blade_custom_thinker", -- modifier name
        {
            duration = self:GetAbility():GetSpecialValueFor("pool_duration")
        }, -- kv
        parent:GetAbsOrigin(),
        self:GetCaster():GetTeamNumber(),
        false
    )
end

function modifier_item_witch_blade_custom_poison:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("poison_slow")
end

function modifier_item_witch_blade_custom_poison:OnCreated()
    if not IsServer() then return end 

    self.canSpread = true

    self:StartIntervalThink(1)
end

function modifier_item_witch_blade_custom_poison:OnIntervalThink()
    local ability = self:GetAbility()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    local damage = caster:GetPrimaryStatValue() * ability:GetSpecialValueFor("poison_attribute_scaling_multiplier") * self:GetStackCount()

    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, parent, damage, nil)

    local chance = ability:GetSpecialValueFor("poison_spread_chance")
    local radius = ability:GetSpecialValueFor("poison_spread_range")
    local duration = ability:GetSpecialValueFor("poison_duration")

    if not self.canSpread then return end
    if not RollPercentage(chance) then return end 

    local victims = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and not victim:IsMagicImmune() and not victim:HasModifier("modifier_item_witch_blade_custom_poison") then
            local debuff = victim:FindModifierByName("modifier_item_witch_blade_custom_poison")
            if not debuff then
                debuff = victim:AddNewModifier(caster, ability, "modifier_item_witch_blade_custom_poison", {
                    duration = duration
                })
            end

            if debuff then
                if debuff:GetStackCount() < ability:GetSpecialValueFor("poison_max_stacks") then
                    debuff:IncrementStackCount()
                end
                
                debuff:ForceRefresh()
            end

            self:PlayEffects(victim)

            self.canSpread = false 

            break
        end
    end
end

function modifier_item_witch_blade_custom_poison:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/bloodletting_blade/spectre_arcana_v2_dispersion_2.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    -- ParticleManager:SetParticleControl( effect_cast, 1, vControlVector )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
--------
function modifier_item_witch_blade_custom_thinker:OnCreated()
    if not IsServer() then return end 

    -- references
    self.damage = self:GetAbility():GetSpecialValueFor("pool_damage")
    self.radius = self:GetAbility():GetSpecialValueFor("pool_radius")
    self.duration = self:GetAbility():GetSpecialValueFor("pool_debuff_duration")
    
    local vision = 200

    -- Start interval
    self:StartIntervalThink( 1 )

    -- Create fow viewer
    AddFOWViewer( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), vision, 3, true)

    EmitSoundOn("Hero_Viper.NetherToxin.Cast", self:GetParent())
    EmitSoundOn("Hero_Viper.NetherToxin", self:GetParent())

    local particle_cast = "particles/econ/items/viper/viper_immortal_tail_ti8/viper_immortal_ti8_nethertoxin.vpcf"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
end

function modifier_item_witch_blade_custom_thinker:OnIntervalThink()
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
		-- damage
		damageTable.victim = enemy
		ApplyDamage(damageTable)

        EmitSoundOn("Hero_Viper.NetherToxin.Damage", enemy)

        enemy:AddNewModifier(
            self:GetCaster(), -- player source
            self:GetAbility(), -- ability source
            "modifier_item_witch_blade_custom_thinker_debuff", -- modifier name
            { duration = self.duration } -- kv
        )

        SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, enemy, self.damage, nil)
	end
end

function modifier_item_witch_blade_custom_thinker:OnRemoved()
    if not IsServer() then return end 

    StopSoundOn("Hero_Viper.NetherToxin", self:GetParent())

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    UTIL_Remove(self:GetParent())
end
-------------
function modifier_item_witch_blade_custom_thinker_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_item_witch_blade_custom_thinker_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("pool_reduction")
end

function modifier_item_witch_blade_custom_thinker_debuff:GetEffectName() return "particles/econ/items/viper/viper_immortal_tail_ti8/viper_immortal_ti8_nethertoxin_debuff.vpcf" end