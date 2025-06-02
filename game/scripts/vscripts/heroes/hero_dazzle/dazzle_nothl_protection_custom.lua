LinkLuaModifier("modifier_dazzle_nothl_protection_custom", "heroes/hero_dazzle/dazzle_nothl_protection_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_nothl_protection_custom_absorb_state", "heroes/hero_dazzle/dazzle_nothl_protection_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAbsorb = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

dazzle_nothl_protection_custom = class(ItemBaseClass)
modifier_dazzle_nothl_protection_custom = class(dazzle_nothl_protection_custom)
modifier_dazzle_nothl_protection_custom_absorb_state = class(ItemBaseClassAbsorb)
-------------
function dazzle_nothl_protection_custom:GetIntrinsicModifierName()
    return "modifier_dazzle_nothl_protection_custom"
end

function dazzle_nothl_protection_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    
    target:AddNewModifier(caster, ability, "modifier_dazzle_nothl_protection_custom_absorb_state", { duration = duration })

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_dazzle/dazzle_lucky_charm.vpcf", PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
    EmitSoundOn("Hero_Dazzle.BadJuJu.Target", target)
end
------------
function modifier_dazzle_nothl_protection_custom_absorb_state:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE  
    }

    return funcs
end

function modifier_dazzle_nothl_protection_custom_absorb_state:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_dazzle_nothl_protection_custom_absorb_state:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_dazzle_nothl_protection_custom_absorb_state:GetAbsoluteNoDamagePure()
    return 1
end

function modifier_dazzle_nothl_protection_custom_absorb_state:OnDestroy()
    if not IsServer() then return end
    local parent = self:GetParent()
    local heal = parent:GetMaxHealth()
    parent:Heal(heal, self:GetAbility())
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, heal, nil)
end