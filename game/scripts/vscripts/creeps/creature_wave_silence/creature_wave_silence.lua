LinkLuaModifier("modifier_creature_wave_silence", "creeps/creature_wave_silence/creature_wave_silence", LUA_MODIFIER_MOTION_NONE)

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

creature_wave_silence = class(ItemBaseClass)
modifier_creature_wave_silence = class(ItemBaseClassDebuff)
-------------
function creature_wave_silence:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local radius = self:GetSpecialValueFor("radius")
    local duration = self:GetSpecialValueFor("duration")

    local victims = FindUnitsInRadius(caster:GetTeam(), point, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() or enemy:IsMagicImmune() or enemy:IsInvulnerable() then break end

        enemy:AddNewModifier(caster, self, "modifier_creature_wave_silence", {
            duration = duration
        })
    end

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_death_prophet/death_prophet_silence.vpcf", PATTACH_POINT, caster )
    ParticleManager:SetParticleControl( effect_cast, 0, point )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector(radius,0,0) )
    ParticleManager:ReleaseParticleIndex(effect_cast)

    EmitSoundOnLocationWithCaster(point, "Hero_DeathProphet.Silence", caster)
end
-----------
function modifier_creature_wave_silence:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

function modifier_creature_wave_silence:GetEffectName()
    return "particles/econ/items/death_prophet/death_prophet_ti9/death_prophet_silence_custom_ti9_overhead_model.vpcf"
end

function modifier_creature_wave_silence:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end