LinkLuaModifier("modifier_boss_omniknight_guardian_angel", "heroes/bosses/divine/boss_omniknight_guardian_angel", LUA_MODIFIER_MOTION_NONE)

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

boss_omniknight_guardian_angel = class(ItemBaseClass)
modifier_boss_omniknight_guardian_angel = class(boss_omniknight_guardian_angel)
-------------
function boss_omniknight_guardian_angel:GetIntrinsicModifierName()
    return "modifier_boss_omniknight_guardian_angel"
end
-------------
function modifier_boss_omniknight_guardian_angel:OnCreated()
    if not IsServer() then return end 

    local particle_cast = "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf"

    -- create particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        5,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        self:GetParent():GetOrigin(), -- unknown
        true -- unknown, true
    )

    self:AddParticle(
        effect_cast,
        false,
        false,
        -1,
        false,
        false
    )
end

function modifier_boss_omniknight_guardian_angel:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

function modifier_boss_omniknight_guardian_angel:GetModifierIncomingDamage_Percentage()
    if self:GetParent():PassivesDisabled() then return end
    return self:GetAbility():GetSpecialValueFor("damage_reduction")
end