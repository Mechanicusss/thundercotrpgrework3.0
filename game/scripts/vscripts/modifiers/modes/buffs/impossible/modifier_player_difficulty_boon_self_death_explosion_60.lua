LinkLuaModifier( "modifier_player_difficulty_boon_self_death_explosion_60", "modifiers/modes/buffs/impossible/modifier_player_difficulty_boon_self_death_explosion_60", LUA_MODIFIER_MOTION_NONE )
modifier_player_difficulty_boon_self_death_explosion_60 = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_player_difficulty_boon_self_death_explosion_60:IsHidden()
    return false
end

function modifier_player_difficulty_boon_self_death_explosion_60:RemoveOnDeath()
    return false
end

function modifier_player_difficulty_boon_self_death_explosion_60:IsDebuff()
    return true
end

function modifier_player_difficulty_boon_self_death_explosion_60:IsStunDebuff()
    return false
end

function modifier_player_difficulty_boon_self_death_explosion_60:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_player_difficulty_boon_self_death_explosion_60:OnCreated( kv )
    self.parent = self:GetParent()

    -- references
    self.reflect = 40
    self.reflectOriginal = 40
    self.min_radius = 400
    self.max_radius = 800
    self.delta = self.max_radius-self.min_radius

    if not IsServer() then return end
    -- for shard
    self.attacker = {}

    -- precache damage
    self.damageTable = {
        -- victim = target,
        attacker = self.parent,
        -- damage = 500,
        -- damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(), --Optional.
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_REFLECTION, --Optional.
    }

    if not IsServer() then return end
end

function modifier_player_difficulty_boon_self_death_explosion_60:OnRefresh( kv )
    self:OnCreated( kv )
end

function modifier_player_difficulty_boon_self_death_explosion_60:OnRemoved()
end

function modifier_player_difficulty_boon_self_death_explosion_60:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_player_difficulty_boon_self_death_explosion_60:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }

    return funcs
end

function modifier_player_difficulty_boon_self_death_explosion_60:OnAttackLanded(params)
    if not IsServer() then return end
    if params.target ~= self:GetParent() then return end
    if params.inflictor ~= nil then return end

    self.reflect = self.reflectOriginal

    -- find enemies
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),    -- int, your team number
        self.parent:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.max_radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        if enemy ~= self:GetParent() then
            -- get distance percentage damage
            local distance = (enemy:GetOrigin()-self.parent:GetOrigin()):Length2D()
            local pct = (self.max_radius-distance)/self.delta
            pct = math.min( pct, 1 )

            -- apply damage
            self.damageTable.victim = enemy
            self.damageTable.damage = params.damage * pct * self.reflect/100
            self.damageTable.damage_type = params.damage_type
            ApplyDamage( self.damageTable )

            -- play effects
            self:PlayEffects( enemy )
        end
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_player_difficulty_boon_self_death_explosion_60:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/econ/items/spectre/spectre_arcana/spectre_arcana_dispersion.vpcf"

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
        self.parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    -- ParticleManager:SetParticleControl( effect_cast, 1, vControlVector )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_player_difficulty_boon_self_death_explosion_60:GetTexture()
    return "spectre_dispersion"
end