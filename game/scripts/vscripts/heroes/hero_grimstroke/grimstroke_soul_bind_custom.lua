LinkLuaModifier("modifier_grimstroke_soul_bind_custom", "heroes/hero_grimstroke/grimstroke_soul_bind_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_soul_bind_custom_self_buff", "heroes/hero_grimstroke/grimstroke_soul_bind_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_soul_bind_custom_debuff", "heroes/hero_grimstroke/grimstroke_soul_bind_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_soul_bind_custom_debuff_mana_transfer", "heroes/hero_grimstroke/grimstroke_soul_bind_custom", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

grimstroke_soul_bind_custom = class(ItemBaseClass)
modifier_grimstroke_soul_bind_custom = class(grimstroke_soul_bind_custom)
modifier_grimstroke_soul_bind_custom_self_buff = class(ItemBaseClassBuff)
modifier_grimstroke_soul_bind_custom_debuff = class(ItemBaseClassDebuff)
modifier_grimstroke_soul_bind_custom_debuff_mana_transfer = class(ItemBaseClassDebuff)

_G.GrimstrokeSoulbindChains = {}
-------------
function grimstroke_soul_bind_custom:GetIntrinsicModifierName()
    return "modifier_grimstroke_soul_bind_custom"
end

function grimstroke_soul_bind_custom:GetAOERadius()
    return self:GetSpecialValueFor("chain_latch_radius")
end

function grimstroke_soul_bind_custom:OnSpellStart()
    if not IsServer() then return end
--
    local parent = self:GetCaster()
    local ability = self
    local duration = ability:GetSpecialValueFor("duration")
    
    if parent:HasModifier("modifier_grimstroke_soul_bind_custom_self_buff") then
        parent:RemoveModifierByName("modifier_grimstroke_soul_bind_custom_self_buff")
    end

    parent:AddNewModifier(parent, ability, "modifier_grimstroke_soul_bind_custom_self_buff", { duration = duration })

    local iParticleCastID = ParticleManager:CreateParticle("particles/units/heroes/hero_grimstroke/grimstroke_cast_soulchain.vpcf", PATTACH_ABSORIGIN, parent)
    ParticleManager:ReleaseParticleIndex(iParticleCastID)

    EmitSoundOn("Hero_Grimstroke.SoulChain.Cast", parent)
end
---------
function modifier_grimstroke_soul_bind_custom_self_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_grimstroke_soul_bind_custom_self_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE 
    }
end

function modifier_grimstroke_soul_bind_custom_self_buff:GetModifierTotalPercentageManaRegen()
    return -self:GetAbility():GetSpecialValueFor("mana_transfer_pct")
end

