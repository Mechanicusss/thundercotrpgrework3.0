LinkLuaModifier("modifier_dazzle_shallow_grave_custom", "heroes/hero_dazzle/dazzle_shallow_grave_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_shallow_grave_custom_aura", "heroes/hero_dazzle/dazzle_shallow_grave_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_shallow_grave_custom_buff", "heroes/hero_dazzle/dazzle_shallow_grave_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dazzle_shallow_grave_custom_cooldown", "heroes/hero_dazzle/dazzle_shallow_grave_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

dazzle_shallow_grave_custom = class(ItemBaseClass)
modifier_dazzle_shallow_grave_custom = class(dazzle_shallow_grave_custom)
modifier_dazzle_shallow_grave_custom_aura = class(ItemBaseClassAura)
modifier_dazzle_shallow_grave_custom_buff = class(ItemBaseClassAura)
modifier_dazzle_shallow_grave_custom_cooldown = class(ItemBaseClass)

function modifier_dazzle_shallow_grave_custom_cooldown:IsHidden() return false end
function modifier_dazzle_shallow_grave_custom_cooldown:IsDebuff() return true end
-------------
function dazzle_shallow_grave_custom:GetIntrinsicModifierName()
    return "modifier_dazzle_shallow_grave_custom"
end

function dazzle_shallow_grave_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
---------------------------------------------------------------------
function modifier_dazzle_shallow_grave_custom:IsAura()
    return true
end

function modifier_dazzle_shallow_grave_custom:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_dazzle_shallow_grave_custom:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_dazzle_shallow_grave_custom:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_dazzle_shallow_grave_custom:GetModifierAura()
    return "modifier_dazzle_shallow_grave_custom_aura"
end

function modifier_dazzle_shallow_grave_custom:GetAuraEntityReject(target)
    return false
end
--------------------------------------------------------
function modifier_dazzle_shallow_grave_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MIN_HEALTH 
    }
end

function modifier_dazzle_shallow_grave_custom_buff:GetMinHealth()
    return 1
end

function modifier_dazzle_shallow_grave_custom_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self:PlayEffects(parent)
end

function modifier_dazzle_shallow_grave_custom_buff:OnDestroy()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    local parent = self:GetParent()
    parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_dazzle_shallow_grave_custom_cooldown", {
        duration = self:GetAbility():GetSpecialValueFor("cooldown")
    })

    local heal = parent:GetMaxHealth()
    parent:Heal(heal, self:GetAbility())
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, heal, nil)
end

function modifier_dazzle_shallow_grave_custom_buff:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/dazzle/dazzle_dark_light_weapon/dazzle_dark_shallow_grave.vpcf"
    local sound_cast = "Hero_Dazzle.Shallow_Grave"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end