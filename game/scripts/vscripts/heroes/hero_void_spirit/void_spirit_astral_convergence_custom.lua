LinkLuaModifier("modifier_void_spirit_astral_convergence_custom", "heroes/hero_void_spirit/void_spirit_astral_convergence_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_spirit_astral_convergence_custom_caster", "heroes/hero_void_spirit/void_spirit_astral_convergence_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_spirit_astral_convergence_custom_debuff", "heroes/hero_void_spirit/void_spirit_astral_convergence_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_spirit_astral_convergence_custom_emitter", "heroes/hero_void_spirit/void_spirit_astral_convergence_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassCaster = {
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

void_spirit_astral_convergence_custom = class(ItemBaseClass)
modifier_void_spirit_astral_convergence_custom = class(void_spirit_astral_convergence_custom)
modifier_void_spirit_astral_convergence_custom_caster = class(ItemBaseClassCaster)
modifier_void_spirit_astral_convergence_custom_debuff = class(ItemBaseClassDebuff)
modifier_void_spirit_astral_convergence_custom_emitter = class(ItemBaseClassCaster)
-------------
function void_spirit_astral_convergence_custom:GetAOERadius()
    return self:GetSpecialValueFor("max_distance")
end

function void_spirit_astral_convergence_custom:GetChannelTime()
    return self:GetSpecialValueFor("duration")
end

function void_spirit_astral_convergence_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local dissimilate_Duration = 0

    -- Dissimilate
    local dissimilate = "modifier_void_spirit_dissimilate_custom"
    if caster:HasModifier(dissimilate) then
        local dissimilate_Ability = caster:FindAbilityByName("void_spirit_dissimilate_custom")
        local dissimilate_Mod = caster:FindModifierByName(dissimilate)
        if dissimilate_Ability ~= nil and dissimilate_Mod ~= nil then
            dissimilate_Duration = dissimilate_Mod:GetRemainingTime()
            caster:RemoveModifierByName(dissimilate)
            caster:AddNewModifier(caster, dissimilate_Ability, dissimilate, {})
        end
    end

    -- Cast
    caster:AddNewModifier(caster, self, "modifier_void_spirit_astral_convergence_custom_caster", {
        x = point.x,
        y = point.y,
        z = point.z,
        duration = self:GetSpecialValueFor("duration"),
        dissimilate = dissimilate_Duration
    })

    EmitSoundOn("Hero_VoidSpirit.Dissimilate.Cast", caster)
end

function void_spirit_astral_convergence_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_void_spirit_astral_convergence_custom_caster")
end
--------------------
function modifier_void_spirit_astral_convergence_custom_caster:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }
end