function modifier_grimstroke_soul_bind_custom_self_buff:OnCreated()
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.radius = self.ability:GetSpecialValueFor("chain_latch_radius")
    self.duration = self.ability:GetSpecialValueFor("chain_duration")

    self.effect = ParticleManager:CreateParticle( "particles/units/heroes/hero_grimstroke/grimstroke_soulchain_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        0,
        self.caster,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        self.caster:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        1,
        self.caster,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        self.caster:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        2,
        self.caster,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        self.caster:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    _G.GrimstrokeSoulbindChains[self.caster:entindex()] = _G.GrimstrokeSoulbindChains[self.caster:entindex()] or nil
    _G.GrimstrokeSoulbindChains[self.caster:entindex()] = nil

    self:StartIntervalThink(0.1)
end

function modifier_grimstroke_soul_bind_custom_self_buff:OnRemoved()
    if not IsServer() then return end

    if self.effect ~= nil then
        ParticleManager:DestroyParticle(self.effect, false)
        ParticleManager:ReleaseParticleIndex(self.effect)
    end

    if self:GetParent():IsIllusion() then
        self:GetParent():ForceKill(false)
    end
end

function modifier_grimstroke_soul_bind_custom_self_buff:OnIntervalThink()
    local victims = FindUnitsInRadius(self.caster:GetTeam(), self.caster:GetAbsOrigin(), nil,
            self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and not victim:IsInvulnerable() and not victim:IsMagicImmune() then
            local shouldApply = false

            local existingDebuff = victim:FindModifierByName("modifier_grimstroke_soul_bind_custom_debuff")
            if existingDebuff ~= nil then
                local existingDebuffCaster = existingDebuff:GetCaster()
                -- If the other caster is different then we apply it again
                if existingDebuffCaster ~= self.caster then
                    shouldApply = true
                end
            else
                shouldApply = true
            end

            if shouldApply and _G.GrimstrokeSoulbindChains[self.caster:entindex()] ~= victim:entindex() then
                victim:AddNewModifier(self.caster, self.ability, "modifier_grimstroke_soul_bind_custom_debuff", {
                    duration = self.duration
                })

                _G.GrimstrokeSoulbindChains[self.caster:entindex()] = victim:entindex()
            end
        end
    end
end
-----------
function modifier_grimstroke_soul_bind_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_grimstroke_soul_bind_custom_debuff:OnCreated()
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.radius = self.ability:GetSpecialValueFor("chain_latch_radius")
    self.duration = self.ability:GetSpecialValueFor("chain_duration")
    self.breakDistance = self.ability:GetSpecialValueFor("chain_break_distance")

    self.casterMod = self.caster:FindModifierByName("modifier_grimstroke_soul_bind_custom_self_buff")
    if self.casterMod ~= nil then
        self.casterMod:IncrementStackCount()
    end

    self.parent:AddNewModifier(self.caster, self.ability, "modifier_grimstroke_soul_bind_custom_debuff_mana_transfer", {
        duration = self.duration
    })

    --EmitSoundOn("Hero_Grimstroke.SoulChain.Target", self.parent)
    --EmitSoundOn("Hero_Grimstroke.SoulChain.Partner", self.caster)

    self.effect = ParticleManager:CreateParticle( "particles/units/heroes/hero_grimstroke/grimstroke_soulchain_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        0,
        self.parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        self.parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        1,
        self.parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        self.parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        2,
        self.parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        self.parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    --------
    self.effectSkull = ParticleManager:CreateParticle( "particles/units/heroes/hero_grimstroke/grimstroke_soulchain_marker.vpcf", PATTACH_OVERHEAD_FOLLOW, self.parent )
    ParticleManager:SetParticleControlEnt(
        self.effectSkull,
        0,
        self.parent,
        PATTACH_OVERHEAD_FOLLOW,
        "attach_hitloc",
        self.parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ---------
    self.effectChain = ParticleManager:CreateParticle( "particles/units/heroes/hero_grimstroke/grimstroke_soulchain.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControlEnt(
        self.effectChain,
        0,
        self.caster,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        self.caster:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.effectChain,
        1,
        self.parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        self.parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    self:AddParticle(self.effectChain, false, false, -1, false, true)

    EmitSoundOn("Hero_Grimstroke.SoulChain.Leash", self.parent)

    self:StartIntervalThink(0.1)
end

function modifier_grimstroke_soul_bind_custom_debuff:OnIntervalThink()
    self.casterMod = self.caster:FindModifierByName("modifier_grimstroke_soul_bind_custom_self_buff")
    if self.casterMod ~= nil then
        if self.casterMod:GetStackCount() <= 0 then self:Destroy() return end
    else
        self:Destroy()
    end

    if (self.caster:GetAbsOrigin() - self.parent:GetAbsOrigin()):Length2D() > self.breakDistance then
        self.parent:RemoveModifierByName("modifier_grimstroke_soul_bind_custom_debuff")
    end
end

function modifier_grimstroke_soul_bind_custom_debuff:OnRemoved()
    if not IsServer() then return end
    if not self.caster or self.caster == nil then return end

    self.casterMod = self.caster:FindModifierByName("modifier_grimstroke_soul_bind_custom_self_buff")
    if self.casterMod ~= nil then
        self.casterMod:DecrementStackCount()
    end

    if self.effect ~= nil then
        ParticleManager:DestroyParticle(self.effect, false)
        ParticleManager:ReleaseParticleIndex(self.effect)
    end

    if self.effectSkull ~= nil then
        ParticleManager:DestroyParticle(self.effectSkull, false)
        ParticleManager:ReleaseParticleIndex(self.effectSkull)
    end

    if self.effectChain ~= nil then
        ParticleManager:DestroyParticle(self.effectChain, false)
        ParticleManager:ReleaseParticleIndex(self.effectChain)
    end

    StopSoundOn("Hero_Grimstroke.SoulChain.Leash", self:GetParent())

    self.parent:RemoveModifierByName("modifier_grimstroke_soul_bind_custom_debuff_mana_transfer")

    _G.GrimstrokeSoulbindChains[self.caster:entindex()] = _G.GrimstrokeSoulbindChains[self.caster:entindex()] or nil 
    _G.GrimstrokeSoulbindChains[self.caster:entindex()] = nil
end
--------
function modifier_grimstroke_soul_bind_custom_debuff_mana_transfer:OnCreated()
    if not IsServer() then return end

    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.attacker = self.caster

    local owner = self.caster:GetOwner()
    if self.caster:IsIllusion() and owner ~= nil then
        if owner:IsPlayerController() then
            self.attacker = owner:GetAssignedHero()
        end
    end

    self.interval = self.ability:GetSpecialValueFor("transfer_interval")
    self.transferAmount = self.ability:GetSpecialValueFor("mana_transfer_pct")
    self.damageMultiplier = self.ability:GetSpecialValueFor("mana_transfer_damage_multiplier")

    self.damageTable = {
        attacker = self.attacker,
        victim = self.parent,
        damage_type = self.ability:GetAbilityDamageType(),
        ability = self.ability,
    }

    self:StartIntervalThink(self.interval)
end

function modifier_grimstroke_soul_bind_custom_debuff_mana_transfer:OnIntervalThink()
    if not self.caster or self.caster == nil then return end
    
    self.casterMod = self.caster:FindModifierByName("modifier_grimstroke_soul_bind_custom_self_buff")
    if not self.casterMod or self.casterMod == nil then return end
    local stacks = self.casterMod:GetStackCount()

    if stacks <= 0 then
        stacks = 1
    end

    local mana = (self.caster:GetMana() * (self.transferAmount/100)) / stacks
    if mana <= 0 then return end

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_MANA_LOSS,
        self.caster,
        mana,
        nil
    )

    self.damageTable.damage = mana * (self.damageMultiplier/100)

    ApplyDamage(self.damageTable)
end

function modifier_grimstroke_soul_bind_custom_debuff_mana_transfer:IsHidden() return true end

function modifier_grimstroke_soul_bind_custom_debuff_mana_transfer:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end