--------------------------------------------------------------------------------
local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

spectre_dispersion_custom = class({})
modifier_spectre_dispersion_custom_activated = class({})
LinkLuaModifier( "modifier_spectre_dispersion_custom", "heroes/hero_spectre/spectre_dispersion_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_spectre_dispersion_custom_activated", "heroes/hero_spectre/spectre_dispersion_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_spectre_dispersion_custom_debuff", "heroes/hero_spectre/spectre_dispersion_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_spectre_dispersion_custom_talent_buff", "heroes/hero_spectre/spectre_dispersion_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_spectre_dispersion_custom_talent_cooldown", "heroes/hero_spectre/spectre_dispersion_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_spectre_dispersion_custom_aura", "heroes/hero_spectre/spectre_dispersion_custom", LUA_MODIFIER_MOTION_NONE )

modifier_spectre_dispersion_custom_debuff = class(ItemBaseClassDebuff)
modifier_spectre_dispersion_custom_aura = class(ItemBaseClassAura)
modifier_spectre_dispersion_custom_talent_buff = class(ItemBaseClassAura)
modifier_spectre_dispersion_custom_talent_cooldown = class(ItemBaseClassDebuff)

function modifier_spectre_dispersion_custom_talent_buff:IsDebuff() return false end
function modifier_spectre_dispersion_custom_talent_cooldown:IsHidden() return true end
function modifier_spectre_dispersion_custom_talent_cooldown:RemoveOnDeath() return false end
--------------------------------------------------------------------------------
-- Init Abilities
function spectre_dispersion_custom:Precache( context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_spectre.vsndevts", context )
    PrecacheResource( "particle", "particles/econ/items/spectre/spectre_arcana/spectre_arcana_dispersion.vpcf", context )
end

function spectre_dispersion_custom:GetAOERadius()
    return self:GetSpecialValueFor("max_radius")
end

function spectre_dispersion_custom:Spawn()
    if not IsServer() then return end
end

function modifier_spectre_dispersion_custom_activated:IsHidden()
    return false
end

function modifier_spectre_dispersion_custom_activated:IsDebuff()
    return false
end

function modifier_spectre_dispersion_custom_activated:IsStunDebuff()
    return false
end

function modifier_spectre_dispersion_custom_activated:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Passive Modifier
function spectre_dispersion_custom:GetIntrinsicModifierName()
    return "modifier_spectre_dispersion_custom"
end

modifier_spectre_dispersion_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_spectre_dispersion_custom:IsHidden()
    return true
end

function modifier_spectre_dispersion_custom:IsDebuff()
    return false
end

function modifier_spectre_dispersion_custom:IsStunDebuff()
    return false
end

function modifier_spectre_dispersion_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_spectre_dispersion_custom:OnCreated( kv )
    self.parent = self:GetParent()

    -- references
    self.reflect = self:GetAbility():GetSpecialValueFor( "damage_reflection_pct" )
    self.min_radius = self:GetAbility():GetSpecialValueFor( "min_radius" )
    self.max_radius = self:GetAbility():GetSpecialValueFor( "max_radius" )
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

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_spectre_dispersion_custom:OnRefresh( kv )
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if parent:IsIllusion() then return end

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("damage_reflection_pct")
end

function modifier_spectre_dispersion_custom:OnIntervalThink()
    self:OnRefresh()
end

function modifier_spectre_dispersion_custom:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    if caster:IsIllusion() then return end

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_spectre_dispersion_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_spectre_dispersion_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target or event.target:GetTeam() == parent:GetTeam() then return end

    local target = event.target

    local talent = parent:FindAbilityByName("talent_spectre_2")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then return end

    local buff = target:FindModifierByName("modifier_spectre_dispersion_custom_debuff")
    if not buff then
        buff = target:AddNewModifier(parent, self:GetAbility(), "modifier_spectre_dispersion_custom_debuff", {
            duration = self:GetAbility():GetSpecialValueFor("buff_duration")
        })
    end

    if buff then
        if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("buff_max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end

function modifier_spectre_dispersion_custom:GetModifierIncomingDamage_Percentage( params )
    if self.parent ~= params.target or self.parent == params.attacker then return end 
    if self.parent:GetTeam() == params.attacker:GetTeam() then return end
    if self.parent:PassivesDisabled() or self.parent:IsIllusion() or not self.parent:IsRealHero() then return end

    -- Don't reflect reflection
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= 0 then return end

    self.reflect = self:GetAbility():GetSpecialValueFor( "damage_reflection_pct" )
    self.min_radius = self:GetAbility():GetSpecialValueFor( "min_radius" )
    self.max_radius = self:GetAbility():GetSpecialValueFor( "max_radius" )
    self.delta = self.max_radius-self.min_radius

    local attacker = params.attacker

    local talent = self.parent:FindAbilityByName("talent_spectre_2")
    if talent ~= nil and talent:GetLevel() > 2 then
        if not self.parent:HasModifier("modifier_spectre_dispersion_custom_talent_cooldown") and not self.parent:HasModifier("modifier_spectre_dispersion_custom_talent_buff") and params.damage >= (self.parent:GetMaxHealth() * (talent:GetSpecialValueFor("max_hp_pct_trigger")/100)) then
            self.parent:AddNewModifier(self.parent, talent, "modifier_spectre_dispersion_custom_talent_buff", {
                duration = talent:GetSpecialValueFor("damage_reduction_duration")
            })
        end
    end

    local buff = attacker:FindModifierByName("modifier_spectre_dispersion_custom_debuff")
    if not buff then
        buff = attacker:AddNewModifier(self.parent, self:GetAbility(), "modifier_spectre_dispersion_custom_debuff", {
            duration = self:GetAbility():GetSpecialValueFor("buff_duration")
        })
    end

    if buff then
        if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("buff_max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()

        if (not talent or (talent ~= nil and talent:GetLevel() < 3)) then
            -- find enemies
            local enemies = FindUnitsInRadius(
                self.parent:GetTeamNumber(),    -- int, your team number
                self.parent:GetOrigin(),    -- point, center point
                nil,    -- handle, cacheUnit. (not known)
                self.max_radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
                DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
                DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
                0,  -- int, flag filter
                0,  -- int, order filter
                false   -- bool, can grow cache
            )

            for _,enemy in pairs(enemies) do
                -- get distance percentage damage
                local distance = (enemy:GetOrigin()-self.parent:GetOrigin()):Length2D()
                local pct = (self.max_radius-distance)/self.delta
                pct = math.min( pct, 1 )

                -- apply damage
                self.damageTable.victim = enemy
                self.damageTable.damage = params.damage * pct * ((self.reflect/100)*buff:GetStackCount())
                self.damageTable.damage_type = params.damage_type
                ApplyDamage( self.damageTable )

                -- play effects
                self:PlayEffects( enemy )
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_spectre_dispersion_custom:PlayEffects( target )
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
----------
function modifier_spectre_dispersion_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }

    return funcs
end

function modifier_spectre_dispersion_custom_debuff:GetModifierIncomingDamage_Percentage(event)
    if event.attacker ~= self:GetCaster() then return end

    return self:GetAbility():GetSpecialValueFor("buff_damage_increase_pct") * self:GetStackCount()
end
------------------
function modifier_spectre_dispersion_custom_talent_buff:OnCreated( kv )
    if not IsServer() then return end

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_spectre_dispersion_custom_talent_buff:OnRefresh( kv )
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if parent:IsIllusion() then return end

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("damage_reduction_boost")
end

function modifier_spectre_dispersion_custom_talent_buff:OnIntervalThink()
    self:OnRefresh()
end

function modifier_spectre_dispersion_custom_talent_buff:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    if caster:IsIllusion() then return end

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil

    caster:AddNewModifier(caster, self:GetAbility(), "modifier_spectre_dispersion_custom_talent_cooldown", {
        duration = self:GetAbility():GetSpecialValueFor("damage_reduction_cooldown")
    })
end