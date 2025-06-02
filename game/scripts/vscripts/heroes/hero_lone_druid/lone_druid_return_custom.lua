LinkLuaModifier("modifier_lone_druid_return_custom", "heroes/hero_lone_druid/lone_druid_return_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

lone_druid_return_custom = class(ItemBaseClass)
modifier_lone_druid_return_custom = class(lone_druid_return_custom)
-------------
function lone_druid_return_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local owner = caster:GetOwner()

    if not owner then return end
    if owner:IsNull() then return end 
    if not owner:IsAlive() then return end 

    FindClearSpaceForUnit(caster, owner:GetAbsOrigin(), false)

    EmitSoundOn("LoneDruid_SpiritBear.Return", caster)

    local particle = "particles/units/heroes/hero_lone_druid/lone_druid_bear_blink_end.vpcf"

    local effect_cast = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(effect_cast, 0, caster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)
end