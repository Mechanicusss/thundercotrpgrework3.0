LinkLuaModifier("modifier_mars_gods_rebuke_custom", "heroes/hero_mars/mars_gods_rebuke_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mars_gods_rebuke_custom_stacks", "heroes/hero_mars/mars_gods_rebuke_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mars_gods_rebuke_custom_debuff", "heroes/hero_mars/mars_gods_rebuke_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
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

mars_gods_rebuke_custom = class(ItemBaseClass)
modifier_mars_gods_rebuke_custom = class(mars_gods_rebuke_custom)
modifier_mars_gods_rebuke_custom_stacks = class(ItemBaseClassBuff)
modifier_mars_gods_rebuke_custom_debuff = class(ItemBaseClassDebuff)
-------------
function mars_gods_rebuke_custom:GetIntrinsicModifierName()
    return "modifier_mars_gods_rebuke_custom"
end

function mars_gods_rebuke_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- load data
    local radius = self:GetSpecialValueFor("radius")
    local angle = self:GetSpecialValueFor("angle")/2
    local duration = self:GetSpecialValueFor("knockback_duration")
    local distance = self:GetSpecialValueFor("knockback_distance")

    -- find units
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(), -- int, your team number
        caster:GetOrigin(), -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    -- precache
    local origin = caster:GetOrigin()
    local cast_direction = (point-origin):Normalized()
    local cast_angle = VectorToAngles( cast_direction ).y

    local rebukeDamage = caster:FindModifierByName("modifier_mars_gods_rebuke_custom_stacks")
    local totalDamage = 0
    if rebukeDamage then
        totalDamage = rebukeDamage:GetStackCount()
        caster:RemoveModifierByName("modifier_mars_gods_rebuke_custom_stacks")
    end

    local crit = self:GetSpecialValueFor("crit_mult")
    if caster:HasTalent("special_bonus_unique_mars_2_custom") then
        crit = crit + caster:FindAbilityByName("special_bonus_unique_mars_2_custom"):GetSpecialValueFor("value")
    end

    totalDamage = totalDamage * (crit/100)

    -- for each units
    local caught = false
    for _,enemy in pairs(enemies) do
        -- check within cast angle
        local enemy_direction = (enemy:GetOrigin() - origin):Normalized()
        local enemy_angle = VectorToAngles( enemy_direction ).y
        local angle_diff = math.abs( AngleDiff( cast_angle, enemy_angle ) )
        if angle_diff<=angle then
            if IsBossTCOTRPG(enemy) then
                totalDamage = totalDamage * (1+(self:GetSpecialValueFor("bonus_damage_vs_bosses")/100))
            end

            -- attack
            ApplyDamage({
                attacker = caster,
                victim = enemy,
                damage = totalDamage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
                ability = self
            })

            SendOverheadEventMessage(
                nil,
                OVERHEAD_ALERT_CRITICAL,
                enemy,
                totalDamage,
                nil
            )

            enemy:AddNewModifier(caster, self, "modifier_mars_gods_rebuke_custom_debuff", {
                duration = self:GetSpecialValueFor("knockback_slow_duration")
            })

            enemy:AddNewModifier(
                caster, -- player source
                self, -- ability source
                "modifier_generic_knockback_lua", -- modifier name
                {
                    duration = duration,
                    distance = distance,
                    height = 30,
                    direction_x = enemy_direction.x,
                    direction_y = enemy_direction.y,
                } -- kv
            )

            caught = true
            -- play effects
            self:PlayEffects2( enemy, origin, cast_direction )
        end
    end

    -- play effects
    self:PlayEffects1( caught, (point-origin):Normalized() )
end

function mars_gods_rebuke_custom:PlayEffects1( caught, direction )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_mars/mars_shield_bash.vpcf"
    local sound_cast = "Hero_Mars.Shield.Cast"
    if not caught then
        local sound_cast = "Hero_Mars.Shield.Cast.Small"
    end

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end

function mars_gods_rebuke_custom:PlayEffects2( target, origin, direction )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_mars/mars_shield_bash_crit.vpcf"
    local sound_cast = "Hero_Mars.Shield.Crit"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, target:GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 1, direction )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
-------------
function modifier_mars_gods_rebuke_custom:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_mars_gods_rebuke_custom:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if parent:HasModifier("modifier_mars_gods_rebuke_custom_stacks") and not ability:IsActivated() then
        ability:SetActivated(true)
    end

    if not parent:HasModifier("modifier_mars_gods_rebuke_custom_stacks") and ability:IsActivated() then
        ability:SetActivated(false)
    end
end

function modifier_mars_gods_rebuke_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }
end

function modifier_mars_gods_rebuke_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.inflictor then return end
    if event.unit ~= parent or event.attacker == parent then return end
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
    if event.damage <= 0 then return end
    if not parent:HasModifier("modifier_mars_bulwark_custom_toggle") then return end

    local ability = self:GetAbility()
    local absorb = event.damage * (ability:GetSpecialValueFor("absorb_pct") / 100)

    if absorb < 1 then
        absorb = 1
    end

    local stacks = parent:FindModifierByName("modifier_mars_gods_rebuke_custom_stacks")
    if stacks == nil then
        stacks = parent:AddNewModifier(parent, ability, "modifier_mars_gods_rebuke_custom_stacks", {
            duration = ability:GetSpecialValueFor("absorb_duration")
        })
    end

    local limit = parent:GetMaxHealth() * (ability:GetSpecialValueFor("absorb_limit_from_max_hp_pct")/100)

    if stacks then
        if stacks:GetStackCount() < limit then
            stacks:SetStackCount(stacks:GetStackCount() + absorb)
        end

        if stacks:GetStackCount() >= limit then
            if ability:IsCooldownReady() and ability:GetManaCost(-1) <= parent:GetMana() and not parent:IsSilenced() and not parent:IsStunned() and not parent:IsHexed() and parent:HasModifier("modifier_mars_bulwark_custom_toggle") then
                SpellCaster:Cast(ability, parent, true)
                return
            end
        end
        
        stacks:ForceRefresh()
    end
end
----------
function modifier_mars_gods_rebuke_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_mars_gods_rebuke_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("knockback_slow")
end