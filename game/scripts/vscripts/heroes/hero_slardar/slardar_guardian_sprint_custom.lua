LinkLuaModifier("modifier_slardar_guardian_sprint_custom", "heroes/hero_slardar/slardar_guardian_sprint_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

slardar_guardian_sprint_custom = class(ItemBaseClass)
modifier_slardar_guardian_sprint_custom = class(slardar_guardian_sprint_custom)
-------------
function slardar_guardian_sprint_custom:GetIntrinsicModifierName()
    return "modifier_slardar_guardian_sprint_custom"
end
------------
function modifier_slardar_guardian_sprint_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE 
    }

    return funcs
end

function modifier_slardar_guardian_sprint_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_slardar_guardian_sprint_custom:OnIntervalThink()
    if self:IsInWater() then
        self.speed = self:GetAbility():GetSpecialValueFor("bonus_speed")*2
        self.damage = self:GetAbility():GetSpecialValueFor("bonus_damage_pct")*2
        self.regen = self:GetAbility():GetSpecialValueFor("hp_regen_pct")*2
        self.vfx = "particles/units/heroes/hero_slardar/slardar_sprint_river.vpcf"
    else
        self.speed = self:GetAbility():GetSpecialValueFor("bonus_speed")
        self.damage = self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
        self.regen = self:GetAbility():GetSpecialValueFor("hp_regen_pct")
        self.vfx = "particles/units/heroes/hero_slardar/slardar_sprint.vpcf"
    end

    self:Invoke()
end

function modifier_slardar_guardian_sprint_custom:AddCustomTransmitterData()
    return
    {
        speed = self.fSpeed,
        damage = self.fDamage,
        regen = self.fRegen,
        vfx = self.fVfx
    }
end

function modifier_slardar_guardian_sprint_custom:HandleCustomTransmitterData(data)
    if data.speed ~= nil and data.damage ~= nil and data.regen ~= nil and data.vfx ~= nil then
        self.fSpeed = tonumber(data.speed)
        self.fDamage = tonumber(data.damage)
        self.fRegen = tonumber(data.regen)
        self.fVfx = tonumber(data.vfx)
    end
end

function modifier_slardar_guardian_sprint_custom:Invoke()
    if IsServer() == true then
        self.fSpeed = self.speed
        self.fDamage = self.damage
        self.fRegen = self.regen
        self.fVfx = self.vfx

        self:SendBuffRefreshToClients()
    end
end

function modifier_slardar_guardian_sprint_custom:IsInWater()
    if not self:GetParent():HasScepter() then return false end
    return (self:GetParent():GetOrigin().z <= 384) or self:GetParent():HasModifier("modifier_slardar_slithereen_crush_custom_emitter_aura")
end

function modifier_slardar_guardian_sprint_custom:GetModifierMoveSpeedBonus_Percentage()
    return self.fSpeed
end

function modifier_slardar_guardian_sprint_custom:GetModifierDamageOutgoing_Percentage()
    return self.fDamage
end

function modifier_slardar_guardian_sprint_custom:GetModifierHealthRegenPercentage()
    return self.fRegen
end

function modifier_slardar_guardian_sprint_custom:GetEffectName()
    return self.fVfx
end

function modifier_slardar_guardian_sprint_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_slardar_guardian_sprint_custom:CheckState()
    local state = {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }

    return state
end