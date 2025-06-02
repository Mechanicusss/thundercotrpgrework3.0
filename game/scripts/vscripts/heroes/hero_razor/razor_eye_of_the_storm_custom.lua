razor_eye_of_the_storm_custom = class({})
LinkLuaModifier( "modifier_razor_eye_of_the_storm_custom", "heroes/hero_razor/razor_eye_of_the_storm_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_razor_eye_of_the_storm_custom_debuff", "heroes/hero_razor/razor_eye_of_the_storm_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Init Abilities
function razor_eye_of_the_storm_custom:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_razor.vsndevts", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_razor/razor_eye_of_the_storm.vpcf", context )
end

function razor_eye_of_the_storm_custom:Spawn()
    if not IsServer() then return end
end

function razor_eye_of_the_storm_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
--------------------------------------------------------------------------------
-- Ability Start
function razor_eye_of_the_storm_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()

    if caster:HasModifier("modifier_razor_eye_of_the_storm_custom") then
        caster:RemoveModifierByName("modifier_razor_eye_of_the_storm_custom")
    end

    caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_razor_eye_of_the_storm_custom", -- modifier name
        {
            duration = self:GetSpecialValueFor("duration")
        } -- kv
    )
end

modifier_razor_eye_of_the_storm_custom_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_razor_eye_of_the_storm_custom_debuff:IsHidden()
    return false
end

function modifier_razor_eye_of_the_storm_custom_debuff:IsDebuff()
    return true
end

function modifier_razor_eye_of_the_storm_custom_debuff:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_razor_eye_of_the_storm_custom_debuff:OnCreated( kv )
    if not IsServer() then return end
    -- send init data from server to client
    self:SetHasCustomTransmitterData( true )

    self.armor = kv.armor
    self.mr = kv.mr
end

function modifier_razor_eye_of_the_storm_custom_debuff:OnRefresh( kv )
    if not IsServer() then return end
    if self.armor ~= nil and kv.armor ~= nil and self.mr ~= nil and kv.mr ~= nil then
        self.armor = kv.armor
        self.mr = kv.mr
    end
end

function modifier_razor_eye_of_the_storm_custom_debuff:OnRemoved()
end

function modifier_razor_eye_of_the_storm_custom_debuff:OnDestroy()
end

--------------------------------------------------------------------------------
-- Transmitter data
function modifier_razor_eye_of_the_storm_custom_debuff:AddCustomTransmitterData()
    -- on server
    local data = {
        armor = self.armor,
        mr = self.mr
    }

    return data
end

function modifier_razor_eye_of_the_storm_custom_debuff:HandleCustomTransmitterData( data )
    -- on client
    self.armor = data.armor
    self.mr = data.mr
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_razor_eye_of_the_storm_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function modifier_razor_eye_of_the_storm_custom_debuff:GetModifierPhysicalArmorBonus()
    return -self.armor * self:GetStackCount()
end

function modifier_razor_eye_of_the_storm_custom_debuff:GetModifierMagicalResistanceBonus()
    return self.mr * self:GetStackCount()
end

modifier_razor_eye_of_the_storm_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_razor_eye_of_the_storm_custom:IsHidden()
    return false
end

function modifier_razor_eye_of_the_storm_custom:IsDebuff()
    return false
end

function modifier_razor_eye_of_the_storm_custom:RemoveOnDeath()
    return true
end

function modifier_razor_eye_of_the_storm_custom:IsPurgable()
    return false
end

-- Optional Classifications
function modifier_razor_eye_of_the_storm_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_razor_eye_of_the_storm_custom:OnCreated( kv )
    self.parent = self:GetParent()

    -- references
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
    self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
    self.interval = self:GetAbility():GetSpecialValueFor( "strike_interval" )
    self.armor = self:GetAbility():GetSpecialValueFor( "armor_reduction" )
    self.mr = self:GetAbility():GetSpecialValueFor( "magic_resistance" )

    if not IsServer() then return end

    self.strikes = 1
    if self.parent:HasScepter() then
        self.interval = self.interval / 2
        self.strikes = self.strikes + 1
    end

    self.targets = {}

    -- ability properties
    self.abilityDamageType = self:GetAbility():GetAbilityDamageType()

    -- precache damage
    self.damageTable = {
        -- victim = target,
        attacker = self.parent,
        damage_type = self.abilityDamageType,
        ability = self:GetAbility(), --Optional.
    }
    -- ApplyDamage(damageTable)

    -- Start interval
    self:StartIntervalThink( self.interval )
    self:OnIntervalThink()

    -- play effects
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_razor/razor_rain_storm.vpcf"
    local sound_cast = "Hero_Razor.Storm.Cast"
    local sound_loop = "Hero_Razor.Storm.Loop"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent )

    -- buff particle
    self:AddParticle(
        self.effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )

    -- Create Sound
    EmitSoundOn( sound_cast, self.parent )
    EmitSoundOn( sound_loop, self.parent )
