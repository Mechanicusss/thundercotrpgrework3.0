LinkLuaModifier("modifier_luna_might_of_the_moon_custom", "heroes/hero_luna/luna_might_of_the_moon_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_luna_might_of_the_moon_custom_stacks", "heroes/hero_luna/luna_might_of_the_moon_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_luna_might_of_the_moon_custom_damage", "heroes/hero_luna/luna_might_of_the_moon_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_luna_might_of_the_moon_custom_sunstrike_pre", "heroes/hero_luna/luna_might_of_the_moon_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_luna_might_of_the_moon_custom_sunstrike_thinker", "heroes/hero_luna/luna_might_of_the_moon_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_luna_might_of_the_moon_custom_scepter", "heroes/hero_luna/luna_might_of_the_moon_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassSun = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

luna_might_of_the_moon_custom = class(ItemBaseClass)
modifier_luna_might_of_the_moon_custom = class(luna_might_of_the_moon_custom)
modifier_luna_might_of_the_moon_custom_stacks = class(ItemBaseClassSun)
modifier_luna_might_of_the_moon_custom_damage = class(ItemBaseClassSun)
modifier_luna_might_of_the_moon_custom_sunstrike_pre = class(ItemBaseClassSun)
modifier_luna_might_of_the_moon_custom_sunstrike_thinker = class(ItemBaseClassSun)
modifier_luna_might_of_the_moon_custom_scepter = class(ItemBaseClassSun)

function modifier_luna_might_of_the_moon_custom_sunstrike_pre:IsHidden() return true end
function modifier_luna_might_of_the_moon_custom_sunstrike_thinker:IsHidden() return true end
----------------------
function luna_might_of_the_moon_custom:GetIntrinsicModifierName()
    return "modifier_luna_might_of_the_moon_custom"
end

function luna_might_of_the_moon_custom:GetAOERadius()
    return self:GetSpecialValueFor("sun_strike_aoe")
end

function luna_might_of_the_moon_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local pos = self:GetCursorPosition()

    caster:AddNewModifier(caster, self, "modifier_luna_might_of_the_moon_custom_sunstrike_pre", {
        x = pos.x,
        y = pos.y,
        z = pos.z
    })

    caster:RemoveModifierByName("modifier_luna_might_of_the_moon_custom_stacks")

    self:SetActivated(false)
end
---------------------
function modifier_luna_might_of_the_moon_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED 
    }
end

function modifier_luna_might_of_the_moon_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    ability:SetActivated(false)
end

