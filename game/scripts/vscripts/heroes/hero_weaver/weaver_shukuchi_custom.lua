LinkLuaModifier("modifier_weaver_shukuchi_custom", "heroes/hero_weaver/weaver_shukuchi_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weaver_shukuchi_custom_aura", "heroes/hero_weaver/weaver_shukuchi_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weaver_shukuchi_custom_illusion", "heroes/hero_weaver/weaver_shukuchi_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weaver_shukuchi_custom_scepter_debuff", "heroes/hero_weaver/weaver_shukuchi_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_max_movement_speed", "modifiers/modifier_max_movement_speed", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

weaver_shukuchi_custom = class(ItemBaseClass)
modifier_weaver_shukuchi_custom = class(ItemBaseClassBuff)
modifier_weaver_shukuchi_custom_illusion = class(ItemBaseClassBuff)
modifier_weaver_shukuchi_custom_aura = class(ItemBaseClassAura)
modifier_weaver_shukuchi_custom_scepter_debuff = class(ItemBaseClassDebuff)
-------------
function weaver_shukuchi_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    caster:AddNewModifier(
        caster,
        self,
        "modifier_weaver_shukuchi_custom",
        {
            duration = self:GetSpecialValueFor("duration")
        }
    )

    EmitSoundOn("Hero_Weaver.Shukuchi", caster)

    -- So this is crashing somehow
    -- Maybe it interfers with geminate attack?
    local illusions = CreateIllusions(caster, caster, {
        outgoing_damage = self:GetSpecialValueFor("illusion_damage_outgoing"),
        incoming_damage = self:GetSpecialValueFor("illusion_damage_incoming"),
        outgoing_damage_roshan = self:GetSpecialValueFor("illusion_damage_outgoing"),
        outgoing_damage_structure = self:GetSpecialValueFor("illusion_damage_outgoing")
    }, 1, 0, false, true)

    local illusion = illusions[1]
    if illusion ~= nil then
        illusion:AddNewModifier(caster, nil, "modifier_max_movement_speed", {})
        illusion:SetBaseMoveSpeed(caster:GetIdealSpeedNoSlows())
        illusion:AddNewModifier(caster, self, "modifier_weaver_shukuchi_custom_illusion", {
            duration = self:GetSpecialValueFor("duration")
        })

        -- Tome stuff because this isn't added normally --
        local tome_Agility = caster:FindModifierByName("tome_consumed_agi")
        local tome_Strength = caster:FindModifierByName("tome_consumed_str")
        local tome_Intellect = caster:FindModifierByName("tome_consumed_int")

        if tome_Agility ~= nil then
            local _t = illusion:AddNewModifier(illusion, tome_Agility:GetAbility(), tome_Agility:GetName(), {})
            if _t ~= nil then
                _t:SetStackCount(tome_Agility:GetStackCount())
            end
        end

        if tome_Strength ~= nil then
            local _t = illusion:AddNewModifier(illusion, tome_Strength:GetAbility(), tome_Strength:GetName(), {})
            if _t ~= nil then
                _t:SetStackCount(tome_Strength:GetStackCount())
            end
        end

        if tome_Intellect ~= nil then
            local _t = illusion:AddNewModifier(illusion, tome_Intellect:GetAbility(), tome_Intellect:GetName(), {})
            if _t ~= nil then
                _t:SetStackCount(tome_Intellect:GetStackCount())
            end
        end
    end
end
---------------
function modifier_weaver_shukuchi_custom:OnCreated()
    local ability = self:GetAbility()

    ability.targets = {}

    if not IsServer() then return end 

    local particlePath = "particles/units/heroes/hero_weaver/weaver_shukuchi.vpcf"

    local parent = self:GetParent()

    self.effect = ParticleManager:CreateParticle(particlePath, PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(
        self.effect,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
end

function modifier_weaver_shukuchi_custom:OnRemoved()
    if not IsServer() then return end 

    local parent = self:GetParent()

    if self.effect ~= nil then
        ParticleManager:DestroyParticle(self.effect, true)
        ParticleManager:ReleaseParticleIndex(self.effect)
    end

    local illusions = FindUnitsInRadius(
        parent:GetTeamNumber(),    -- int, your team number
        parent:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        FIND_UNITS_EVERYWHERE,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,illusion in ipairs(illusions) do
        if illusion:HasModifier("modifier_weaver_shukuchi_custom_illusion") then
            illusion:ForceKill(false)
        end
    end
end

function modifier_weaver_shukuchi_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT  
    }

    return funcs
end

function modifier_weaver_shukuchi_custom:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("speed")
end

function modifier_weaver_shukuchi_custom:CheckState()
    local state = {
        [MODIFIER_STATE_INVISIBLE] = self:GetModifierInvisibilityLevel() == 1.0
    }

    return state
end

function modifier_weaver_shukuchi_custom:GetModifierInvisibilityLevel(params)
    return math.min(1, self:GetElapsedTime() / self:GetAbility():GetSpecialValueFor("fade_time"))
end

function modifier_weaver_shukuchi_custom:OnAbilityExecuted(event)
    if event.unit == self:GetParent() then
        if not string.match(event.ability:GetAbilityName(), "item_gold_bag") then
            self:Destroy()
        end
    end
end

function modifier_weaver_shukuchi_custom:OnAttack(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local parent = self:GetParent()

    if attacker ~= parent then
        return
    end

    if not attacker:IsAlive() then
        return
    end

    self:Destroy()
end

function modifier_weaver_shukuchi_custom:IsAura()
    return true
end

function modifier_weaver_shukuchi_custom:GetAuraSearchType()
    return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_weaver_shukuchi_custom:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_weaver_shukuchi_custom:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_weaver_shukuchi_custom:GetModifierAura()
    return "modifier_weaver_shukuchi_custom_aura"
end

function modifier_weaver_shukuchi_custom:GetAuraEntityReject(target)
    local ability = self:GetAbility()

    -- Can only damage once
    if ability.targets[target:entindex()] then
        return true
    end

    return false
end
----------------
function modifier_weaver_shukuchi_custom_aura:OnCreated()
    local ability = self:GetAbility()

    local caster = self:GetCaster()
    local parent = self:GetParent()

    local entindex = parent:entindex()

    ability.targets[entindex] = ability.targets[entindex] or nil 
    ability.targets[entindex] = true

    if not IsServer() then return end 

    local damage = ability:GetSpecialValueFor("damage") + (caster:GetAgility() * (ability:GetSpecialValueFor("agi_to_damage")/100))

    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = damage,
        damage_type = ability:GetAbilityDamageType()
    })

    if caster:HasScepter() then
        parent:AddNewModifier(caster, ability, "modifier_weaver_shukuchi_custom_scepter_debuff", {
            duration = ability:GetSpecialValueFor("scepter_duration")
        })
    end

    local particlePath = "particles/units/heroes/hero_weaver/weaver_shukuchi_damage.vpcf"

    self.effect = ParticleManager:CreateParticle(particlePath, PATTACH_ABSORIGIN, parent)
    ParticleManager:SetParticleControl( self.effect, 1, caster:GetOrigin() )
    ParticleManager:ReleaseParticleIndex(self.effect)
end
---------
function modifier_weaver_shukuchi_custom_illusion:OnCreated()
    if not IsServer() then return end 

    self.target = nil

    self:StartIntervalThink(FrameTime())
end

-- I fucking copied this from waves, gimme a break
function modifier_weaver_shukuchi_custom_illusion:OnIntervalThink()
    local parent = self:GetParent()

    -- Disable the AI entirely if the unit is channeling an ability
    if parent:IsChanneling() then return end

    -- Targeting logic --
    if self.target ~= nil and not self.target:IsNull() then
        -- The target must be alive, not be attack immune
        if self.target:IsAlive() and not self.target:IsInvulnerable() and not self.target:IsUntargetableFrom(parent) then
            parent:SetForceAttackTarget(self.target)
        else
            parent:SetForceAttackTarget(nil)
            self.target = nil
        end
    end

    -- We will continue to search for units even if there is a target already 
    -- to see if there's another target that is closer
    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            parent:Script_GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and victim ~= self.target and not victim:HasModifier("modifier_wave_manager_fow_revealer") and not victim:HasModifier("modifier_chicken_ability_1_self_transmute") then
            if self.target ~= nil then
                local victimDistance = parent:GetRangeToUnit(victim)
                local currentTargetDistance = parent:GetRangeToUnit(self.target)

                -- If there is a unit that is closer to the unit than the current target,
                -- we change the target to be that unit instead
                if victimDistance < currentTargetDistance then
                    self.target = victim 
                    break
                end
            else
                self.target = victim 
                break
            end
        end
    end
end

function modifier_weaver_shukuchi_custom_illusion:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }

    return state
end

function modifier_weaver_shukuchi_custom_illusion:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_weaver_shukuchi_custom_illusion:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_weaver_shukuchi_custom_illusion:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_weaver_shukuchi_custom_illusion:StatusEffectPriority()
    return 10001
end

function modifier_weaver_shukuchi_custom_illusion:OnDestroy()
    if not IsServer() then return end

    if not self:GetParent():IsNull() then
        --UTIL_RemoveImmediate(self:GetParent()) // Removing will crash the game since we can't remove an entity with active projectiles
        self:GetParent():ForceKill(false)
    end
end
---------------
function modifier_weaver_shukuchi_custom_scepter_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_weaver_shukuchi_custom_scepter_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("scepter_slow")
end

function modifier_weaver_shukuchi_custom_scepter_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("scepter_incoming_damage")
end