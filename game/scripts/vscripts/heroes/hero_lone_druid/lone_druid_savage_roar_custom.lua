LinkLuaModifier("modifier_lone_druid_savage_roar_custom", "heroes/hero_lone_druid/lone_druid_savage_roar_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lone_druid_savage_roar_custom_autocast", "heroes/hero_lone_druid/lone_druid_savage_roar_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lone_druid_savage_roar_custom_buff", "heroes/hero_lone_druid/lone_druid_savage_roar_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lone_druid_savage_roar_custom_debuff", "heroes/hero_lone_druid/lone_druid_savage_roar_custom", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

lone_druid_savage_roar_custom = class(ItemBaseClass)
modifier_lone_druid_savage_roar_custom_autocast = class(ItemBaseClass)
modifier_lone_druid_savage_roar_custom = class(ItemBaseClassBuff)
modifier_lone_druid_savage_roar_custom_buff = class(ItemBaseClassBuff)
modifier_lone_druid_savage_roar_custom_debuff = class(ItemBaseClassDebuff)
-------------
function lone_druid_savage_roar_custom:GetIntrinsicModifierName()
    return "modifier_lone_druid_savage_roar_custom_autocast"
end

function modifier_lone_druid_savage_roar_custom_autocast:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(0.1)
end

function modifier_lone_druid_savage_roar_custom_autocast:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not ability:GetAutoCastState() or not ability:IsFullyCastable() or not ability:IsCooldownReady() or ability:GetManaCost(-1) > parent:GetMana() or parent:IsSilenced() or parent:IsStunned() or parent:IsHexed() then return end

    SpellCaster:Cast(ability, parent, true)
end

function lone_druid_savage_roar_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function lone_druid_savage_roar_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    self:PerformRoar(caster)

    local bears = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,bear in ipairs(bears) do
        if bear:GetUnitName() == "npc_dota_lone_druid_bear_custom" then
            self:PerformRoar(bear)
        end
    end
end

function lone_druid_savage_roar_custom:PerformRoar(source)
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")

    local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_savage_roar.vpcf", PATTACH_ABSORIGIN_FOLLOW, source)
    ParticleManager:SetParticleControl(effect_cast, 0, source:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(effect_cast)

    local units = FindUnitsInRadius(caster:GetTeam(), source:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if caster:GetTeam() == unit:GetTeam() then
            unit:AddNewModifier(caster, self, "modifier_lone_druid_savage_roar_custom_buff", {
                duration = self:GetSpecialValueFor("buff_duration")
            })
        else
            unit:AddNewModifier(caster, self, "modifier_lone_druid_savage_roar_custom_debuff", {
                duration = self:GetSpecialValueFor("debuff_duration")
            })
        end
    end

    EmitSoundOn("Hero_LoneDruid.SavageRoar.Cast", source)
end
------------
function modifier_lone_druid_savage_roar_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_lone_druid_savage_roar_custom_buff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed_pct")
end

function modifier_lone_druid_savage_roar_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movement_speed_pct")
end
------------
function modifier_lone_druid_savage_roar_custom_debuff:CheckState()
    local states = {
        [MODIFIER_STATE_DISARMED] = true
    }

    return states
end

function modifier_lone_druid_savage_roar_custom_debuff:GetEffectName()
    return "particles/generic_gameplay/generic_disarm.vpcf"
end

function modifier_lone_druid_savage_roar_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end