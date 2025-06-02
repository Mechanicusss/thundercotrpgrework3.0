boss_sand_storm = class({})
modifier_boss_sand_storm_thinker = class({})
modifier_boss_sand_storm_debuff = class({})

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

modifier_boss_sand_storm_aura = class(ItemBaseClassAura)

LinkLuaModifier( "modifier_boss_sand_storm", "heroes/bosses/sand/storm", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_sand_storm_debuff", "heroes/bosses/sand/storm", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_sand_storm_thinker", "heroes/bosses/sand/storm", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_sand_storm_aura", "heroes/bosses/sand/storm", LUA_MODIFIER_MOTION_NONE )

function boss_sand_storm:GetIntrinsicModifierName()
    return "modifier_boss_sand_storm_thinker"
end

function boss_sand_storm:GetAOERadius()
    return self:GetSpecialValueFor("sand_storm_radius")
end

function modifier_boss_sand_storm_thinker:IsHidden() return true end
function modifier_boss_sand_storm_thinker:IsPurgable() return false end
function modifier_boss_sand_storm_thinker:RemoveOnDeath() return false end

function modifier_boss_sand_storm_thinker:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    -- load data
    caster:AddNewModifier(
        caster, -- player source
        self:GetAbility(), -- ability source
        "modifier_boss_sand_storm", -- modifier name
        {
            start = true,
        } -- kv
    )

    -- effects
    local sound_cast = "Ability.SandKing_SandStorm.start"
    EmitSoundOn( sound_cast, caster )
end

--------------------------------------------------------------------------------
-- Ability Channeling
-- function boss_sand_storm:GetChannelTime()

-- end

modifier_boss_sand_storm = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_boss_sand_storm:IsHidden()
    return false
end

function modifier_boss_sand_storm:IsDebuff()
    return false
end

function modifier_boss_sand_storm:IsPurgable()
    return false
end

function modifier_boss_sand_storm:OnCreated()
    if not IsServer() then return end

    local particle_cast = "particles/units/heroes/hero_sandking/sandking_sandstorm.vpcf"
    local sound_cast = "Ability.SandKing_SandStorm.loop"
    local radius = self:GetAbility():GetSpecialValueFor( "sand_storm_radius" )

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( radius, radius, radius ) )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
    self:StartIntervalThink(GameRules:GetGameFrameTime())
end

function modifier_boss_sand_storm:OnIntervalThink()
    ParticleManager:SetParticleControl(self.effect_cast, 0, self:GetParent():GetOrigin())
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_boss_sand_storm_aura:OnCreated( kv )
    -- references
    self.damage = self:GetAbility():GetSpecialValueFor( "sand_storm_damage" ) -- special value
    self.radius = self:GetAbility():GetSpecialValueFor( "sand_storm_radius" ) -- special value
    self.interval = 0.5

    if IsServer() then
        -- initialize
        self.active = true
        self.damageTable = {
            -- victim = target,
            attacker = self:GetCaster(),
            damage = self.damage * self.interval,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility(), --Optional.
        }

        -- Start interval
        self:StartIntervalThink( self.interval )
        self:OnIntervalThink()
    end
end

function modifier_boss_sand_storm:IsAura()
  return true
end

function modifier_boss_sand_storm:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_boss_sand_storm:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_boss_sand_storm:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("sand_storm_radius")
end

function modifier_boss_sand_storm:GetModifierAura()
    return "modifier_boss_sand_storm_aura"
end

function modifier_boss_sand_storm:GetAuraEntityReject(target)
    if target:IsMagicImmune() then return true end

    return false
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_boss_sand_storm:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_boss_sand_storm:OnDeath(event)
    if event.unit ~= self:GetParent() then return end

    ParticleManager:DestroyParticle( self.effect_cast, false )
    ParticleManager:ReleaseParticleIndex( self.effect_cast )

    -- Stop sound
    local sound_cast = "Ability.SandKing_SandStorm.loop"
    StopSoundOn( sound_cast, self:GetParent() )
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_boss_sand_storm:CheckState()
    local state = {
        --[MODIFIER_STATE_INVISIBLE] = true,
    }

    return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_boss_sand_storm_aura:OnIntervalThink()
    -- find enemies
    local enemies = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(),   -- int, your team number
        self:GetCaster():GetOrigin(),   -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    -- damage enemies
    for _,enemy in pairs(enemies) do
        self.damageTable.victim = enemy
        ApplyDamage( self.damageTable )
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_boss_sand_storm_debuff", { duration = 1.0 })
    end

    -- effects: reposition cloud
    if self.effect_cast then
        ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations


function modifier_boss_sand_storm:StopEffects()
    -- Stop particles
    ParticleManager:DestroyParticle( self.effect_cast, false )
    ParticleManager:ReleaseParticleIndex( self.effect_cast )

    -- Stop sound
    local sound_cast = "Ability.SandKing_SandStorm.loop"
    StopSoundOn( sound_cast, self:GetParent() )
end
-------------
function modifier_boss_sand_storm_debuff:IsHidden()
    return false
end

function modifier_boss_sand_storm_debuff:IsDebuff()
    return true
end

function modifier_boss_sand_storm_debuff:IsPurgable()
    return false
end

function modifier_boss_sand_storm_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MISS_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }

    return funcs
end

function modifier_boss_sand_storm_debuff:GetModifierMiss_Percentage()
    return self:GetAbility():GetSpecialValueFor("miss")
end

function modifier_boss_sand_storm_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end