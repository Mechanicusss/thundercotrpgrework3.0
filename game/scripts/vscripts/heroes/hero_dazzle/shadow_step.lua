LinkLuaModifier("modifier_dazzle_shadow_step", "heroes/hero_dazzle/shadow_step", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_shadow_step_emitter", "heroes/hero_dazzle/shadow_step", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_shadow_step_emitter_aura", "heroes/hero_dazzle/shadow_step", LUA_MODIFIER_MOTION_NONE)


local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

dazzle_shadow_step = class(ItemBaseClass)
modifier_dazzle_shadow_step = class(dazzle_shadow_step)
modifier_dazzle_shadow_step_emitter = class(ItemBaseClass)
modifier_dazzle_shadow_step_emitter_aura = class(ItemBaseAura)
-------------
function dazzle_shadow_step:GetIntrinsicModifierName()
    return "modifier_dazzle_shadow_step"
end

function dazzle_shadow_step:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function dazzle_shadow_step:OnSpellStart()
    if not IsServer() then return end

    local point = self:GetCursorPosition()
    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
    local interval = ability:GetLevelSpecialValueFor("interval", (ability:GetLevel() - 1))

    -- Particle --
    local vfx = ParticleManager:CreateParticle("particles/dazzle/dazzle_shadow_step.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(vfx, 0, point)
    ParticleManager:SetParticleControl(vfx, 1, Vector(radius, radius, radius))
    -- --

    -- Create Placeholder Unit that holds the aura --
    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNoDraw()
    emitter:AddNewModifier(caster, ability, "modifier_dazzle_shadow_step_emitter", { duration = duration, radius = radius, interval = interval })
    -- --

    caster:EmitSound("Hero_Dazzle.BadJuJu.Target")

    Timers:CreateTimer(duration, function()
        ParticleManager:DestroyParticle(vfx, false)
        ParticleManager:ReleaseParticleIndex(vfx)
        emitter:ForceKill(false)
    end)
end
------------
function modifier_dazzle_shadow_step:DeclareFunctions()
    local funcs = {}

    return funcs
end

function modifier_dazzle_shadow_step:OnCreated()
    if not IsServer() then return end
end
----------------
function modifier_dazzle_shadow_step_emitter:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()

    self.radius = params.radius
end

function modifier_dazzle_shadow_step_emitter:OnDestroy()
    if not IsServer() then return end

    self:GetParent():ForceKill(false)
end

function modifier_dazzle_shadow_step_emitter:CheckState()
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

function modifier_dazzle_shadow_step_emitter:IsAura()
  return true
end

function modifier_dazzle_shadow_step_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_dazzle_shadow_step_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_dazzle_shadow_step_emitter:GetAuraRadius()
  return self.radius
end

function modifier_dazzle_shadow_step_emitter:GetModifierAura()
    return "modifier_dazzle_shadow_step_emitter_aura"
end

function modifier_dazzle_shadow_step_emitter:GetAuraEntityReject(ent) 
    return false
end
--------------
function modifier_dazzle_shadow_step_emitter_aura:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("interval")
    
    self.jumps = ability:GetSpecialValueFor("max_targets")
    self.heal = ability:GetSpecialValueFor("heal_amount") + (self:GetCaster():GetBaseIntellect() * (ability:GetSpecialValueFor("bonus_from_int")/100))
    self.radius = ability:GetSpecialValueFor("damage_radius")
    self.bounce_radius = ability:GetSpecialValueFor("bounce_radius")
    self.damage = self.heal

    self.healedUnits = {}

    table.insert( self.healedUnits, self:GetCaster() )

    self.damageTable = {
        -- victim = target,
        attacker = self:GetCaster(),
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability, --Optional.
    }

    self:StartIntervalThink(interval)
end

function modifier_dazzle_shadow_step_emitter_aura:OnIntervalThink()
    self:Jump( self.jumps, self:GetParent(), self:GetParent() )
    EmitSoundOn("Hero_Dazzle.Shadow_Wave", self:GetParent())
end

function modifier_dazzle_shadow_step_emitter_aura:Jump( jumps, source, target )
    -- Heal
    source:Heal( self.heal, self:GetAbility() )
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, source, self.heal, nil)

    -- Find enemy nearby
    local enemies = FindUnitsInRadius(
        source:GetTeamNumber(), -- int, your team number
        source:GetOrigin(), -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    -- Damage
    for _,enemy in pairs(enemies) do
        self.damageTable.victim = enemy
        ApplyDamage( self.damageTable )

        -- Play effects
        self:PlayEffects2( enemy )
    end

    -- counter
    local jump = jumps-1
    if jump <0 then
        return
    end

    -- next target
    local nextTarget = nil
    if target and target~=source then
        nextTarget = target
    else
        -- Find ally nearby
        local allies = FindUnitsInRadius(
            source:GetTeamNumber(), -- int, your team number
            source:GetOrigin(), -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            self.bounce_radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_FRIENDLY, -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            0,  -- int, flag filter
            FIND_CLOSEST,   -- int, order filter
            false   -- bool, can grow cache
        )
        
        for _,ally in pairs(allies) do
            local pass = false
            for _,unit in pairs(self.healedUnits) do
                if ally==unit then
                    pass = true
                end
            end

            if not pass then
                nextTarget = ally
                break
            end
        end
    end

    if nextTarget then
        table.insert( self.healedUnits, nextTarget )
        self:Jump( jump, nextTarget )
    end

    -- Play effects
    self:PlayEffects1( source, nextTarget )

end

function modifier_dazzle_shadow_step_emitter_aura:PlayEffects1( source, target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_dazzle/dazzle_shadow_wave.vpcf"

    if not target then
        target = source
    end

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, source )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        source,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        source:GetOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_dazzle_shadow_step_emitter_aura:PlayEffects2( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_dazzle/dazzle_shadow_wave_impact_damage.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end