function modifier_void_spirit_astral_convergence_custom_caster:DeclareFunctions()
    return {
        --MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_void_spirit_astral_convergence_custom_caster:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end

    self.damage = self.damage + event.damage
end

function modifier_void_spirit_astral_convergence_custom_caster:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local interval = ability:GetSpecialValueFor("interval")
    local radius = ability:GetSpecialValueFor("max_distance")
    local duration = ability:GetSpecialValueFor("duration")

    self.dissimilateDuration = params.dissimilate

    self.point = Vector(params.x, params.y, params.z)

    local emitter = CreateUnitByName("outpost_placeholder_unit", self.point, false, parent, parent, parent:GetTeamNumber())
    emitter:AddNewModifier(parent, ability, "modifier_void_spirit_astral_convergence_custom_emitter", { 
        duration = duration
    })

    self.timer = nil
    self.fadeTimer = nil

    self.damage = 0

    parent:AddNoDraw()

    self:StartIntervalThink(interval)
end

function modifier_void_spirit_astral_convergence_custom_caster:OnIntervalThink()
    self:DoAstralStep()
end

function modifier_void_spirit_astral_convergence_custom_caster:GetRandomPointOnCircleEdge(center, radius)
    local angle = RandomFloat(0, 2 * math.pi)
    local x = center.x + radius * math.cos(angle)
    local y = center.y + radius * math.sin(angle)
    return Vector(x, y, center.z)
end

function modifier_void_spirit_astral_convergence_custom_caster:DoAstralStep()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if self.timer ~= nil then
        Timers:RemoveTimer(self.timer)
        self.timer = nil
    end

    -- load data
    local radius = ability:GetSpecialValueFor( "line_slash_radius" )
    local pop_delay = ability:GetSpecialValueFor( "pop_damage_delay" )
    local pop_damage = ability:GetSpecialValueFor( "pop_damage" ) + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    -- find a random location at the edge of the circle radius
    local maxDistance = ability:GetSpecialValueFor("max_distance")
    local randomEdgeLoc = self:GetRandomPointOnCircleEdge(self.point, maxDistance)

    -- teleport to outer edge (this is where the slash starts from)
    local initialLoc = GetGroundPosition(randomEdgeLoc, nil)
    caster:SetAbsOrigin(initialLoc)

    local delay = ability:GetSpecialValueFor("interval")-0.1
    local slashDamage = caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("attack_to_damage")/100)

    caster:FaceTowards(self.point)

    self.timer = Timers:CreateTimer(delay, function()
        caster:RemoveNoDraw()
        caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)

        -- find destination
        local direction = (randomEdgeLoc - self.point):Normalized()
        local dist = math.max( math.min( maxDistance, direction:Length2D() ), 1 )
        direction.z = 0
        direction = direction:Normalized()

        local target = GetGroundPosition(self.point + direction * dist, nil)

        -- teleport
        caster:SetAbsOrigin(target)

        -- find units in line
        local enemies = FindUnitsInLine(
            self:GetCaster():GetTeamNumber(),   -- int, your team number
            randomEdgeLoc, -- point, start point
            target, -- point, end point
            nil,    -- handle, cacheUnit. (not known)
            radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES  -- int, flag filter
        )

        for _,enemy in pairs(enemies) do
            if not enemy:IsAlive() or enemy:IsMagicImmune() then break end
            -- perform attack
            --caster:PerformAttack( enemy, true, true, true, false, true, false, true )
            local slashDamageTable = {
                attacker = caster,
                victim = enemy,
                damage = slashDamage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = ability
            }

            if self:GetCaster():HasModifier("modifier_void_spirit_aether_remnant_custom_emitter") then
                slashDamageTable.attacker = self:GetCaster():GetOwner():GetAssignedHero()
            end

            ApplyDamage(slashDamageTable)
            self.damage = self.damage + pop_damage + slashDamage

            -- add modifier
            enemy:AddNewModifier(
                caster, -- player source
                ability, -- ability source
                "modifier_void_spirit_astral_convergence_custom_debuff", -- modifier name
                { duration = pop_delay } -- kv
            )

            -- play effects
            self:PlayEffects2( enemy )
        end

        -- play effects
        self:PlayEffects1( randomEdgeLoc, target )

        if self.fadeTimer ~= nil then
            Timers:RemoveTimer(self.fadeTimer)
            self.fadeTimer = nil
        end

        self.fadeTimer = Timers:CreateTimer(delay, function()
            caster:AddNoDraw()
        end)
    end)
end

function modifier_void_spirit_astral_convergence_custom_caster:PlayEffects1( origin, target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_void_spirit/astral_step/void_spirit_astral_step.vpcf"
    local sound_start = "Hero_VoidSpirit.AstralStep.Start"
    local sound_end = "Hero_VoidSpirit.AstralStep.End"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, origin )
    ParticleManager:SetParticleControl( effect_cast, 1, target )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOnLocationWithCaster( origin, sound_start, self:GetCaster() )
    EmitSoundOnLocationWithCaster( target, sound_end, self:GetCaster() )
end

function modifier_void_spirit_astral_convergence_custom_caster:PlayEffects2( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_void_spirit/astral_step/void_spirit_astral_step_impact.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_void_spirit_astral_convergence_custom_caster:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("max_distance")

    parent:RemoveNoDraw()

    if self.timer ~= nil then
        Timers:RemoveTimer(self.timer)
        self.timer = nil
    end

    if self.fadeTimer ~= nil then
        Timers:RemoveTimer(self.fadeTimer)
        self.fadeTimer = nil
    end

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        local explosionDamageTable = {
            victim = victim, 
            attacker = parent, 
            damage = self.damage * (ability:GetSpecialValueFor("end_multiplier")/100), 
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        }

        if parent:HasModifier("modifier_void_spirit_aether_remnant_custom_emitter") then
            explosionDamageTable.attacker = parent:GetOwner():GetAssignedHero()
        end

        ApplyDamage(explosionDamageTable)
    end

    EmitSoundOn("Hero_VoidSpirit.Dissimilate.Stun", parent)

    FindClearSpaceForUnit(parent, self.point, false)

    -- Re-apply dissimilate with its old duration
    local dissimilate = "modifier_void_spirit_dissimilate_custom"
    if parent:HasModifier(dissimilate) then
        local dissimilate_Ability = parent:FindAbilityByName("void_spirit_dissimilate_custom")
        if dissimilate_Ability ~= nil then
            parent:RemoveModifierByName(dissimilate)
            parent:AddNewModifier(parent, dissimilate_Ability, dissimilate, {
                duration = self.dissimilateDuration
            })
        end
    end
end

function modifier_void_spirit_astral_convergence_custom_caster:GetStatusEffectName()
    return "particles/status_fx/status_effect_void_spirit_pulse_buff.vpcf"
end

function modifier_void_spirit_astral_convergence_custom_caster:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_void_spirit_astral_convergence_custom_caster:StatusEffectPriority()
    return 10001
end
------------------------------
function modifier_void_spirit_astral_convergence_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_void_spirit_astral_convergence_custom_debuff:IsStackable() return true end
--------------------------------------------------------------------------------
-- Initializations
function modifier_void_spirit_astral_convergence_custom_debuff:OnCreated( kv )
    if not IsServer() then return end

    -- references
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    self.damage = self:GetAbility():GetSpecialValueFor( "pop_damage" ) + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))
    self.slow = -self:GetAbility():GetSpecialValueFor( "movement_slow_pct" )
