LinkLuaModifier("modifier_oracle_false_promise_custom", "heroes/hero_oracle/oracle_false_promise_custom", LUA_MODIFIER_MOTION_NONE)

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

oracle_false_promise_custom = class(ItemBaseClass)
modifier_oracle_false_promise_custom = class(ItemBaseClassBuff)
-------------
function oracle_false_promise_custom:OnSpellStart()
    if not IsServer() then return end

    self.target = self:GetCursorTarget()

    local caster = self:GetCaster()
end

function oracle_false_promise_custom:OnChannelFinish(bInterrupted)
    if not IsServer() then return end

    local caster = self:GetCaster()

    StopSoundOn("Hero_Oracle.FalsePromise.Target", caster)

    if bInterrupted then return end 

    if not self.target or self.target:IsNull() or not self.target:IsAlive() then return end 

    local health = self.target:GetHealth()

    self.target:AddNewModifier(caster, self, "modifier_oracle_false_promise_custom", {
        duration = self:GetSpecialValueFor("duration"),
        originalHealth = health
    })

    EmitSoundOn("Hero_Oracle.FalsePromise.Cast", self.target)
end
----------------------------
function modifier_oracle_false_promise_custom:GetEffectName()
    return "particles/units/heroes/hero_oracle/oracle_false_promise_indicator.vpcf"
end

function modifier_oracle_false_promise_custom:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_oracle_false_promise_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MIN_HEALTH,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_oracle_false_promise_custom:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.target then return end 

    local attacker = event.attacker 

    if attacker:HasModifier("modifier_oracle_false_promise_custom") then return end

    if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end 

    if not parent:HasModifier("modifier_item_aghanims_shard") then return end

    local preCastVfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_attacked.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(preCastVfx, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(preCastVfx)

    local ability = self:GetAbility()
    local reflect = ability:GetSpecialValueFor("reflect_damage")

    local damage = event.damage * (reflect/100)

    self.storedDamage = self.storedDamage + damage

    ApplyDamage({
        attacker = parent,
        victim = attacker,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })
end

function modifier_oracle_false_promise_custom:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("health_regen_pct")
end

function modifier_oracle_false_promise_custom:GetMinHealth()
    return 1
end

function modifier_oracle_false_promise_custom:OnCreated(params)
    if not IsServer() then return end 

    local parent = self:GetParent()

    self.health = params.originalHealth

    self.storedDamage = 0

    local preCastVfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(preCastVfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(preCastVfx, 2, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(preCastVfx)

    EmitSoundOn("Hero_Oracle.FalsePromise.Target", parent)

    self.effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.effect_cast, 0, parent:GetAbsOrigin())

    EmitSoundOn("Hero_Oracle.FalsePromise.FP", parent)
end

function modifier_oracle_false_promise_custom:OnRemoved()
    if not IsServer() then return end 

    local parent = self:GetParent()

    StopSoundOn("Hero_Oracle.FalsePromise.FP", parent)

    ParticleManager:DestroyParticle(self.effect_cast, false)
    ParticleManager:ReleaseParticleIndex(self.effect_cast)

    if not self.health or self.health < 0 or not parent:IsAlive() then return end

    parent:SetHealth(self.health)

    EmitSoundOn("Hero_Oracle.FalsePromise.Healed", parent)

    local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_break_heal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(vfx, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfx)

    if parent:HasModifier("modifier_item_aghanims_shard") and self.storedDamage > 0 then
        local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(vfx, 0, parent:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(vfx)

        local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            self:GetAbility():GetSpecialValueFor("damage_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,enemy in ipairs(victims) do
            if not enemy:IsAlive() then break end

            ApplyDamage({
                attacker = parent,
                victim = enemy,
                damage = self.storedDamage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self:GetAbility()
            })
        end

        EmitSoundOn("Hero_Oracle.FalsePromise.Damaged", parent)
    end

    self.storedDamage = 0
end