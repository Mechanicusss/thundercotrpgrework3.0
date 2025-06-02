modifier_underlord_firestorm_custom_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_underlord_firestorm_custom_debuff:IsHidden()
    return false
end

function modifier_underlord_firestorm_custom_debuff:IsDebuff()
    return true
end

function modifier_underlord_firestorm_custom_debuff:IsStunDebuff()
    return false
end

function modifier_underlord_firestorm_custom_debuff:IsPurgable()
    return true
end

function modifier_underlord_firestorm_custom_debuff:IsStackable()
    return true
end

function modifier_underlord_firestorm_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_underlord_firestorm_custom_debuff:OnCreated( kv )
    -- references
    if not IsServer() then return end
    local interval = kv.interval
    self.damage = kv.damage
    self.damage_pct = kv.damage/100

    -- precache damage
    self.damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        -- damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(), --Optional.
    }
    -- ApplyDamage(damageTable)

    -- Start interval
    self:StartIntervalThink( interval )
end

function modifier_underlord_firestorm_custom_debuff:OnRefresh( kv )
    if not IsServer() then return end

    self.damage_pct = self.damage/100
end

function modifier_underlord_firestorm_custom_debuff:OnRemoved()
end

function modifier_underlord_firestorm_custom_debuff:OnDestroy()
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_underlord_firestorm_custom_debuff:OnIntervalThink()
    -- check health
    local damage = (self.damage_pct + (self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("str_to_damage")/100))) * self:GetStackCount()

    -- apply damage
    self.damageTable.damage = damage
    ApplyDamage( self.damageTable )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_underlord_firestorm_custom_debuff:GetEffectName()
    return "particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave_burn.vpcf"
end

function modifier_underlord_firestorm_custom_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

modifier_underlord_firestorm_custom_thinker = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_underlord_firestorm_custom_thinker:IsHidden()
    return true
end

function modifier_underlord_firestorm_custom_thinker:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_underlord_firestorm_custom_thinker:OnCreated( kv )
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    -- references
    local damage = self.ability:GetSpecialValueFor( "wave_damage" ) + (self.caster:GetStrength() * (self.ability:GetSpecialValueFor("str_to_damage")/100))
    local delay = self.ability:GetSpecialValueFor( "first_wave_delay" )
    self.radius = self.ability:GetSpecialValueFor( "radius" )
    self.count = self.ability:GetSpecialValueFor( "wave_count" )
    self.interval = self.ability:GetSpecialValueFor( "wave_interval" )

    self.burn_duration = self.ability:GetSpecialValueFor( "burn_duration" )
    self.burn_interval = self.ability:GetSpecialValueFor( "burn_interval" )
    self.burn_damage = self.ability:GetSpecialValueFor( "burn_damage" )

    if self.caster:HasScepter() and self.caster:HasModifier("modifier_underlord_pit_of_abyss_custom_buff") then
        self.interval = self.interval / 2
        self.burn_duration = self.burn_duration / 2
        self.count = self.count * 2
        self.radius = 500
    end

    if not IsServer() then return end

    -- init
    self.wave = 0
    self.damageTable = {
        -- victim = target,
        attacker = self.caster,
        damage = damage,
        damage_type = self.ability:GetAbilityDamageType(),
        ability = self.ability, --Optional.
    }
    -- ApplyDamage(damageTable)

    -- Start interval
    self:StartIntervalThink( delay )
end

function modifier_underlord_firestorm_custom_thinker:OnRefresh( kv )
    
end

function modifier_underlord_firestorm_custom_thinker:OnRemoved()
end

