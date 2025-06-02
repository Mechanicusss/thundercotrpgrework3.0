lina_laguna_blade_custom = class({})
modifier_lina_laguna_blade_custom_aghs = class({})
modifier_lina_laguna_blade_custom_autocast_strike = class({})
modifier_lina_laguna_blade_custom_autocast_strike_vanish = class({})
LinkLuaModifier( "modifier_lina_laguna_blade_custom_aghs", "heroes/hero_lina/laguna_blade", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lina_laguna_blade_custom", "heroes/hero_lina/laguna_blade", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lina_laguna_blade_custom_autocast_strike", "heroes/hero_lina/laguna_blade", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lina_laguna_blade_custom_autocast_strike_vanish", "heroes/hero_lina/laguna_blade", LUA_MODIFIER_MOTION_NONE )

----------
function modifier_lina_laguna_blade_custom_autocast_strike_vanish:OnCreated()
    if not IsServer() then return end
    self:GetParent():AddNoDraw()
end

function modifier_lina_laguna_blade_custom_autocast_strike_vanish:OnDestroy()
    if not IsServer() then return end
    self:GetParent():RemoveNoDraw()
end

function modifier_lina_laguna_blade_custom_autocast_strike_vanish:IsHidden()
    return true
end

function modifier_lina_laguna_blade_custom_autocast_strike_vanish:RemoveOnDeath()
    return true
end

function modifier_lina_laguna_blade_custom_autocast_strike_vanish:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true
    }
    return state
end

function modifier_lina_laguna_blade_custom_autocast_strike:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST  
    }
    return funcs
end

function modifier_lina_laguna_blade_custom_autocast_strike:OnAbilityFullyCast(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end
    if not event.ability or not event.ability:IsTrained() then return end
    if event.ability:GetAbilityName() == "lina_light_strike_array" and event.ability:GetAutoCastState() then
        local pos = event.ability:GetCursorPosition()
        parent:AddNewModifier(parent, event.ability, "modifier_lina_laguna_blade_custom_autocast_strike_vanish", { duration = 0.5 })
        Timers:CreateTimer(0.25, function()
            parent:SetAbsOrigin(pos)
        end)
    end
end

function modifier_lina_laguna_blade_custom_autocast_strike:OnDeath(event)
    local parent = self:GetParent()
    if parent ~= event.unit then return end
    local strike = parent:FindAbilityByName("lina_light_strike_array")
    if not strike or strike:GetLevel() < 1 or not strike:GetAutoCastState() then return end
    strike:ToggleAutoCast()
    parent:RemoveModifierByNameAndCaster("modifier_lina_laguna_blade_custom_autocast_strike", parent)
end

function modifier_lina_laguna_blade_custom_autocast_strike:IsHidden()
    return true
end

function modifier_lina_laguna_blade_custom_autocast_strike:RemoveOnDeath()
    return false
end
----------
function lina_laguna_blade_custom:GetIntrinsicModifierName()
    return "modifier_lina_laguna_blade_custom_aghs"
end

function modifier_lina_laguna_blade_custom_aghs:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_START
    }
    return funcs
end

function modifier_lina_laguna_blade_custom_aghs:OnAttackStart(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if unit:IsIllusion() then return end

    if not unit:HasScepter() then return end

    if not caster:IsAlive() or caster:PassivesDisabled() or caster:IsIllusion() then
        return
    end

    if not victim:IsAlive() or victim:IsMagicImmune() or victim:IsBuilding() or victim:IsOther() then return end
    
    local chance = ability:GetLevelSpecialValueFor("scepter_chance", (ability:GetLevel() - 1))

    if not RollPercentage(chance) then
        return
    end

    self:CastRandomAbility(unit, victim)
end

function modifier_lina_laguna_blade_custom_aghs:CastRandomAbility(unit, target)
    local dragonSlave = unit:FindAbilityByName("lina_dragon_slave")
    local lightStrikeArray = unit:FindAbilityByName("lina_light_strike_array")
    local lagunaBlade = unit:FindAbilityByName("lina_laguna_blade_custom")

    local random = RandomInt(1, 3)
    if random == 1 and dragonSlave ~= nil and dragonSlave:GetLevel() > 0 then
        SpellCaster:Cast(dragonSlave, target)
    elseif random == 2 and lightStrikeArray ~= nil and lightStrikeArray:GetLevel() > 0 then
        SpellCaster:Cast(lightStrikeArray, target)
    elseif random == 3 and lagunaBlade ~= nil and lagunaBlade:GetLevel() > 0 then
        SpellCaster:Cast(lagunaBlade, target)
    end
end

--------------------------------------------------------------------------------
-- Ability Cast Filter
function lina_laguna_blade_custom:CastFilterResultTarget( hTarget )
    if hTarget:IsMagicImmune() then
        return UF_FAIL_MAGIC_IMMUNE_ENEMY
    end

    if not IsServer() then return UF_SUCCESS end
    local nResult = UnitFilter(
        hTarget,
        self:GetAbilityTargetTeam(),
        self:GetAbilityTargetType(),
        self:GetAbilityTargetFlags(),
        self:GetCaster():GetTeamNumber()
    )

    if nResult ~= UF_SUCCESS then
        return nResult
    end

    return UF_SUCCESS
end

--------------------------------------------------------------------------------
-- Ability Start
function lina_laguna_blade_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    -- Play effects
    self:PlayEffects( target )

    -- load data
    local delay = self:GetSpecialValueFor( "damage_delay" )

    -- add modfier
    target:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_lina_laguna_blade_custom", -- modifier name
        { duration = delay } -- kv
    )
end

--------------------------------------------------------------------------------
function lina_laguna_blade_custom:PlayEffects( target )

    -- Get Resources
    local particle_cast = "particles/econ/items/lina/lina_ti6/lina_ti6_laguna_blade.vpcf"
    local sound_cast = "Hero_Lina.LagunaBladeImpact.Immortal"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
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
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )
end

modifier_lina_laguna_blade_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_lina_laguna_blade_custom:IsHidden()
    return true
end

function modifier_lina_laguna_blade_custom:IsPurgable()
    return false
end

function modifier_lina_laguna_blade_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_lina_laguna_blade_custom:OnCreated( kv )
    if not IsServer() then return end
    -- references
    self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
    self.type = DAMAGE_TYPE_PURE
end

function modifier_lina_laguna_blade_custom:OnRefresh( kv )
end

function modifier_lina_laguna_blade_custom:OnRemoved()
end

function modifier_lina_laguna_blade_custom:OnDestroy()
    if not IsServer() then return end

    -- cancel if magic immune or invulnerable
    if self:GetParent():IsInvulnerable() then return end
    if self:GetParent():IsMagicImmune() then return end 

    -- cancel if linken
    if self:GetParent():TriggerSpellAbsorb( self:GetAbility() ) then return end

    -- apply damage
    local damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.damage,
        damage_type = self.type,
        ability = self:GetAbility(), --Optional.
    }
    ApplyDamage(damageTable)
end