LinkLuaModifier("modifier_shadow_shaman_bloodlust", "heroes/hero_shadow_shaman/shadow_shaman_bloodlust", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shadow_shaman_bloodlust_buff", "heroes/hero_shadow_shaman/shadow_shaman_bloodlust", LUA_MODIFIER_MOTION_NONE)

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

shadow_shaman_bloodlust = class(ItemBaseClass)
modifier_shadow_shaman_bloodlust = class(shadow_shaman_bloodlust)
modifier_shadow_shaman_bloodlust_buff = class(ItemBaseClassBuff)
-------------
function shadow_shaman_bloodlust:GetIntrinsicModifierName()
    return "modifier_shadow_shaman_bloodlust"
end

function shadow_shaman_bloodlust:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOn("Hero_OgreMagi.Bloodlust.Cast", caster)

    local wards = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,ward in ipairs(wards) do
        if IsShamanWard(ward) and ward:IsAlive() then
            local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_cast.vpcf", PATTACH_POINT_FOLLOW, ward)
            ParticleManager:SetParticleControl(effect_cast, 0, ward:GetAbsOrigin())
            ParticleManager:ReleaseParticleIndex(effect_cast)

            ward:AddNewModifier(caster, self, "modifier_shadow_shaman_bloodlust_buff", {
                duration = self:GetSpecialValueFor("duration")
            })

            EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", ward)
        end
    end
end

function modifier_shadow_shaman_bloodlust_buff:OnCreated()
    if not IsServer() then return end
end

function modifier_shadow_shaman_bloodlust_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MODEL_SCALE 
    }

    return funcs
end

function modifier_shadow_shaman_bloodlust_buff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("attack_speed_pct")
end

function modifier_shadow_shaman_bloodlust_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end

function modifier_shadow_shaman_bloodlust_buff:GetModifierModelScale()
    return 50
end

function modifier_shadow_shaman_bloodlust_buff:GetEffectName()
    return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end
