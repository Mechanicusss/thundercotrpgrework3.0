lina_light_strike_array_custom = class({})
LinkLuaModifier( "modifier_lina_light_strike_array_custom", "heroes/hero_lina/lina_light_strike_array_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_lina_light_strike_array_custom_def", "heroes/hero_lina/lina_light_strike_array_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_light_strike_array_custom_debuff", "heroes/hero_lina/lina_light_strike_array_custom", LUA_MODIFIER_MOTION_NONE)


modifier_lina_light_strike_array_custom_def = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
})

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

modifier_lina_light_strike_array_custom_debuff = class(ItemBaseClassDebuff)

function lina_light_strike_array_custom:GetIntrinsicModifierName()
  return "modifier_lina_light_strike_array_custom_def"
end

function modifier_lina_light_strike_array_custom_def:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_lina_light_strike_array_custom_def:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()

    if parent ~= event.attacker or parent == event.target then return end

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")
    if not RollPercentage(chance) then return end

    local point = event.target

    parent:StartGesture(ACT_DOTA_CAST_ABILITY_2)
    
    local duration = ability:GetSpecialValueFor( "light_strike_array_delay_time" )

    local point = event.target:GetAbsOrigin()

    -- create thinker
    CreateModifierThinker(
        parent, -- player source
        ability, -- ability source
        "modifier_lina_light_strike_array_custom", -- modifier name
        { duration = duration }, -- kv
        point,
        parent:GetTeamNumber(),
        false
    )

    -- Add Fiery Soul buff before damage is done 
    local fierySoul = caster:FindModifierByName("modifier_lina_fiery_soul_custom")
    local fierySoul_Ability = caster:FindAbilityByName("lina_fiery_soul_custom")
    
    if fierySoul_Ability ~= nil then
        if not fierySoul then
            fierySoul = caster:AddNewModifier(caster, fierySoul_Ability, "modifier_lina_fiery_soul_custom", { duration = fierySoul_Ability:GetSpecialValueFor("fiery_soul_stack_duration") })
        end

        if fierySoul then
            if fierySoul:GetStackCount() < fierySoul_Ability:GetSpecialValueFor("fiery_soul_max_stacks") then
                fierySoul:IncrementStackCount()
            end

            fierySoul:ForceRefresh()
        end
    end
end
--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function lina_light_strike_array_custom:GetAOERadius()
    return self:GetSpecialValueFor( "light_strike_array_aoe" )
end

--------------------------------------------------------------------------------
-- Ability Start

modifier_lina_light_strike_array_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_lina_light_strike_array_custom:IsHidden()
    return true
end

function modifier_lina_light_strike_array_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_lina_light_strike_array_custom:OnCreated( kv )
    -- references
    self.stun = self:GetAbility():GetSpecialValueFor( "light_strike_array_stun_duration" )
    self.damage = self:GetAbility():GetSpecialValueFor( "light_strike_array_damage" )
    self.radius = self:GetAbility():GetSpecialValueFor( "light_strike_array_aoe" )

    if not IsServer() then return end
    -- play effects
    self:PlayEffects1()
end

function modifier_lina_light_strike_array_custom:OnRefresh( kv )
    
end

function modifier_lina_light_strike_array_custom:OnRemoved()
end

function modifier_lina_light_strike_array_custom:OnDestroy()
    if not IsServer() then return end
    -- destroy trees
    GridNav:DestroyTreesAroundPoint( self:GetParent():GetOrigin(), self.radius, false )

    local damage = self.damage + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100))
    local caster = self:GetCaster()

    local fierySoul = caster:FindModifierByName("modifier_lina_fiery_soul_custom")
    if fierySoul then
        local fierySoul_Ability = fierySoul:GetAbility()

        damage = damage + (fierySoul_Ability:GetSpecialValueFor("fiery_soul_spell_damage") * fierySoul:GetStackCount())
    end

    -- precache damage
    local damageTable = {
        -- victim = target,
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self, --Optional.
    }
    -- ApplyDamage(damageTable)

    -- find enemies
    local enemies = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(),   -- int, your team number
        self:GetParent():GetOrigin(),   -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        -- damage
        damageTable.victim = enemy

        local debuff = enemy:FindModifierByName("modifier_lina_light_strike_array_custom_debuff")

        if not debuff then
            debuff = enemy:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_lina_light_strike_array_custom_debuff", {
                duration = self:GetAbility():GetSpecialValueFor("burn_duration")
            })
        end

        if debuff then
            local runeLightStrikeArray = caster:FindModifierByName("modifier_item_socket_rune_legendary_lina_light_strike_array")
            if not runeLightStrikeArray then
                if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("burn_max_stacks") then
                    debuff:IncrementStackCount()
                end
            else
                debuff:IncrementStackCount()
            end

            debuff:ForceRefresh()
        end

        ApplyDamage( damageTable )
    end

    -- play effects
    self:PlayEffects2()

    -- remove thinker
    UTIL_Remove( self:GetParent() )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_lina_light_strike_array_custom:PlayEffects1()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_lina/lina_spell_light_strike_array_ray_team.vpcf"
    local sound_cast = "Ability.PreLightStrikeArray"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticleForTeam( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster(), self:GetCaster():GetTeamNumber() )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 1, 1 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOnLocationForAllies( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end

function modifier_lina_light_strike_array_custom:PlayEffects2()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf"
    local sound_cast = "Ability.LightStrikeArray"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 1, 1 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end
----------------------
function modifier_lina_light_strike_array_custom_debuff:OnCreated()
    if not IsServer() then return end

    self.interval = self:GetAbility():GetSpecialValueFor("burn_interval")

    self:StartIntervalThink(self.interval)
end

function modifier_lina_light_strike_array_custom_debuff:OnIntervalThink()
    local damage = self:GetStackCount() * (self:GetAbility():GetSpecialValueFor("burn_dps") + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100)))
    local caster = self:GetCaster()
    
    local fierySoul = caster:FindModifierByName("modifier_lina_fiery_soul_custom")
    if fierySoul then
        local fierySoul_Ability = fierySoul:GetAbility()

        damage = damage + (fierySoul_Ability:GetSpecialValueFor("fiery_soul_spell_damage") * fierySoul:GetStackCount())
    end

    ApplyDamage({
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage = damage,
        ability = self:GetAbility(),
        damage_type = DAMAGE_TYPE_MAGICAL,
    })

    local runeLightStrikeArray = caster:FindModifierByName("modifier_item_socket_rune_legendary_lina_light_strike_array")
    if runeLightStrikeArray then
        if RollPercentage(runeLightStrikeArray.stunChance) then
            self:GetParent():AddNewModifier(caster, nil, "modifier_stunned", {
                duration = runeLightStrikeArray.stunDuration
            })
        end
    end
end

function modifier_lina_light_strike_array_custom_debuff:GetEffectName()
    return "particles/econ/items/phoenix/phoenix_ti10_immortal/phoenix_ti10_fire_spirit_burn.vpcf"
end