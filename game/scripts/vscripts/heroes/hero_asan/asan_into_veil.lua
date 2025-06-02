LinkLuaModifier("modifier_asan_into_veil", "heroes/hero_asan/asan_into_veil", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_asan_into_veil_buff", "heroes/hero_asan/asan_into_veil", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_asan_into_veil_aura_enemy", "heroes/hero_asan/asan_into_veil", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

asan_into_veil = class(ItemBaseClass)
modifier_asan_into_veil = class(asan_into_veil)
modifier_asan_into_veil_buff = class(ItemBaseClassBuff)
modifier_asan_into_veil_aura_enemy = class(ItemBaseAura)
-------------
function asan_into_veil:GetIntrinsicModifierName()
    return "modifier_asan_into_veil"
end

function asan_into_veil:GetCooldown()
    local caster = self:GetCaster()
    local cooldown = self.BaseClass.GetCooldown(self, -1)
    local talent = caster:FindAbilityByName("special_bonus_unique_asan_5_custom")
    
    if talent ~= nil and talent:GetLevel() > 0 then
        cooldown = cooldown + talent:GetSpecialValueFor("value")
    end

    return cooldown or 0
end

function asan_into_veil:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function asan_into_veil:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetSpecialValueFor("duration")

    local talent = caster:FindAbilityByName("special_bonus_unique_asan_4_custom")
    
    if talent ~= nil and talent:GetLevel() > 0 then
        duration = duration + talent:GetSpecialValueFor("value")
    end
    
    caster:AddNewModifier(caster, ability, "modifier_asan_into_veil_buff", { duration = duration })
end
----
function modifier_asan_into_veil_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        --MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_asan_into_veil_buff:GetModifierMoveSpeedBonus_Percentage(event)
    local bonus = self:GetAbility():GetSpecialValueFor("movement_speed_bonus")
    local parent = self:GetParent()
    local talent = parent:FindAbilityByName("special_bonus_unique_asan_1_custom")
    
    if talent ~= nil and talent:GetLevel() > 0 then
        bonus = bonus + talent:GetSpecialValueFor("value")
    end

    return bonus
end

function modifier_asan_into_veil_buff:GetModifierIncomingDamage_Percentage(event)
    if not event.attacker:HasModifier("modifier_asan_into_veil_aura_enemy") then
        return -100
    end
end

--function modifier_asan_into_veil_buff:GetModifierDamageOutgoing_Percentage(event)
--    if event.target ~= nil then
--        if not event.target:HasModifier("modifier_asan_into_veil_aura_enemy") then
--            return -100
--        end
--    end
--end

function modifier_asan_into_veil_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    EmitSoundOn("Hero_PhantomAssassin.Blur", parent)

    self.radius = ability:GetSpecialValueFor("radius")

    -- Self buff Effect --
    self.buffEffect = ParticleManager:CreateParticle( "particles/units/heroes/hero_phantom_assassin_persona/pa_persona_phantom_blur_active.vpcf", PATTACH_POINT_FOLLOW, parent )
    
    ParticleManager:SetParticleControlEnt(
        self.buffEffect,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    -- AOE Effect --
    self.aoeEffect = ParticleManager:CreateParticle( "particles/econ/items/nightstalker/nightstalker_ti10_silence/nightstalker_ti10_2.vpcf", PATTACH_POINT_FOLLOW, parent )
    
    ParticleManager:SetParticleControlEnt(
        self.aoeEffect,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetOrigin(), -- unknown
        true -- unknown, true
    )

    ParticleManager:SetParticleControl( self.aoeEffect, 2, Vector(self.radius, 0, 0) )
    
    -- Burst Effect --
    self.burstEffect = ParticleManager:CreateParticle( "particles/units/heroes/hero_phantom_assassin_persona/pa_persona_phantom_strike_end.vpcf", PATTACH_POINT_FOLLOW, parent )
    
    ParticleManager:SetParticleControlEnt(
        self.burstEffect,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetOrigin(), -- unknown
        true -- unknown, true
    )

    ParticleManager:ReleaseParticleIndex(self.burstEffect)
end

function modifier_asan_into_veil_buff:OnDestroy()
    if not IsServer() then return end

    if self.buffEffect ~= nil then
        ParticleManager:DestroyParticle(self.buffEffect, false)
        ParticleManager:ReleaseParticleIndex(self.buffEffect)
    end

    if self.aoeEffect ~= nil then
        ParticleManager:DestroyParticle(self.aoeEffect, false)
        ParticleManager:ReleaseParticleIndex(self.aoeEffect)
    end

    EmitSoundOn("Hero_PhantomAssassin.Blur.Break", self:GetParent())
end

function modifier_asan_into_veil_buff:IsAura()
  return true
end

function modifier_asan_into_veil_buff:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP)
end

function modifier_asan_into_veil_buff:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_asan_into_veil_buff:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_asan_into_veil_buff:GetModifierAura()
    return "modifier_asan_into_veil_aura_enemy"
end

function modifier_asan_into_veil_buff:GetAuraEntityReject(ent) 
    return false
end

function modifier_asan_into_veil_buff:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_asan_into_veil_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_asan_into_veil_buff:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_asan_into_veil_buff:StatusEffectPriority()
    return 10001
end
--------------
function modifier_asan_into_veil_aura_enemy:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.buffEffect = ParticleManager:CreateParticle( "particles/units/heroes/hero_phantom_assassin_persona/pa_persona_phantom_blur_active.vpcf", PATTACH_POINT_FOLLOW, parent )
    
    ParticleManager:SetParticleControlEnt(
        self.buffEffect,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    EmitSoundOn("Hero_PhantomAssassin.Blur", parent)
end

function modifier_asan_into_veil_aura_enemy:OnDestroy()
    if not IsServer() then return end

    if self.buffEffect ~= nil then
        ParticleManager:DestroyParticle(self.buffEffect, false)
        ParticleManager:ReleaseParticleIndex(self.buffEffect)
    end

    EmitSoundOn("Hero_PhantomAssassin.Blur.Break", self:GetParent())
end

function modifier_asan_into_veil_aura_enemy:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

function modifier_asan_into_veil_aura_enemy:GetModifierIncomingDamage_Percentage(event)
    if event.attacker:HasModifier("modifier_asan_into_veil_buff") then
        return self:GetAbility():GetSpecialValueFor("damage_amplify")
    end
end

function modifier_asan_into_veil_aura_enemy:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_asan_into_veil_aura_enemy:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_asan_into_veil_aura_enemy:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_asan_into_veil_aura_enemy:StatusEffectPriority()
    return 10001
end