end

function modifier_razor_eye_of_the_storm_custom:OnRefresh( kv )
end

function modifier_razor_eye_of_the_storm_custom:OnRemoved()
end

function modifier_razor_eye_of_the_storm_custom:OnDestroy()
    if not IsServer() then return end
    -- stop sound
    local sound_loop = "Hero_Razor.Storm.Loop"
    local sound_end = "Hero_Razor.StormEnd"
    StopSoundOn( sound_loop, self.parent )
    EmitSoundOn( sound_end, self.parent )

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_razor_eye_of_the_storm_custom:OnIntervalThink()
    local targets = {}

    local type_filter = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
    if self.building then
        --type_filter = type_filter + DOTA_UNIT_TARGET_BUILDING
    end

    -- find enemies
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),    -- int, your team number
        self.parent:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        type_filter,    -- int, type filter
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )
    if #enemies<1 then return end

    -- sort based on health
    table.sort( enemies, function( left, right )
        return left:GetHealth() < right:GetHealth()
    end)

    -- find static-linked enemies (modifier name subject to change)
    local linked = {}
    for i,enemy in ipairs(enemies) do
        if enemy:HasModifier( "modifier_razor_static_link_custom_debuff" ) then
            table.insert( linked, enemy )
        end
    end

    -- find enemies based on number of strikes per interval
    for i=1,self.strikes do
        local target
        -- find enemies in linked
        for _,enemy in pairs(linked) do
            if not targets[enemy] then
                targets[enemy] = true
                target = enemy
                break
            end
        end
        if target then break end
        -- find target in lowest
        for _,enemy in pairs(enemies) do
            if not targets[enemy] then
                -- check building
                if not enemy:IsBuilding() and enemy:IsAlive() and not enemy:IsMagicImmune() and not enemy:IsInvulnerable() and self.parent:CanEntityBeSeenByMyTeam(enemy) then
                    targets[enemy] = true
                    target = enemy
                    break
                elseif (enemy:IsAncient() or enemy:IsTower() or enemy:IsBarracks()) then
                    targets[enemy] = true
                    target = enemy
                    break
                end
            end
        end
    end

    local baseDmg = self:GetAbility():GetSpecialValueFor( "damage" )

    if self:GetCaster():HasTalent("special_bonus_unique_razor_1_custom") then
        local talentDmg = self:GetCaster():FindAbilityByName("special_bonus_unique_razor_1_custom"):GetSpecialValueFor("value")
        baseDmg = baseDmg + talentDmg
    end

    self.damageTable.damage = baseDmg + (self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster()) * (self:GetAbility():GetSpecialValueFor("attack_to_damage")/100))

    local armorRemoval = self.armor
    local mrRemoval = self.mr
    if self:GetCaster():HasTalent("special_bonus_unique_razor_2_custom") then
        local bonusArmorRemoval = self:GetCaster():FindAbilityByName("special_bonus_unique_razor_2_custom"):GetSpecialValueFor("value")
        armorRemoval = armorRemoval + bonusArmorRemoval
    end
    
    -- strike targets
    for enemy,_ in pairs(targets) do
        -- damage
        self.damageTable.victim = enemy
        ApplyDamage( self.damageTable )
        self.parent:PerformAttack(enemy, true, true, true, false, false, false, true)

        -- add modifier
        local debuff = enemy:AddNewModifier(
            self.parent, -- player source
            self:GetAbility(), -- ability source
            "modifier_razor_eye_of_the_storm_custom_debuff", -- modifier name
            {
                duration = 3,
                armor = armorRemoval,
                mr = mrRemoval
            } -- kv
        )

        if debuff ~= nil then
            if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("debuff_max_stacks") then
                debuff:IncrementStackCount()
            end

            debuff:ForceRefresh()
        end

        -- play effects
        self:PlayEffects2( enemy )
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_razor_eye_of_the_storm_custom:PlayEffects2( enemy )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_razor/razor_storm_lightning_strike.vpcf"
    local sound_cast = "Hero_razor.lightning"

    -- Create Particle
    -- NOTE: Don't know what is the proper effect
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, self.parent )
    ParticleManager:SetParticleControl( effect_cast, 0, self.parent:GetOrigin() + Vector(0,0,500) )
    -- ParticleManager:SetParticleControlEnt(
    --  effect_cast,
    --  0,
    --  self.parent,
    --  PATTACH_CUSTOMORIGIN,
    --  "",
    --  self.parent:GetOrigin() + Vector(0,0,300), -- unknown
    --  false -- unknown, true
    -- )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        enemy,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, enemy )
end