function modifier_luna_might_of_the_moon_custom:OnAbilityExecuted(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if parent ~= event.unit then return end
    if event.ability == ability then return end

    if string.match(event.ability:GetAbilityName(), "luna_") and not event.ability:IsToggle() then
        -- Damage Bonus --
        local bonusDamage = parent:FindModifierByName("modifier_luna_might_of_the_moon_custom_damage")

        if not bonusDamage then
            bonusDamage = parent:AddNewModifier(parent, ability, "modifier_luna_might_of_the_moon_custom_damage", {
                duration = ability:GetSpecialValueFor("duration")
            })
        end

        if bonusDamage then
            if bonusDamage:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
                bonusDamage:IncrementStackCount()
            end

            bonusDamage:ForceRefresh()
        end
    end

    if event.ability:GetAbilityName() ~= "luna_moon_beam_custom" then return end

    -- Stacks --
    local buff = parent:FindModifierByName("modifier_luna_might_of_the_moon_custom_stacks")

    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_luna_might_of_the_moon_custom_stacks", {})
    end

    if buff then
        if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end

        if buff:GetStackCount() == ability:GetSpecialValueFor("max_stacks") then
            ability:SetActivated(true)

            if parent:HasScepter() and not parent:HasModifier("modifier_luna_might_of_the_moon_custom_scepter") then
                parent:AddNewModifier(parent, ability, "modifier_luna_might_of_the_moon_custom_scepter", {
                    duration = ability:GetSpecialValueFor("scepter_duration")
                })
            end
        end

        buff:ForceRefresh()
    end
end
---------------
function modifier_luna_might_of_the_moon_custom_stacks:RemoveOnDeath() return false end
-------------
function modifier_luna_might_of_the_moon_custom_sunstrike_pre:OnCreated(params)
    if not IsServer() then return end

    self.pos = Vector(params.x, params.y, params.z)
    self:StartIntervalThink(0.1)
end

function modifier_luna_might_of_the_moon_custom_sunstrike_pre:OnIntervalThink()
    if not IsServer() then return end

    local parent = self:GetParent()
    local pos = parent:GetAbsOrigin()
    local ability = self:GetAbility()
    local radius = 600

    -- get values
    local delay = ability:GetSpecialValueFor("sun_strike_delay")
    local vision_distance = ability:GetSpecialValueFor("sun_strike_aoe")
    local vision_duration = 4

    -- create modifier thinker
    CreateModifierThinker(
        parent,
        ability,
        "modifier_luna_might_of_the_moon_custom_sunstrike_thinker",
        { duration = delay },
        self.pos,
        bit.bor(DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS),
        false
    )

    -- create vision
    AddFOWViewer(bit.bor(DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS), self.pos, vision_distance, 4, false )

    self:Destroy()
end
-----------------
function modifier_luna_might_of_the_moon_custom_sunstrike_thinker:OnCreated( kv )
    if IsServer() then
        -- references
        self.damage = self:GetAbility():GetSpecialValueFor("sun_strike_damage")
        self.radius = self:GetAbility():GetSpecialValueFor("sun_strike_aoe")

        -- Play effects
        self:PlayEffects1()
    end
end

function modifier_luna_might_of_the_moon_custom_sunstrike_thinker:OnDestroy( kv )
    if IsServer() then
        -- Damage enemies
        local damageTable = {
            -- victim = target,
            attacker = self:GetCaster(),
            damage = self.damage + (self:GetCaster():GetBaseIntellect() * (self:GetAbility():GetSpecialValueFor("int_to_damage")/100)),
            damage_type = DAMAGE_TYPE_PURE,
            ability = self:GetAbility(), --Optional.
        }

        local enemies = FindUnitsInRadius(
            self:GetCaster():GetTeamNumber(),   -- int, your team number
            self:GetParent():GetOrigin(),   -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            self.radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, -- int, flag filter
            0,  -- int, order filter
            false   -- bool, can grow cache
        )

        for _,enemy in pairs(enemies) do
            damageTable.victim = enemy
            ApplyDamage(damageTable)

            if self:GetCaster():HasModifier("modifier_luna_might_of_the_moon_custom_scepter") then
                ApplyDamage({
                    victim = enemy,
                    attacker = self:GetCaster(),
                    damage = damageTable.damage * (self:GetAbility():GetSpecialValueFor("scepter_split_damage_pct")/100),
                    damage_type = DAMAGE_TYPE_MAGICAL,
                    ability = self:GetAbility()
                })
            end
        end

        -- Play effects
        self:PlayEffects2()

        self:GetCaster():RemoveModifierByName("modifier_luna_might_of_the_moon_custom_scepter")

        -- remove thinker
        UTIL_Remove( self:GetParent() )
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_luna_might_of_the_moon_custom_sunstrike_thinker:PlayEffects1()
    -- Get Resources
    local particle_cast = "particles/econ/items/invoker/invoker_apex/invoker_sun_strike_team_immortal1.vpcf"
    local sound_cast = "Hero_Invoker.SunStrike.Charge.Apex"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end

function modifier_luna_might_of_the_moon_custom_sunstrike_thinker:PlayEffects2()
    -- Get Resources
    local particle_cast = "particles/econ/items/invoker/invoker_apex/invoker_sun_strike_immortal1.vpcf"
    local sound_cast = "Hero_Invoker.SunStrike.Ignite.Apex"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end
-----------------
function modifier_luna_might_of_the_moon_custom_damage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_luna_might_of_the_moon_custom_damage:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("damage_increase") * self:GetStackCount()
end
------------
function modifier_luna_might_of_the_moon_custom_stacks:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
end

function modifier_luna_might_of_the_moon_custom_stacks:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("spell_damage_increase") * self:GetStackCount()
end