function modifier_underlord_firestorm_custom_thinker:OnDestroy()
    if not IsServer() then return end
    if self:GetParent():IsHero() then return end

    UTIL_Remove( self:GetParent() )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_underlord_firestorm_custom_thinker:OnIntervalThink()
    if not self.delayed then
        self.delayed = true
        self:StartIntervalThink( self.interval )
        self:OnIntervalThink()
        return
    end

    -- find enemies
    local enemies = FindUnitsInRadius(
        self.caster:GetTeamNumber(),    -- int, your team number
        self.parent:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        -- damage
        self.damageTable.victim = enemy
        ApplyDamage( self.damageTable )

        -- add debuff
        local debuff = enemy:FindModifierByName("modifier_underlord_firestorm_custom_debuff")
        if debuff == nil then
            debuff = enemy:AddNewModifier(
                self.caster, -- player source
                self.ability, -- ability source
                "modifier_underlord_firestorm_custom_debuff", -- modifier name
                {
                    duration = self.burn_duration,
                    interval = self.burn_interval,
                    damage = self.burn_damage,
                } -- kv
            )
        end

        if debuff ~= nil then
            debuff:IncrementStackCount()
            debuff:ForceRefresh()
        end
    end

    -- play effects
    self:PlayEffects()

    -- count wave
    self.wave = self.wave + 1
    if self.wave>=self.count then
        self:Destroy()
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_underlord_firestorm_custom_thinker:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf"
    local sound_cast = "Hero_AbyssalUnderlord.Firestorm"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, self.parent:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 4, Vector( self.radius, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self.parent )
end

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassCd = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

underlord_firestorm_custom = class({})
modifier_underlord_firestorm_custom = class(ItemBaseClass)
modifier_underlord_firestorm_custom_procattack_cooldown = class(ItemBaseClassCd)
LinkLuaModifier( "modifier_underlord_firestorm_custom_debuff", "heroes/hero_underlord/underlord_firestorm_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_underlord_firestorm_custom_thinker", "heroes/hero_underlord/underlord_firestorm_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_underlord_firestorm_custom", "heroes/hero_underlord/underlord_firestorm_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_underlord_firestorm_custom_procattack_cooldown", "heroes/hero_underlord/underlord_firestorm_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function underlord_firestorm_custom:GetAOERadius()
    return self:GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------
-- Ability Phase Start
function underlord_firestorm_custom:OnAbilityPhaseStart()
    local point = self:GetCursorPosition()

    self:PlayEffects( point )

    return true -- if success
end

function underlord_firestorm_custom:OnAbilityPhaseInterrupted()
    self:StopEffects()
end

--------------------------------------------------------------------------------
-- Ability Start
function underlord_firestorm_custom:OnSpellStart()
    self:StopEffects()

    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    if caster:HasScepter() and caster:HasModifier("modifier_underlord_pit_of_abyss_custom_buff") then
        point = caster:GetAbsOrigin()

        caster:AddNewModifier(caster, self, "modifier_underlord_firestorm_custom_thinker", {})
    else
        -- create thinker
        CreateModifierThinker(
            caster, -- player source
            self, -- ability source
            "modifier_underlord_firestorm_custom_thinker", -- modifier name
            {}, -- kv
            point,
            caster:GetTeamNumber(),
            false
        )
    end
end

function underlord_firestorm_custom:GetBehavior()
    local caster = self:GetCaster()

    if caster:HasScepter() and caster:HasModifier("modifier_underlord_pit_of_abyss_custom_buff") then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AOE 
    else
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE 
    end
end

function underlord_firestorm_custom:GetIntrinsicModifierName()
    return "modifier_underlord_firestorm_custom"
end

function modifier_underlord_firestorm_custom:OnCreated()
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    -- references
    local damage = self.ability:GetSpecialValueFor( "wave_damage" ) + (self.caster:GetStrength() * (self.ability:GetSpecialValueFor("str_to_damage")/100))
    local delay = self.ability:GetSpecialValueFor( "first_wave_delay" )
    self.radius = self.ability:GetSpecialValueFor( "procattack_radius" )
    self.count = 1
    self.interval = self.ability:GetSpecialValueFor( "wave_interval" )
    self.cooldown = self.ability:GetSpecialValueFor("procattack_cooldown")

    self.burn_duration = self.ability:GetSpecialValueFor( "burn_duration" )
    self.burn_interval = self.ability:GetSpecialValueFor( "burn_interval" )
    self.burn_damage = self.ability:GetSpecialValueFor( "burn_damage" )

    if self.caster:HasScepter() and self.caster:HasModifier("modifier_underlord_pit_of_abyss_custom_buff") then
        self.interval = self.interval / 2
        self.burn_interval = self.burn_interval / 2
        self.cooldown = self.cooldown / 2
    end

    if not IsServer() then return end

    self.damageTable = {
        -- victim = target,
        attacker = self.caster,
        damage = damage,
        damage_type = self.ability:GetAbilityDamageType(),
        ability = self.ability, --Optional.
    }
end

function modifier_underlord_firestorm_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_underlord_firestorm_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local attacker = event.attacker
    local attackTarget = event.target

    if attacker ~= parent then return end
    if not parent:HasModifier("modifier_item_aghanims_shard") or parent:HasModifier("modifier_underlord_firestorm_custom_procattack_cooldown") then return end
    -- find enemies
    local enemies = FindUnitsInRadius(
        self.caster:GetTeamNumber(),    -- int, your team number
        attackTarget:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        -- damage
        self.damageTable.victim = enemy
        ApplyDamage( self.damageTable )

        -- add debuff
        local debuff = enemy:FindModifierByName("modifier_underlord_firestorm_custom_debuff")
        if debuff == nil then
            debuff = enemy:AddNewModifier(
                self.caster, -- player source
                self.ability, -- ability source
                "modifier_underlord_firestorm_custom_debuff", -- modifier name
                {
                    duration = self.burn_duration,
                    interval = self.burn_interval,
                    damage = self.burn_damage,
                } -- kv
            )
        end

        if debuff ~= nil then
            debuff:IncrementStackCount()
            debuff:ForceRefresh()
        end

        self:PlayEffects(enemy)
    end

    -- play effects
    
    self.caster:AddNewModifier(self.caster, self.ability, "modifier_underlord_firestorm_custom_procattack_cooldown", {
        duration = self.cooldown
    })
end

function modifier_underlord_firestorm_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf"
    local sound_cast = "Hero_AbyssalUnderlord.Firestorm"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 4, Vector( self.radius, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self.parent )
end
--------------------------------------------------------------------------------
function underlord_firestorm_custom:PlayEffects( point )
    -- Get Resources
    local particle_cast = "particles/units/heroes/heroes_underlord/underlord_firestorm_pre.vpcf"
    local sound_cast = "Hero_AbyssalUnderlord.Firestorm.Start"

    -- get data
    local radius = self:GetSpecialValueFor( "radius" )

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticleForTeam( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster(), self:GetCaster():GetTeamNumber() )
    ParticleManager:SetParticleControl( self.effect_cast, 0, point )
    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( 2, 2, 2 ) )

    -- Create Sound
    EmitSoundOnLocationWithCaster( point, sound_cast, self:GetCaster() )
end

function underlord_firestorm_custom:StopEffects()
    ParticleManager:DestroyParticle( self.effect_cast, true )
    ParticleManager:ReleaseParticleIndex( self.effect_cast )
end