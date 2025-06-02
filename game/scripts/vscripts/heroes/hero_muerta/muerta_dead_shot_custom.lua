LinkLuaModifier("modifier_muerta_dead_shot_custom", "heroes/hero_muerta/muerta_dead_shot_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muerta_dead_shot_custom_impact_debuff", "heroes/hero_muerta/muerta_dead_shot_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muerta_dead_shot_custom_res_debuff", "heroes/hero_muerta/muerta_dead_shot_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muerta_dead_shot_custom_channeling", "heroes/hero_muerta/muerta_dead_shot_custom", LUA_MODIFIER_MOTION_NONE)

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

muerta_dead_shot_custom = class(ItemBaseClass)
modifier_muerta_dead_shot_custom = class(muerta_dead_shot_custom)
modifier_muerta_dead_shot_custom_impact_debuff = class(ItemBaseClassDebuff)
modifier_muerta_dead_shot_custom_res_debuff = class(ItemBaseClassDebuff)
modifier_muerta_dead_shot_custom_channeling = class(ItemBaseClassBuff)
-------------
function muerta_dead_shot_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local target = self:GetCursorTarget()

    local talent = caster:FindAbilityByName("talent_muerta_1")
    if talent == nil or (talent ~= nil and talent:GetLevel() < 1) then
        self:FireShot(DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, target)

        if caster:HasScepter() then
            caster:StartGesture(ACT_DOTA_CAST_ABILITY_3)

            self:FireShot(DOTA_PROJECTILE_ATTACHMENT_ATTACK_2, target)
        end
    end

    if talent ~= nil and talent:GetLevel() > 0 then
        caster:AddNewModifier(caster, self, "modifier_muerta_dead_shot_custom_channeling", {
            duration = talent:GetSpecialValueFor("duration"),
            x = self:GetCursorPosition().x,
            y = self:GetCursorPosition().y,
            z = self:GetCursorPosition().z,
        })
    end
end

function muerta_dead_shot_custom:GetChannelTime()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_muerta_1")
    if talent ~= nil and talent:GetLevel() > 0 then
        return talent:GetSpecialValueFor("duration")
    end
end

function muerta_dead_shot_custom:GetBehavior()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_muerta_1")
    if talent ~= nil and talent:GetLevel() > 0 then
        return DOTA_ABILITY_BEHAVIOR_POINT  
    end
end

function muerta_dead_shot_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_muerta_dead_shot_custom_channeling")
end

function muerta_dead_shot_custom:OnProjectileHit_ExtraData(target, location, extraData)
    if not target then return end 

    local caster = self:GetCaster()
    local ability = self

    local damage = ability:GetSpecialValueFor("damage") + (caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("damage_from_attack")/100))
    local slowDuration = ability:GetSpecialValueFor("impact_duration")
    local ricochetDamage = ability:GetSpecialValueFor("ricochet_damage") + (caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("damage_from_attack")/100))
    local ricochetFearDuration = ability:GetSpecialValueFor("ricochet_magic_res_duration")

    -- Primary shot --
    if extraData.primary == 1 then
        local radius = ability:GetSpecialValueFor("ricochet_radius")
        local victims = FindUnitsInRadius(caster:GetTeam(), location, nil,
                radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

        if #victims == 1 and target:IsAlive() and not caster:HasModifier("modifier_muerta_dead_shot_custom_channeling") then
            EmitSoundOn("Hero_Muerta.DeadShot.Ricochet", target)
            self:FireSecondaryShot(location, Vector(extraData.casterFvX, extraData.casterFvY, extraData.casterFvZ), true, target)
        elseif #victims > 1 and not caster:HasModifier("modifier_muerta_dead_shot_custom_channeling") then
            for _,victim in ipairs(victims) do
                if victim:IsAlive() and victim ~= target then
                    self:FireSecondaryShot(location, victim:GetAbsOrigin(), false, victim)

                    break
                end
            end
        end

        ApplyDamage({
            attacker = caster,
            victim = target,
            damage = damage,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = ability,
        })

        if caster:HasModifier("modifier_muerta_dead_shot_custom_channeling") then
            caster:PerformAttack(
                target,
                true,
                true,
                true,
                false,
                false,
                false,
                false
            )
        end

        EmitSoundOn("Hero_Muerta.DeadShot.Damage", target)

        target:AddNewModifier(caster, ability, "modifier_muerta_dead_shot_custom_impact_debuff", {
            duration = slowDuration
        })

        EmitSoundOn("Hero_Muerta.DeadShot.Slow", target)
    end

    -- Secondary shot --
    if extraData.primary == 0 then
        local hTarget = EntIndexToHScript(extraData.targetindex)
        
        if not hTarget:IsNull() and hTarget:IsAlive() then
            hTarget:AddNewModifier(caster, ability, "modifier_muerta_dead_shot_custom_res_debuff", {
                duration = ricochetFearDuration
            })

            ApplyDamage({
                attacker = caster,
                victim = hTarget,
                damage = damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = ability,
            })
        end
    end
end

function muerta_dead_shot_custom:FireSecondaryShot(origin, point, single, hTarget)
    local caster = self:GetCaster()

    local projectile_direction = (point - origin):Normalized()

    if single == true then
        projectile_direction = point
    end

    local maxDistance = 1500
    local speed = 2000
    local radius = 115

    local proj = {
        vSpawnOrigin = origin,
        vVelocity = projectile_direction * speed,
        fDistance = maxDistance,
        fStartRadius = radius,
        fEndRadius = radius,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_CREEP,DOTA_UNIT_TARGET_BASIC),
        EffectName = "particles/units/heroes/hero_muerta/muerta_deadshot_linear.vpcf",
        Ability = self,
        Source = caster,
        bProvidesVision = true,
        iVisionRadius = radius,
        fVisionDuration = 1,
        iVisionTeamNumber = caster:GetTeamNumber(),
        ExtraData = {
            primary = 0,
            targetindex = hTarget:entindex()
        }
    }

    ProjectileManager:CreateLinearProjectile(proj)
