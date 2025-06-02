LinkLuaModifier("modifier_pudge_flesh_pounce", "heroes/hero_pudge/pounce", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_knockback_lua", "modifiers/modifier_generic_knockback_lua", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier("modifier_generic_stunned_lua", "modifiers/modifier_generic_stunned_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_pudge_flesh_pounce_rot_emitter", "heroes/hero_pudge/pounce", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

pudge_flesh_pounce = class(ItemBaseClass)
modifier_pudge_flesh_pounce = class(pudge_flesh_pounce)
modifier_pudge_flesh_pounce_rot_emitter = class(ItemBaseClass)
-------------
function pudge_flesh_pounce:GetIntrinsicModifierName()
    return "modifier_pudge_flesh_pounce"
end

function pudge_flesh_pounce:CreateRotEmitter(caster, location, ability, duration, rot)
    CreateUnitByNameAsync("outpost_placeholder_unit", location, false, caster, caster, caster:GetTeamNumber(), function(unit)
        unit:AddNoDraw()
        unit:AddNewModifier(caster, ability, "modifier_pudge_flesh_pounce_rot_emitter", { duration = duration })
    end)
end

function pudge_flesh_pounce:OnSpellStart()
    if not IsServer() then return end

    local target = self:GetCaster()

    local distance = self:GetEffectiveCastRange(target:GetOrigin(), nil) -- Based on the cast range

    local duration = distance / 1000 -- proportional to the distance
    local height = distance * 0.57 -- proportional to the distance
    
    local stun = self:GetSpecialValueFor("impact_stun_duration")
    local damage = self:GetSpecialValueFor("impact_damage")
    local strengthMultiplier = self:GetSpecialValueFor("strength_damage_pct") / 100
    local radius = self:GetSpecialValueFor("impact_radius")
    
    -- knockback
    local knockback = target:AddNewModifier(
        target, -- player source
        self, -- ability source
        "modifier_generic_knockback_lua", -- modifier name
        {
            distance = distance,
            height = height,
            duration = duration,
            direction_x = target:GetForwardVector().x,
            direction_y = target:GetForwardVector().y,
            IsStun = true,
        } -- kv
    )

    Timers:CreateTimer(duration, function()
        -- Effect --
        local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_snapfire/hero_snapfire_cookie_landing.vpcf", PATTACH_WORLDORIGIN, target )
        ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
        ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
        ParticleManager:ReleaseParticleIndex( effect_cast )

        -- Create Sound
        EmitSoundOn( "Hero_Snapfire.FeedCookie.Impact", target )

        -- precache damage
        local damageTable = {
            -- victim = target,
            attacker = target,
            damage = damage + (target:GetStrength() * strengthMultiplier),
            damage_type = self:GetAbilityDamageType(),
            ability = self, --Optional.
        }

        -- find enemies
        local enemies = FindUnitsInRadius(
            target:GetTeamNumber(),   -- int, your team number
            target:GetOrigin(), -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            0,  -- int, flag filter
            0,  -- int, order filter
            false   -- bool, can grow cache
        )

        for _,enemy in pairs(enemies) do
            -- apply damage
            damageTable.victim = enemy
            ApplyDamage(damageTable)

            -- stun
            enemy:AddNewModifier(
                target, -- player source
                self, -- ability source
                "modifier_generic_stunned_lua", -- modifier name
                { duration = stun } -- kv
            )
        end

        -- destroy trees
        GridNav:DestroyTreesAroundPoint(target:GetOrigin(), radius, true)

        -- Rot Emitter 
        local rotCloudDuration = self:GetSpecialValueFor("rot_cloud_duration")
        local pudgeRot = target:FindAbilityByName("pudge_rot_custom")

        if not pudgeRot then return end
        if pudgeRot:GetLevel() < 1 then return end

        pudge_flesh_pounce:CreateRotEmitter(target, target:GetOrigin(), self, rotCloudDuration, pudgeRot)
    end)
end
------------
function modifier_pudge_flesh_pounce_rot_emitter:OnCreated(params)
    if not IsServer() then return end

    local unit = self:GetParent()
    local caster = self:GetCaster()

    if caster:HasModifier("modifier_item_ultimate_scepter") or caster:HasModifier("modifier_item_ultimate_scepter_consumed_alchemist") or caster:HasModifier("modifier_item_ultimate_scepter_consumed") then
        unit:AddNewModifier(unit, nil, "modifier_item_ultimate_scepter_consumed", {})
    end

    local parentRot = caster:FindAbilityByName("pudge_rot_custom")
    
    self.rot = unit:AddAbility("pudge_rot_custom")

    self.rot:SetLevel(parentRot:GetLevel())

    self.rot:ToggleAbility()

    -- Particle --
    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_rot.vpcf", PATTACH_WORLDORIGIN, unit)
    ParticleManager:SetParticleControl(self.particle, 0, unit:GetOrigin())
    ParticleManager:SetParticleControl(self.particle, 1, Vector(self.rot:GetAOERadius(), self.rot:GetAOERadius(), self.rot:GetAOERadius()))
end

function modifier_pudge_flesh_pounce_rot_emitter:OnDestroy(params)
    if not IsServer() then return end

    self.rot:ToggleAbility()
    self:GetParent():RemoveAbilityByHandle(self.rot)

    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)

    self:GetParent():ForceKill(false)
end

function modifier_pudge_flesh_pounce_rot_emitter:CheckState()
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