end

function modifier_void_spirit_astral_convergence_custom_debuff:OnRefresh( kv )
    
end

function modifier_void_spirit_astral_convergence_custom_debuff:OnRemoved()
end

function modifier_void_spirit_astral_convergence_custom_debuff:OnDestroy()
    if not IsServer() then return end
    if self:GetParent():IsMagicImmune() then return end

    -- Apply damage
    local damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(), --Optional.
    }

    if self:GetCaster():HasModifier("modifier_void_spirit_aether_remnant_custom_emitter") then
        damageTable.attacker = self:GetCaster():GetOwner():GetAssignedHero()
    end

    ApplyDamage(damageTable)

    -- play effects
    self:PlayEffects()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_void_spirit_astral_convergence_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_void_spirit_astral_convergence_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_void_spirit_astral_convergence_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_void_spirit/astral_step/void_spirit_astral_step_debuff.vpcf"
end

function modifier_void_spirit_astral_convergence_custom_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_void_spirit_astral_convergence_custom_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_void_spirit_astral_step_debuff.vpcf"
end

function modifier_void_spirit_astral_convergence_custom_debuff:StatusEffectPriority()
    return MODIFIER_PRIORITY_NORMAL
end

function modifier_void_spirit_astral_convergence_custom_debuff:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_void_spirit/astral_step/void_spirit_astral_step_dmg.vpcf"
    local sound_target = "Hero_VoidSpirit.AstralStep.MarkExplosion"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_target, self:GetParent() )
end
--------------------
function modifier_void_spirit_astral_convergence_custom_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_void_spirit_astral_convergence_custom_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_void_spirit_astral_convergence_custom_emitter:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("max_distance")+100
    local radius2 = ability:GetSpecialValueFor("max_distance")

    self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_void_spirit/dissimilate/void_spirit_dissimilate_2.vpcf", PATTACH_CUSTOMORIGIN, parent)
    ParticleManager:SetParticleControl(self.pfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pfx, 1, Vector(radius,radius,radius))
    ParticleManager:SetParticleControl(self.pfx, 2, Vector(radius,radius,radius))
    ParticleManager:SetParticleControl(self.pfx, 3, Vector(radius,radius,radius))

    self.pfxBubble = ParticleManager:CreateParticle("particles/arc_warden_magnetic_custom.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.pfxBubble, 0, parent:GetOrigin())
    ParticleManager:SetParticleControl(self.pfxBubble, 1, Vector(radius2,radius2,radius2))

    -- buff particle
    self:AddParticle(
        self.pfxBubble,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        true, -- bHeroEffect
        false -- bOverheadEffect
    )

    self:StartIntervalThink(FrameTime())
end

function modifier_void_spirit_astral_convergence_custom_emitter:OnIntervalThink()
    if not self:GetCaster():IsChanneling() or not self:GetCaster():HasModifier("modifier_void_spirit_astral_convergence_custom_caster") then
        self:Destroy()
        return
    end
end

function modifier_void_spirit_astral_convergence_custom_emitter:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("max_distance")

    -- Final Damage --
    self.finalPfx = ParticleManager:CreateParticle("particles/units/heroes/hero_void_spirit/dissimilate/void_spirit_dissimilate_dmg.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(self.finalPfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.finalPfx, 1, Vector(radius-200,radius-200,radius-200))
    ParticleManager:ReleaseParticleIndex(self.finalPfx)

    if self.pfx ~= nil then
        ParticleManager:DestroyParticle(self.pfx, false)
        ParticleManager:ReleaseParticleIndex(self.pfx)
    end

    if self.pfxBubble ~= nil then
        ParticleManager:DestroyParticle(self.pfxBubble, false)
        ParticleManager:ReleaseParticleIndex(self.pfxBubble)
    end
    
    if self:GetParent():IsAlive() then
        --self:GetParent():Kill(nil, nil)
        UTIL_RemoveImmediate(self:GetParent())
    end
end

function modifier_void_spirit_astral_convergence_custom_emitter:CheckState()
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
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end