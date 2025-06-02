LinkLuaModifier("modifier_necrolyte_aesthetics_death", "heroes/hero_necrolyte/necrolyte_aesthetics_death", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_aesthetics_death_emitter", "heroes/hero_necrolyte/necrolyte_aesthetics_death", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_aesthetics_death_enemy", "heroes/hero_necrolyte/necrolyte_aesthetics_death", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_necrolyte_aesthetics_death_enemy_execute_debuff", "heroes/hero_necrolyte/necrolyte_aesthetics_death", LUA_MODIFIER_MOTION_HORIZONTAL)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassBuffPerm = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

necrolyte_aesthetics_death = class(ItemBaseClass)
modifier_necrolyte_aesthetics_death = class(necrolyte_aesthetics_death)
modifier_necrolyte_aesthetics_death_enemy = class(ItemBaseClassAura)
modifier_necrolyte_aesthetics_death_emitter = class(ItemBaseClassBuff)
modifier_necrolyte_aesthetics_death_enemy_execute_debuff = class(ItemBaseClassDebuff)
-------------
function necrolyte_aesthetics_death:GetIntrinsicModifierName()
    return "modifier_necrolyte_aesthetics_death"
end

function necrolyte_aesthetics_death:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function necrolyte_aesthetics_death:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    --[[
    local cost = self:GetSpecialValueFor("required_charges")
    local charges = caster:FindModifierByNameAndCaster("modifier_necrolyte_corpse_charges_buff_permanent", caster)
    if charges == nil or charges:GetStackCount() < cost then
        if self:GetAutoCastState() then
            self:ToggleAutoCastState()
        end

        DisplayError(caster:GetPlayerID(), "#necrolyte_not_enough_corpse_charges")
        self:EndCooldown()
        return
    end

    if charges:GetStackCount() >= cost then
        charges:SetStackCount(charges:GetStackCount()-cost)
    end
    --]]

    local pos = self:GetCursorPosition()
    local ability = self
    local duration = ability:GetSpecialValueFor("duration")

    local emitter = CreateUnitByName("outpost_placeholder_unit", pos, false, caster, caster, caster:GetTeamNumber())
    --emitter:AddNoDraw()
    emitter:AddNewModifier(caster, ability, "modifier_necrolyte_aesthetics_death_emitter", { duration = duration })

    Timers:CreateTimer(duration, function()
        UTIL_RemoveImmediate(emitter)
    end)

    EmitSoundOn("Hero_Enigma.BlackHole.Cast.Chasm", emitter)
end

function necrolyte_aesthetics_death:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function modifier_necrolyte_aesthetics_death:OnCreated()
    if not IsServer() then return end
end

function modifier_necrolyte_aesthetics_death:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_necrolyte_aesthetics_death:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if event.attacker ~= parent then return end
    if event.inflictor == nil then return end
    if event.inflictor ~= ability then return end

    local heal = parent:GetMaxHealth() * (ability:GetSpecialValueFor("hp_pct_restore_on_kill")/100)

    parent:SetHealth(parent:GetHealth() + heal)

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_HEAL,
        parent,
        heal,
        nil
    )
end
---
function modifier_necrolyte_aesthetics_death_emitter:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.effect = nil

    self:PlayEffects(parent)
end

function modifier_necrolyte_aesthetics_death_emitter:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.effect, true)
    ParticleManager:ReleaseParticleIndex(self.effect)

    StopSoundOn("Hero_Enigma.BlackHole.Cast.Chasm", self:GetParent())
    EmitSoundOn("Hero_Enigma.Black_Hole.Stop", self:GetParent())
end

function modifier_necrolyte_aesthetics_death_emitter:OnDestroy()
    if not IsServer() then return end

    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end
end

function modifier_necrolyte_aesthetics_death_emitter:CheckState()
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
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }   

    return state
end

function modifier_necrolyte_aesthetics_death_emitter:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/enigma/enigma_world_chasm/enigma_blackhole_ti5_2.vpcf"

    -- Create Particle
    self.effect = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect, 3, target:GetAbsOrigin() )
end

function modifier_necrolyte_aesthetics_death_emitter:IsAura()
  return true
end

function modifier_necrolyte_aesthetics_death_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_necrolyte_aesthetics_death_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_necrolyte_aesthetics_death_emitter:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_necrolyte_aesthetics_death_emitter:GetModifierAura()
    return "modifier_necrolyte_aesthetics_death_enemy"
end

function modifier_necrolyte_aesthetics_death_emitter:GetAuraEntityReject(target)
    return false
end

function modifier_necrolyte_aesthetics_death_emitter:GetAuraDuration()
    return 0.1
