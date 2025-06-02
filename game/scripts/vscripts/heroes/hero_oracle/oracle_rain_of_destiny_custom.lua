LinkLuaModifier("modifier_oracle_rain_of_destiny_custom", "heroes/hero_oracle/oracle_rain_of_destiny_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_rain_of_destiny_custom_thinker", "heroes/hero_oracle/oracle_rain_of_destiny_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_rain_of_destiny_custom_buff", "heroes/hero_oracle/oracle_rain_of_destiny_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_rain_of_destiny_custom_debuff", "heroes/hero_oracle/oracle_rain_of_destiny_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

oracle_rain_of_destiny_custom = class(ItemBaseClass)
modifier_oracle_rain_of_destiny_custom = class(ItemBaseClassBuff)
modifier_oracle_rain_of_destiny_custom_thinker = class(ItemBaseClassBuff)
modifier_oracle_rain_of_destiny_custom_buff = class(ItemBaseClassBuff)
modifier_oracle_rain_of_destiny_custom_debuff = class(ItemBaseClassDebuff)
-------------
function oracle_rain_of_destiny_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function oracle_rain_of_destiny_custom:OnSpellStart()
    if not IsServer() then return end
    
    local caster = self:GetCaster()

    local point = self:GetCursorPosition()

    CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_oracle_rain_of_destiny_custom_thinker", -- modifier name
        {
            duration = self:GetSpecialValueFor("duration")
        }, -- kv
        point,
        caster:GetTeamNumber(),
        false
    )

    EmitSoundOn("Hero_Oracle.RainOfDestiny.Cast", caster)
end
-----------
function modifier_oracle_rain_of_destiny_custom_thinker:OnCreated()
    if not IsServer() then return end 

    -- references
    local tick_rate = self:GetAbility():GetSpecialValueFor("tick_rate")

    self.radius = self:GetAbility():GetSpecialValueFor("radius")

    -- Start interval
    self:StartIntervalThink( tick_rate )

    -- Create fow viewer
    AddFOWViewer( self:GetCaster():GetTeamNumber(), self:GetParent():GetOrigin(), self.radius, 3, true)

    -- effects
    self.effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_scepter_rain_of_destiny.vpcf", PATTACH_WORLDORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.effect_cast, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.effect_cast, 1, Vector(self.radius, self.radius, self.radius))

    EmitSoundOn("Hero_Oracle.RainOfDestiny", self:GetParent())
end

function modifier_oracle_rain_of_destiny_custom_thinker:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

	-- find enemies
	local targets = FindUnitsInRadius(
		caster:GetTeamNumber(),	-- int, your team number
		parent:GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_BOTH,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	for _,target in pairs(targets) do
        if caster:GetTeamNumber() ~= target:GetTeamNumber() then
            local mod = target:FindModifierByName("modifier_oracle_rain_of_destiny_custom_debuff")
            
            if not mod then
                mod = target:AddNewModifier(
                    caster, -- player source
                    self:GetAbility(), -- ability source
                    "modifier_oracle_rain_of_destiny_custom_debuff", -- modifier name
                    { duration = self:GetAbility():GetSpecialValueFor("debuff_duration") } -- kv
                )
            end

            if mod then
                mod:ForceRefresh()
            end
        else
            local mod = target:FindModifierByName("modifier_oracle_rain_of_destiny_custom_buff")
            
            if not mod then
                mod = target:AddNewModifier(
                    caster, -- player source
                    self:GetAbility(), -- ability source
                    "modifier_oracle_rain_of_destiny_custom_buff", -- modifier name
                    { duration = self:GetAbility():GetSpecialValueFor("buff_duration") } -- kv
                )
            end

            if mod then
                mod:ForceRefresh()
            end
        end
	end
end

function modifier_oracle_rain_of_destiny_custom_thinker:OnRemoved()
    if not IsServer() then return end 

    StopSoundOn("Hero_Oracle.RainOfDestiny", self:GetParent())

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    UTIL_Remove(self:GetParent())
end
--------
function modifier_oracle_rain_of_destiny_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET 
    }
end

function modifier_oracle_rain_of_destiny_custom_debuff:GetModifierHealAmplify_PercentageTarget()
    local amp = self:GetAbility():GetSpecialValueFor("heal_amp")
    if amp ~= nil then
        return -amp
    end
end

