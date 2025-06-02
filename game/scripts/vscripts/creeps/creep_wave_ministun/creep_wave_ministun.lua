LinkLuaModifier("modifier_creep_wave_ministun", "creeps/creep_wave_ministun/creep_wave_ministun", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

creep_wave_ministun = class(ItemBaseClass)
modifier_creep_wave_ministun = class(ItemBaseClassDebuff)
-------------
function creep_wave_ministun:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    target:AddNewModifier(caster, self, "modifier_creep_wave_ministun", {
        duration = self:GetSpecialValueFor("duration")
    })

    EmitSoundOn("Hero_Enigma.Malefice", target)
end
-----------
function modifier_creep_wave_ministun:OnCreated()
    if not IsServer() then return end 

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_creep_wave_ministun:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    parent:AddNewModifier(caster, nil, "modifier_stunned", {
        duration = self:GetAbility():GetSpecialValueFor("stun_duration")
    })

    EmitSoundOn("Hero_Enigma.MaleficeTick", parent)
end

function modifier_creep_wave_ministun:GetEffectName()
    return "particles/units/heroes/hero_enigma/enigma_malefice.vpcf"
end