end

function muerta_dead_shot_custom:FireShot(srcAttach, target)
    local caster = self:GetCaster()

    if caster:HasScepter() then
        local effect_castLeft = ParticleManager:CreateParticle("particles/units/heroes/hero_muerta/muerta_gunslinger_left.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(
            effect_castLeft,
            0,
            caster,
            PATTACH_CUSTOMORIGIN_FOLLOW,
            "attach_attack1",
            Vector(0,0,0), -- unknown
            true -- unknown, true
        )

        ParticleManager:ReleaseParticleIndex(effect_castLeft)

        local effect_castRight = ParticleManager:CreateParticle("particles/units/heroes/hero_muerta/muerta_gunslinger_right.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(
            effect_castRight,
            0,
            caster,
            PATTACH_CUSTOMORIGIN_FOLLOW,
            "attach_attack2",
            Vector(0,0,0), -- unknown
            true -- unknown, true
        )

        ParticleManager:ReleaseParticleIndex(effect_castRight)
    end

    local proj = {
        Target = target,
        iMoveSpeed = 2000,
        iSourceAttachment = srcAttach,
        bVisibleToEnemies = true,
        EffectName = "particles/units/heroes/hero_muerta/muerta_deadshot_tracking_proj.vpcf",
        Ability = self,
        Source = caster,
        bProvidesVision = true,
        iVisionRadius = 300,
        iVisionTeamNumber = caster:GetTeam(),
        ExtraData = {
            primary = 1,
            casterFvX = caster:GetForwardVector().x,
            casterFvY = caster:GetForwardVector().y,
            casterFvZ = caster:GetForwardVector().z,
        }
    }

    if caster:HasScepter() then
        Timers:CreateTimer(caster:GetAttackAnimationPoint(), function()
            EmitSoundOn("Hero_Muerta.DeadShot.Cast", caster)

            ProjectileManager:CreateTrackingProjectile(proj)
        end)
    else
        EmitSoundOn("Hero_Muerta.DeadShot.Cast", caster)

        ProjectileManager:CreateTrackingProjectile(proj)
    end
end