function modifier_oracle_rain_of_destiny_custom_debuff:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local interval = ability:GetSpecialValueFor("damage_interval")
    local parent = self:GetParent()

    self.effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_purifyingflames_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(self.effect_cast)

    self:OnIntervalThink()
    self:StartIntervalThink(interval)

    EmitSoundOn("Hero_Oracle.PurifyingFlames.Damage", parent)
    EmitSoundOn("Hero_Oracle.PurifyingFlames", parent)
end

function modifier_oracle_rain_of_destiny_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local damage = ability:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = damage,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    })
end

function modifier_oracle_rain_of_destiny_custom_debuff:OnRemoved()
    if not IsServer() then return end 

    StopSoundOn("Hero_Oracle.PurifyingFlames", self:GetParent())
end

function modifier_oracle_rain_of_destiny_custom_debuff:GetEffectName() return "particles/units/heroes/hero_phoenix/phoenix_supernova_radiance.vpcf" end

function modifier_oracle_rain_of_destiny_custom_debuff:AdvanceForward()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local interval = ability:GetSpecialValueFor("damage_interval")

    local remaining = self:GetRemainingTime()
    local damage = ability:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    local explosionDamage = (damage * remaining) / interval

    local vLocation = parent:GetAbsOrigin()

    local nFXIndex = ParticleManager:CreateParticle( "particles/econ/items/monkey_king/arcana/fire/monkey_king_spring_arcana_fire.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( nFXIndex, 0, vLocation)
    ParticleManager:SetParticleControl( nFXIndex, 1, Vector(ability:GetSpecialValueFor("explosion_radius"), ability:GetSpecialValueFor("explosion_radius"), 0))
    ParticleManager:SetParticleControl( nFXIndex, 3, vLocation)
    ParticleManager:SetParticleControl( nFXIndex, 5, Vector(ability:GetSpecialValueFor("explosion_radius"), ability:GetSpecialValueFor("explosion_radius"), 0))
    ParticleManager:ReleaseParticleIndex( nFXIndex )

    EmitSoundOnLocationWithCaster(vLocation, "Ability.LightStrikeArray", parent)
    EmitSoundOnLocationWithCaster(vLocation, "Ability.PreLightStrikeArray.ti7_layer", parent)

    --EmitSoundOn("Hero_ObsidianDestroyer.SanityEclipse.TI8", parent )
    local units = FindUnitsInRadius(parent:GetTeam(), vLocation, nil, ability:GetSpecialValueFor("explosion_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

    for i, target in ipairs(units) do  --Restore health and play a particle effect for every found ally.
        local damage = {
            victim = target,
            attacker = parent,
            damage = explosionDamage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability,
        }

        ApplyDamage( damage )
    end

    self:Destroy()
end
--------
function modifier_oracle_rain_of_destiny_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET 
    }
end

function modifier_oracle_rain_of_destiny_custom_buff:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("heal_amp")
end

function modifier_oracle_rain_of_destiny_custom_buff:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local interval = ability:GetSpecialValueFor("heal_interval")
    local parent = self:GetParent()

    self:OnIntervalThink()
    self:StartIntervalThink(interval)

    EmitSoundOn("Hero_Oracle.PurifyingFlames", parent)
end

function modifier_oracle_rain_of_destiny_custom_buff:OnRemoved()
    if not IsServer() then return end 

    StopSoundOn("Hero_Oracle.PurifyingFlames", self:GetParent())
end

function modifier_oracle_rain_of_destiny_custom_buff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local heal = parent:GetMaxHealth() * (ability:GetSpecialValueFor("heal_per_sec_pct")/100)

    parent:Heal(heal, self)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, heal, nil)
end

function modifier_oracle_rain_of_destiny_custom_buff:GetEffectName() return "particles/units/heroes/hero_oracle/oracle_purifyingflames.vpcf" end

function modifier_oracle_rain_of_destiny_custom_buff:AdvanceForward()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local interval = ability:GetSpecialValueFor("heal_interval")

    local remaining = self:GetRemainingTime()
    local heal = parent:GetMaxHealth() * (ability:GetSpecialValueFor("heal_per_sec_pct")/100)

    local healing = (heal * remaining) / interval

    EmitSoundOn("Hero_Oracle.FalsePromise.Healed", parent)

    local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_break_heal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(vfx, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfx)

    parent:Heal(healing, self)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, healing, nil)

    self:Destroy()
end