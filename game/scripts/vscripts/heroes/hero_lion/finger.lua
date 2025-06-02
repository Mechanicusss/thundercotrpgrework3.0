lion_finger_of_death_custom = class({})
LinkLuaModifier( "modifier_lion_finger_of_death_custom", "heroes/hero_lion/finger", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lion_finger_of_death_custom_lion", "heroes/hero_lion/finger", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lion_finger_of_death_custom_stacks", "heroes/hero_lion/finger", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

modifier_lion_finger_of_death_custom_lion = class(ItemBaseClass)
modifier_lion_finger_of_death_custom_stacks = class(ItemBaseStacks)

function lion_finger_of_death_custom:GetIntrinsicModifierName()
    return "modifier_lion_finger_of_death_custom_lion"
end

function modifier_lion_finger_of_death_custom_lion:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_DEATH,
    }

    return funcs
end

function modifier_lion_finger_of_death_custom_lion:OnDeath(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end
    if event.attacker == event.unit then return end
    if event.inflictor == nil then return end

    if event.inflictor:GetAbilityName() ~= "lion_finger_of_death_custom" then return end

    local parent = self:GetParent()

    if parent:HasModifier("modifier_lion_finger_of_death_custom_stacks") then
        local mod = parent:FindModifierByName("modifier_lion_finger_of_death_custom_stacks")
        mod:IncrementStackCount()
    else
        local mod = parent:AddNewModifier(parent, self:GetAbility(), "modifier_lion_finger_of_death_custom_stacks", {})
        mod:IncrementStackCount()
    end
end

function modifier_lion_finger_of_death_custom_lion:OnAttackStart(event)
    if not IsServer() then return end
    if event.attacker ~= self:GetParent() then return end
    if event.attacker == event.target then return end
    if not event.target:IsAlive() then return end
    if event.attacker:IsIllusion() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local victim = event.target

    if not ability:IsCooldownReady() then return end
    if ability:GetManaCost(-1) > parent:GetMana() then return end

    SpellCaster:Cast(ability, victim, true)
end

function modifier_lion_finger_of_death_custom_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_lion_finger_of_death_custom_stacks:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_TOOLTIP
    }

    return funcs
end

function modifier_lion_finger_of_death_custom_stacks:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("damage_per_kill") * self:GetStackCount()
end

--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function lion_finger_of_death_custom:GetAOERadius()
    if self:GetCaster():HasScepter() then
        return self:GetSpecialValueFor( "splash_radius_scepter" )
    end

    return 0
end

function lion_finger_of_death_custom:GetCooldown( level )
    if self:GetCaster():HasScepter() then
        return self:GetSpecialValueFor( "cooldown_scepter" )
    end

    return self.BaseClass.GetCooldown( self, level )
end

function lion_finger_of_death_custom:GetManaCost( level )
    if self:GetCaster():HasScepter() then
        return self:GetSpecialValueFor( "mana_cost_scepter" )
    end

    return self.BaseClass.GetManaCost( self, level )
end

--------------------------------------------------------------------------------
-- Ability Start
function lion_finger_of_death_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    -- pre-effects
    local sound_cast = "Hero_Lion.FingerOfDeath"
    EmitSoundOn( sound_cast, caster )

    -- cancel if linken
    if target:TriggerSpellAbsorb(self) then
        self:PlayEffects( target )
        return 
    end

    -- load data
    local delay = self:GetSpecialValueFor("damage_delay")
    local search = self:GetSpecialValueFor("splash_radius_scepter")

    -- find targets
    local targets = {}
    if caster:HasScepter() then
        targets = FindUnitsInRadius(
            caster:GetTeamNumber(), -- int, your team number
            target:GetOrigin(), -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            search, -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            0,  -- int, flag filter
            0,  -- int, order filter
            false   -- bool, can grow cache
        )
    else
        table.insert(targets,target)
    end

    for _,enemy in pairs(targets) do
        -- delay
        enemy:AddNewModifier(
            caster, -- player source
            self, -- ability source
            "modifier_lion_finger_of_death_custom", -- modifier name
            { duration = delay } -- kv
        )

        -- effects
        self:PlayEffects( enemy )
    end
end

--------------------------------------------------------------------------------
function lion_finger_of_death_custom:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_lion/lion_spell_finger_of_death.vpcf"
    local sound_cast = "Hero_Lion.FingerOfDeathImpact"

    -- load data
    local caster = self:GetCaster()
    local direction = (caster:GetOrigin()-target:GetOrigin()):Normalized()

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, caster )
    local attach = "attach_attack1"
    if caster:ScriptLookupAttachment( "attach_attack2" )~=0 then attach = "attach_attack2" end
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        caster,
        PATTACH_POINT_FOLLOW,
        attach,
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 2, target:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 3, target:GetOrigin() + direction )
    ParticleManager:SetParticleControlForward( effect_cast, 3, -direction )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

modifier_lion_finger_of_death_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_lion_finger_of_death_custom:IsHidden()
    return true
end

function modifier_lion_finger_of_death_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE 
end

function modifier_lion_finger_of_death_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_lion_finger_of_death_custom:OnCreated( kv )
    if not IsServer() then return end
    -- references
    if self:GetCaster():HasScepter() then
        self.damage = self:GetAbility():GetSpecialValueFor( "damage_scepter" ) -- special value
    else
        self.damage = self:GetAbility():GetSpecialValueFor( "damage" ) -- special value
    end

    self.damage = self.damage + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100))

    local fingerStacks = self:GetCaster():FindModifierByName("modifier_lion_finger_of_death_custom_stacks")
    if fingerStacks ~= nil then
        self.damage = self.damage + (self:GetAbility():GetSpecialValueFor("damage_per_kill") * fingerStacks:GetStackCount())
    end
end

function modifier_lion_finger_of_death_custom:OnDestroy( kv )
    if IsServer() then
        -- check if it's still valid target
        if not self:GetParent():IsAlive() then return end
        local nResult = UnitFilter(
            self:GetParent(),
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
            0,
            self:GetCaster():GetTeamNumber()
        )
        if nResult ~= UF_SUCCESS then
            return
        end

        -- damage
        local damageTable = {
            victim = self:GetParent(),
            attacker = self:GetCaster(),
            damage = self.damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility(), --Optional.
        }
        ApplyDamage(damageTable)
    end
end