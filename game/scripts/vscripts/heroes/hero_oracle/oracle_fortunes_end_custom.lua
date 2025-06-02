LinkLuaModifier("modifier_oracle_fortunes_end_custom", "heroes/hero_oracle/oracle_fortunes_end_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_fortunes_end_custom_debuff", "heroes/hero_oracle/oracle_fortunes_end_custom", LUA_MODIFIER_MOTION_NONE)

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

oracle_fortunes_end_custom = class(ItemBaseClass)
modifier_oracle_fortunes_end_custom = class(ItemBaseClassBuff)
modifier_oracle_fortunes_end_custom_debuff = class(ItemBaseClassDebuff)
-------------
function oracle_fortunes_end_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_oracle_fortunes_end_custom", {
        duration = self:GetChannelTime()
    })
end

function oracle_fortunes_end_custom:OnChannelFinish(bInterrupted)
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_oracle_fortunes_end_custom")
end

function oracle_fortunes_end_custom:OnProjectileHit(target, location)
    if not target or target:IsNull() then return end 

    local caster = self:GetCaster()

    -- Find enemies --
    local units = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(), -- int, your team number
        target:GetAbsOrigin(), -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self:GetSpecialValueFor("impact_radius"), -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_BOTH,    -- int, team filter
        bit.bor(DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_BASIC,DOTA_UNIT_TARGET_CREEP),  -- int, type filter
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, -- int, flag filter
        FIND_CLOSEST,   -- int, order filter
        false   -- bool, can grow cache
    )

    local damage = self:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (self:GetSpecialValueFor("int_to_damage")/100))

    for _,unit in ipairs(units) do
        if unit:GetTeamNumber() ~= caster:GetTeamNumber() then
            local damage = {
                victim = unit,
                attacker = caster,
                damage = damage,
                damage_type = self:GetAbilityDamageType(),
                ability = self
            }

            ApplyDamage(damage)

            unit:AddNewModifier(caster, self, "modifier_oracle_fortunes_end_custom_debuff", {
                duration = self:GetSpecialValueFor("slow_duration")
            })

            if caster:HasScepter() then
                local RoD_Debuff = unit:FindModifierByName("modifier_oracle_rain_of_destiny_custom_debuff")
                if RoD_Debuff then
                    RoD_Debuff:AdvanceForward()
                end
            end
        else
            unit:Purge(false, true, false, true, false)

            local healAmount = unit:GetMaxHealth() * (self:GetSpecialValueFor("heal_pct")/100)

            unit:Heal(healAmount, self)

            SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, healAmount, nil)

            if caster:HasScepter() then
                local RoD_Buff = unit:FindModifierByName("modifier_oracle_rain_of_destiny_custom_buff")
                if RoD_Buff then
                    RoD_Buff:AdvanceForward()
                end
            end
        end
    end

    -- effects
    self:PlayEffects1(target)
    self:PlayEffects2(target)
end

function oracle_fortunes_end_custom:PlayEffects1(target)
    local particle_cast = "particles/units/heroes/hero_oracle/oracle_fortune_cast_tgt.vpcf"
    local sound_cast = "Hero_Oracle.FortunesEnd.Target"

    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(effect_cast, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)

    EmitSoundOn(sound_cast, target)
end

function oracle_fortunes_end_custom:PlayEffects2(target)
    local particle_cast = "particles/units/heroes/hero_oracle/oracle_fortune_aoe.vpcf"

    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(effect_cast, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 2, Vector(300, 0, 0))
    ParticleManager:ReleaseParticleIndex(effect_cast)
end
-----------
function modifier_oracle_fortunes_end_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE  
    }
end

function modifier_oracle_fortunes_end_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.inflictor == self:GetAbility() and self:GetParent():HasModifier("modifier_item_aghanims_shard") then
        local secondsActive = self:GetDuration() - self:GetRemainingTime()

        return self:GetAbility():GetSpecialValueFor("damage_increase_per_sec") * secondsActive
    end
end

function modifier_oracle_fortunes_end_custom:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local interval = ability:GetSpecialValueFor("interval")
    local parent = self:GetParent()

    self.width = ability:GetSpecialValueFor("search_width")
    self.maxTargets = ability:GetSpecialValueFor("search_targets")

    self.point = ability:GetCursorPosition()

    EmitSoundOn("Hero_Oracle.FortunesEnd.Channel", parent)

    self.effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_fortune_channel.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.effect_cast, 0, parent, PATTACH_POINT_FOLLOW, "attach_attack1", parent:GetAbsOrigin(), true)

    self:StartIntervalThink(interval)
end

function modifier_oracle_fortunes_end_custom:OnRemoved()
    if not IsServer() then return end 

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    StopSoundOn("Hero_Oracle.FortunesEnd.Channel", self:GetParent())
end

function modifier_oracle_fortunes_end_custom:FireProjectile(target)
    local ability = self:GetAbility()
    local parent = self:GetParent()

    local projectile_name = "particles/units/heroes/hero_oracle/oracle_fortune_prj.vpcf"
    local projectile_speed = 1000

    local info = {
        Source = parent,
        Target = target,
        Ability = ability,
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bDodgeable = true
    }

    ProjectileManager:CreateTrackingProjectile(info)
end

function modifier_oracle_fortunes_end_custom:OnIntervalThink()
    local parent = self:GetParent()
    local origin = parent:GetAbsOrigin()

    local i = 0

    local targets = FindUnitsInLine(
        parent:GetTeamNumber(),   -- int, your team number
        origin, -- point, start point
        self.point, -- point, end point
        nil,    -- handle, cacheUnit. (not known)
        self.width, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_BOTH,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE  -- int, flag filter
    )

    if #targets > 1 then
        EmitSoundOn("Hero_Oracle.FortunesEnd.Attack", parent)
    end

    for _,target in ipairs(targets) do 
        if target:IsAlive() and not target:IsInvulnerable() and not target:IsMagicImmune() and target ~= parent and i < self.maxTargets then
            self:FireProjectile(target)

            i = i + 1
        end
    end
end
--------------
function modifier_oracle_fortunes_end_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_oracle_fortunes_end_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end