function muerta_dead_shot_custom:FireShotNoTarget(srcAttach, cp)
    local caster = self:GetCaster()

    if caster:HasScepter() then
        local effect_castLeft = ParticleManager:CreateParticle("particles/units/heroes/hero_muerta/muerta_gunslinger_left.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(
            effect_castLeft,
            0,
            caster,
            PATTACH_CUSTOMORIGIN_FOLLOW,
            "attach_attack1",
            Vector(0,0,0), -- unknown
            true -- unknown, true
        )

        ParticleManager:ReleaseParticleIndex(effect_castLeft)

        local effect_castRight = ParticleManager:CreateParticle("particles/units/heroes/hero_muerta/muerta_gunslinger_right.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(
            effect_castRight,
            0,
            caster,
            PATTACH_CUSTOMORIGIN_FOLLOW,
            "attach_attack2",
            Vector(0,0,0), -- unknown
            true -- unknown, true
        )

        ParticleManager:ReleaseParticleIndex(effect_castRight)
    end

    --[[
    local proj = {
        Target = target,
        iMoveSpeed = 2000,
        iSourceAttachment = srcAttach,
        bVisibleToEnemies = true,
        EffectName = "particles/units/heroes/hero_muerta/muerta_deadshot_tracking_proj.vpcf",
        Ability = self,
        Source = caster,
        bProvidesVision = true,
        iVisionRadius = 300,
        iVisionTeamNumber = caster:GetTeam(),
        ExtraData = {
            primary = 1,
            casterFvX = caster:GetForwardVector().x,
            casterFvY = caster:GetForwardVector().y,
            casterFvZ = caster:GetForwardVector().z,
        }
    }
    --]]

    
    local projectile_direction = (cp - caster:GetAbsOrigin()):Normalized()
    caster:FaceTowards(projectile_direction)

    local proj = {
        vSpawnOrigin = caster:GetAbsOrigin(),
        vVelocity = projectile_direction * 2000,
        fDistance = self:GetEffectiveCastRange(caster:GetAbsOrigin(), nil),
        fStartRadius = 115,
        fEndRadius = 115,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_CREEP,DOTA_UNIT_TARGET_BASIC),
        EffectName = "particles/units/heroes/hero_muerta/muerta_deadshot_linear.vpcf",
        Ability = self,
        Source = caster,
        bProvidesVision = true,
        iVisionRadius = 300,
        fVisionDuration = 1,
        iVisionTeamNumber = caster:GetTeamNumber(),
        ExtraData = {
            primary = 1,
            casterFvX = caster:GetForwardVector().x,
            casterFvY = caster:GetForwardVector().y,
            casterFvZ = caster:GetForwardVector().z,
        }
    }

    if caster:HasScepter() then
        Timers:CreateTimer(caster:GetAttackAnimationPoint(), function()
            EmitSoundOn("Hero_Muerta.DeadShot.Cast", caster)

            ProjectileManager:CreateLinearProjectile(proj)
        end)
    else
        EmitSoundOn("Hero_Muerta.DeadShot.Cast", caster)

        ProjectileManager:CreateLinearProjectile(proj)
    end
end
---------------------
function modifier_muerta_dead_shot_custom_impact_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_muerta_dead_shot_custom_impact_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("impact_slow_pct")
end
------------
function modifier_muerta_dead_shot_custom_res_debuff:GetEffectName()
    return "particles/units/heroes/hero_muerta/muerta_spell_fear_debuff.vpcf"
end

function modifier_muerta_dead_shot_custom_res_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
    }

    return funcs
end

function modifier_muerta_dead_shot_custom_res_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("ricochet_magic_res")
end
-------------
function modifier_muerta_dead_shot_custom_channeling:OnCreated(params)
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    self.cursorPos = Vector(params.x, params.y, params.z)

    local talent = parent:FindAbilityByName("talent_muerta_1")
    if talent ~= nil and talent:GetLevel() > 0 then
        local interval = talent:GetSpecialValueFor("interval")

        self:OnIntervalThink()
        self:StartIntervalThink(interval)
    else
        self:Destroy()
    end
end

function modifier_muerta_dead_shot_custom_channeling:OnIntervalThink()
    local ability = self:GetAbility()
    local target = self:GetCaster()

    if self:GetParent():HasScepter() then
        StartAnimation(self:GetParent(), {duration=self:GetParent():GetAttackAnimationPoint(), activity=ACT_DOTA_CAST_ABILITY_3})
        --self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_3)
        ability:FireShotNoTarget(DOTA_PROJECTILE_ATTACHMENT_ATTACK_2, self.cursorPos)
    else
        self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_1)
    end

    ability:FireShotNoTarget(DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, self.cursorPos)
end