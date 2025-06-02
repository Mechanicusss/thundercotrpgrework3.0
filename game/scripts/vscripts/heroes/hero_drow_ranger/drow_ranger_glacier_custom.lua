LinkLuaModifier("modifier_drow_ranger_glacier_custom", "heroes/hero_drow_ranger/drow_ranger_glacier_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_glacier_custom_aura", "heroes/hero_drow_ranger/drow_ranger_glacier_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_glacier_custom_emitter", "heroes/hero_drow_ranger/drow_ranger_glacier_custom", LUA_MODIFIER_MOTION_NONE)

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

drow_ranger_glacier_custom = class(ItemBaseClass)
modifier_drow_ranger_glacier_custom = class(drow_ranger_glacier_custom)
modifier_drow_ranger_glacier_custom_aura = class(ItemBaseClassAura)
modifier_drow_ranger_glacier_custom_emitter = class(ItemBaseClass)
-------------
function drow_ranger_glacier_custom:GetIntrinsicModifierName()
    return "modifier_drow_ranger_glacier_custom"
end

function drow_ranger_glacier_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = caster:GetAbsOrigin()
    local fw = caster:GetForwardVector()

    local duration = self:GetSpecialValueFor("duration")

    local emitter = CreateUnitByName("outpost_placeholder_unit", point, false, caster, caster, caster:GetTeamNumber())
    emitter:AddNewModifier(caster, self, "modifier_drow_ranger_glacier_custom_emitter", { 
        duration = duration,
        x = fw.x,
        y = fw.y,
        z = fw.z
    })

    EmitSoundOn("Hero_Drow.Glacier", emitter)
end
-------------
function modifier_drow_ranger_glacier_custom_emitter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
    }
end

function modifier_drow_ranger_glacier_custom_emitter:OnCreated(params)
    if not IsServer() then return end 

    local forward = Vector(params.x, params.y, params.z)

    self.parent = self:GetParent()

    self.parent:SetForwardVector(forward)

    local origin = self.parent:GetAbsOrigin()
    local glacierOrigin = Vector(origin.x, origin.y, origin.z+150)

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_drow/drow_glacier_hilltop.vpcf", PATTACH_ABSORIGIN, self.parent)
    ParticleManager:SetParticleControl(self.vfx, 0, glacierOrigin)
end

function modifier_drow_ranger_glacier_custom_emitter:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetCaster() then return end
    if event.unit:IsRealHero() then return end

    self:Destroy()
end

function modifier_drow_ranger_glacier_custom_emitter:OnDestroy()
    if not IsServer() then return end

    EmitSoundOn("Hero_Drow.End", self:GetParent())
    
    if self.vfx then
        ParticleManager:DestroyParticle(self.vfx, false)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    if self:GetParent():IsAlive() then
        UTIL_RemoveImmediate(self:GetParent())
    end
end

function modifier_drow_ranger_glacier_custom_emitter:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVISIBLE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end

function modifier_drow_ranger_glacier_custom_emitter:IsAura()
    return true
end

function modifier_drow_ranger_glacier_custom_emitter:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_drow_ranger_glacier_custom_emitter:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_drow_ranger_glacier_custom_emitter:GetAuraRadius()
    return 150
end

function modifier_drow_ranger_glacier_custom_emitter:GetModifierAura()
    return "modifier_drow_ranger_glacier_custom_aura"
end

function modifier_drow_ranger_glacier_custom_emitter:GetAuraEntityReject(target)
    return false
end
---------------
function modifier_drow_ranger_glacier_custom_aura:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_MISS] = true,
        [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
    }
end

function modifier_drow_ranger_glacier_custom_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_VISUAL_Z_DELTA,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_BONUS_DAY_VISION,
        MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
        MODIFIER_PROPERTY_VISUAL_Z_SPEED_BASE_OVERRIDE
    }
end

function modifier_drow_ranger_glacier_custom_aura:GetBonusDayVision()
    return self:GetAbility():GetSpecialValueFor("bonus_vision")
end

function modifier_drow_ranger_glacier_custom_aura:GetBonusNightVision()
    return self:GetAbility():GetSpecialValueFor("bonus_vision")
end

function modifier_drow_ranger_glacier_custom_aura:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

function modifier_drow_ranger_glacier_custom_aura:GetVisualZDelta()
    return 150
end

function modifier_drow_ranger_glacier_custom_aura:GetVisualZSpeedBaseOverride()
    return 1
end

function modifier_drow_ranger_glacier_custom_aura:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local origin = parent:GetAbsOrigin()
    local height = GetGroundPosition(origin, parent)

    parent:SetAbsOrigin(height)
end