end
------------
function modifier_necrolyte_aesthetics_death_enemy:OnCreated( kv )
    self.rate = self:GetAbility():GetSpecialValueFor( "animation_rate" )
    self.pull_speed = self:GetAbility():GetSpecialValueFor( "pull_speed" )
    self.rotate_speed = self:GetAbility():GetSpecialValueFor( "pull_rotate_speed" )

    if IsServer() then
        -- center
        self.center = Vector( self:GetCaster():GetAbsOrigin().x, self:GetCaster():GetAbsOrigin().y, 0 )

        -- apply motion controller
        if self:ApplyHorizontalMotionController() == false then
            --self:Destroy()
        end

        self:StartIntervalThink(0.25)
    end
end

function modifier_necrolyte_aesthetics_death_enemy:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster():GetOwner():GetAssignedHero()
    local ability = self:GetAbility()

    if parent:HasModifier("modifier_necrolyte_aesthetics_death_enemy_execute_debuff") then return end

    local damage = (ability:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))) * 0.25

    if (parent:GetHealthPercent() <= ability:GetSpecialValueFor("hp_execute_threshold_pct")) or (parent:GetHealth() - damage) <= 1 then
        parent:AddNewModifier(caster, ability, "modifier_necrolyte_aesthetics_death_enemy_execute_debuff", { duration = 1.5 })
        return
    end

    ApplyDamage({
        victim = parent,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })
end

function modifier_necrolyte_aesthetics_death_enemy:OnRefresh( kv )
    
end

function modifier_necrolyte_aesthetics_death_enemy:OnRemoved()
end

function modifier_necrolyte_aesthetics_death_enemy:OnDestroy()
    if IsServer() then
        -- motion compulsory interrupts
        self:GetParent():InterruptMotionControllers( true )
    end
end

function modifier_necrolyte_aesthetics_death_enemy:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA 
end
--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_necrolyte_aesthetics_death_enemy:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
    }

    return funcs
end

function modifier_necrolyte_aesthetics_death_enemy:GetOverrideAnimation()
    return ACT_DOTA_FLAIL
end

function modifier_necrolyte_aesthetics_death_enemy:GetOverrideAnimationRate()
    return self.rate
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_necrolyte_aesthetics_death_enemy:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
    }

    return state
end

--------------------------------------------------------------------------------
-- Motion Effects
function modifier_necrolyte_aesthetics_death_enemy:UpdateHorizontalMotion( me, dt )
    if self:GetParent():HasModifier("modifier_necrolyte_aesthetics_death_enemy_execute_debuff") then
        return
    end
    -- get vector
    local target = self:GetParent():GetOrigin()-self.center
    target.z = 0

    -- reduce length by pull speed
    local targetL = target:Length2D()-self.pull_speed*dt


    -- rotate by rotate speed
    local targetN = target:Normalized()
    local deg = math.atan2( targetN.y, targetN.x )
    local targetN = Vector( math.cos(deg+self.rotate_speed*dt), math.sin(deg+self.rotate_speed*dt), 0 );

    self:GetParent():SetOrigin( self.center + targetN * targetL )


end

function modifier_necrolyte_aesthetics_death_enemy:OnHorizontalMotionInterrupted()
    self:Destroy()
end
----
function modifier_necrolyte_aesthetics_death_enemy_execute_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION 
    }

    return funcs
end

function modifier_necrolyte_aesthetics_death_enemy_execute_debuff:GetModifierProvidesFOWVision()
    return 1
end

function modifier_necrolyte_aesthetics_death_enemy_execute_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self:PlayEffects3(parent)
    self:PlayEffects(parent)

    EmitSoundOn("Hero_Necrolyte.ReapersScythe.Target", parent)
end

function modifier_necrolyte_aesthetics_death_enemy_execute_debuff:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if not parent:IsAlive() then return end

    self:PlayEffects2(parent)

    parent:SetHealth(1)
    parent:Kill(self:GetAbility(), self:GetCaster())
end

function modifier_necrolyte_aesthetics_death_enemy_execute_debuff:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/necrolyte/necro_sullen_harvest/necro_sullen_harvest_scythe_model.vpcf"

    -- Create Particle
    local effect = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, target )
    ParticleManager:SetParticleControl( effect, 1, target:GetAbsOrigin() )
end

function modifier_necrolyte_aesthetics_death_enemy_execute_debuff:PlayEffects2(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/necrolyte/necro_sullen_harvest/necro_ti7_immortal_scythe_impact.vpcf"

    -- Create Particle
    local effect = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, target )
    ParticleManager:SetParticleControl( effect, 1, target:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex(effect)
end

function modifier_necrolyte_aesthetics_death_enemy_execute_debuff:PlayEffects3(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/necrolyte/necro_sullen_harvest/necro_ti7_immortal_scythe.vpcf"

    -- Create Particle
    local effect = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, target )
    ParticleManager:SetParticleControl( effect, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect, 1, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect, 3, target:GetAbsOrigin() )
end

function modifier_necrolyte_aesthetics_death_enemy_execute_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_STUNNED] = true
    }

    return state
end