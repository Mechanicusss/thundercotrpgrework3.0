LinkLuaModifier("modifier_creature_wave_taunt", "creeps/creature_wave_taunt/creature_wave_taunt", LUA_MODIFIER_MOTION_NONE)

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

creature_wave_taunt = class(ItemBaseClass)
modifier_creature_wave_taunt = class(ItemBaseClassDebuff)
-------------
function creature_wave_taunt:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local point = caster:GetAbsOrigin()

    local radius = self:GetSpecialValueFor("radius")
    local duration = self:GetSpecialValueFor("duration")

    local victims = FindUnitsInRadius(caster:GetTeam(), point, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() or enemy:IsMagicImmune() or enemy:IsInvulnerable() then break end

        if enemy:HasModifier("modifier_creature_wave_taunt") then
            enemy:RemoveModifierByName("modifier_creature_wave_taunt")
        end
        
        enemy:AddNewModifier(caster, self, "modifier_creature_wave_taunt", {
            duration = duration
        })
    end

    local effect_cast = ParticleManager:CreateParticle( "particles/econ/items/axe/axe_ti9_immortal/axe_ti9_call.vpcf", PATTACH_POINT, caster )
    ParticleManager:SetParticleControl( effect_cast, 0, point )
    ParticleManager:SetParticleControl( effect_cast, 2, Vector(radius,radius,radius) )
    ParticleManager:ReleaseParticleIndex(effect_cast)

    EmitSoundOnLocationWithCaster(point, "Hero_Axe.Berserkers_Call", caster)
end
-----------
function modifier_creature_wave_taunt:CheckState()
    return {
        [MODIFIER_STATE_TAUNTED] = true,
        [MODIFIER_STATE_IGNORING_STOP_ORDERS] = true,
        [MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
    }
end

function modifier_creature_wave_taunt:OnCreated()
    if not IsServer() then return end 

    self:OnIntervalThink()
    self:StartIntervalThink(FrameTime())
end

function modifier_creature_wave_taunt:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if not caster or caster:IsNull() then
        self:Destroy()
        return
    end

    if not caster:IsAlive() then 
        self:Destroy()
        return
    end

    parent:MoveToTargetToAttack(caster)
end

function modifier_creature_wave_taunt:GetEffectName()
    return "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf"
end

function modifier_creature_wave_taunt:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end