LinkLuaModifier("modifier_faceless_void_time_lock_custom", "faceless_void_time_lock_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_faceless_void_time_lock_custom_debuff", "faceless_void_time_lock_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_faceless_void_time_lock_custom_talent_buff", "faceless_void_time_lock_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

faceless_void_time_lock_custom = class(ItemBaseClass)
modifier_faceless_void_time_lock_custom = class(faceless_void_time_lock_custom)
modifier_faceless_void_time_lock_custom_debuff = class(ItemBaseClassDebuff)
modifier_faceless_void_time_lock_custom_talent_buff = class(ItemBaseClassBuff)
-------------
function faceless_void_time_lock_custom:GetIntrinsicModifierName()
    return "modifier_faceless_void_time_lock_custom"
end

function modifier_faceless_void_time_lock_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_faceless_void_time_lock_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_faceless_void_time_lock_custom:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local victim = event.target

    local talent = caster:FindAbilityByName("talent_faceless_void_1")
    if talent ~= nil and talent:GetLevel() > 1 then
        if unit:GetTeam()~=caster:GetTeam() then
            return
        else
            if not unit:HasModifier("modifier_faceless_void_chronosphere_custom_debuff") then
                return
            end
        end
    elseif talent == nil or (talent ~= nil and talent:GetLevel() < 2) then
        if unit ~= parent then
            return
        end
    end

    if unit:IsIllusion() then return end

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL or event.inflictor ~= nil or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if unit:IsIllusion() then return end
    
    local chance = ability:GetLevelSpecialValueFor("chance", (ability:GetLevel() - 1))

    if unit:HasScepter() and victim:HasModifier("modifier_faceless_void_chronosphere_custom_debuff") then
        chance = ability:GetSpecialValueFor("scepter_chance_pct")
    end

    if not RollPercentage(chance) then
        return
    end

    local stackDuration = ability:GetLevelSpecialValueFor("stack_duration", (ability:GetLevel() - 1))
    local maxStacks = ability:GetLevelSpecialValueFor("max_stacks", (ability:GetLevel() - 1))
    local increasePerStack = ability:GetLevelSpecialValueFor("increase_per_stack", (ability:GetLevel() - 1))
    local radius = ability:GetSpecialValueFor("radius")
    local damageTaken = event.damage * (ability:GetSpecialValueFor("damage_dealt_pct")/100)

    local victims = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for i = 1, #victims, 1 do
        local enemy = victims[i]
        if not enemy:IsAlive() then break end

        Timers:CreateTimer(((0.5/#victims) * i), function()
            local modifierName = "modifier_faceless_void_time_lock_custom_debuff"
            local enemyStacks = enemy:FindModifierByNameAndCaster(modifierName, caster)

            if enemy:IsAlive() then
                local talent = caster:FindAbilityByName("talent_faceless_void_2")
                if talent ~= nil and talent:GetLevel() > 2 then
                    local talentBuffStack = caster:FindModifierByName("modifier_faceless_void_time_lock_custom_talent_buff")
                    if not talentBuffStack then
                        talentBuffStack = caster:AddNewModifier(caster, talent, "modifier_faceless_void_time_lock_custom_talent_buff", {
                            duration = talent:GetSpecialValueFor("stack_duration")
                        })
                    end

                    if talentBuffStack then
                        if talentBuffStack:GetStackCount() < talent:GetSpecialValueFor("max_stacks") then
                            talentBuffStack:IncrementStackCount()
                        end

                        talentBuffStack:ForceRefresh()
                    end
                end

                if enemyStacks == nil then
                    enemy:AddNewModifier(caster, ability, "modifier_faceless_void_time_lock_custom_debuff", { duration = stackDuration }):SetStackCount(1)
                end

                if enemyStacks then
                    if enemyStacks:GetStackCount() < maxStacks then
                        enemyStacks:SetStackCount(enemyStacks:GetStackCount() + 1)
                    else
                        local caster = self:GetCaster()
                        local runeTimeLock = caster:FindModifierByName("modifier_item_socket_rune_legendary_faceless_void_time_lock")
                        if runeTimeLock and runeTimeLock.cooldownReady then
                            enemyStacks:Destroy()

                            local chronosphere = caster:FindAbilityByName("faceless_void_chronosphere_custom")
                            if chronosphere ~= nil and chronosphere:GetLevel() > 0 then
                                local chronosphereMod = caster:FindModifierByName("modifier_faceless_void_chronosphere_custom")
                                if chronosphereMod ~= nil then
                                    local _chronosphere = chronosphereMod:GetAbility()

                                    local talentRadius = runeTimeLock.chronosphereRadius
                                    local talentDuration = runeTimeLock.chronosphereDuration
                                    local talentCd = runeTimeLock.chronosphereCooldown
                                    _chronosphere:CreateChronosphere(talentRadius, enemy:GetAbsOrigin(), talentDuration)
                                    runeTimeLock.cooldownReady = false
                                    Timers:CreateTimer(talentCd, function()
                                        runeTimeLock.cooldownReady = true
                                    end)
                                end
                            end
                        end
                    end

                    enemyStacks:ForceRefresh()
                end

                if enemyStacks ~= nil and enemyStacks:GetStackCount() > 0 then
                    damageTaken = (damageTaken * (1 + ((increasePerStack * enemyStacks:GetStackCount()) / 100)))
                end

                ApplyDamage({
                    victim = enemy, 
                    attacker = caster, 
                    damage = damageTaken, 
                    damage_type = DAMAGE_TYPE_PHYSICAL,
                    ability = ability
                })

                self:PlayEffects(enemy)
            end
        end)
    end
end

function modifier_faceless_void_time_lock_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_faceless_void/faceless_void_time_lock_bash.vpcf"
    local sound_cast = "Hero_FacelessVoid.TimeLockImpact"

    -- Get Data
    local forward = (target:GetOrigin()-self.parent:GetOrigin()):Normalized()

    -- Create Particle
    local particle = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, target )
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin() )
    ParticleManager:SetParticleControlEnt(particle, 2, self.parent, PATTACH_CUSTOMORIGIN, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
-----
function modifier_faceless_void_time_lock_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end

function modifier_faceless_void_time_lock_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("stack_slow")
end

function modifier_faceless_void_time_lock_custom_debuff:GetModifierPhysicalArmorBonus()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_faceless_void_2")
    if talent ~= nil and talent:GetLevel() > 1 then
        return self:GetParent():GetPhysicalArmorBaseValue() * ((talent:GetSpecialValueFor("time_lock_armor_reduction_pct")*self:GetStackCount())/100)
    end
end
-------------------
function modifier_faceless_void_time_lock_custom_talent_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_faceless_void_time_lock_custom_talent_buff:GetModifierDamageOutgoing_Percentage()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_faceless_void_2")
    if talent ~= nil and talent:GetLevel() > 2 then
        return talent:GetSpecialValueFor("bonus_damage_pct") * self:GetStackCount()
    end
end

function modifier_faceless_void_time_lock_custom_talent_buff:GetModifierMoveSpeedBonus_Percentage()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_faceless_void_2")
    if talent ~= nil and talent:GetLevel() > 2 then
        return talent:GetSpecialValueFor("bonus_move_speed_pct") * self:GetStackCount()
    end
end