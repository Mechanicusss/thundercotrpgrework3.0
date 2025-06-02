LinkLuaModifier("modifier_spectre_reality_custom", "heroes/hero_spectre/spectre_reality_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_reality_custom_buff", "heroes/hero_spectre/spectre_reality_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

spectre_reality_custom = class(ItemBaseClass)
modifier_spectre_reality_custom = class(spectre_reality_custom)
modifier_spectre_reality_custom_buff = class(ItemBaseClassBuff)
-------------
function spectre_reality_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function spectre_reality_custom:CastFilterResultTarget(target)
    local caster = self:GetCaster()

    if not target:IsIllusion() then 
        return UF_FAIL_ILLUSION 
    end

    if target:GetUnitName() ~= caster:GetUnitName() then 
        return UF_FAIL_OTHER 
    end

    return UF_SUCCESS
end

function spectre_reality_custom:GetCustomCastErrorTarget(target)
    return "#dota_hud_error_spectre_not_illusion"
end

function spectre_reality_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local target = self:GetCursorTarget()

    local pos = target:GetAbsOrigin()
    local fw = target:GetForwardVector()

    caster:SetAbsOrigin(pos)
    FindClearSpaceForUnit(caster, pos, false)
    caster:SetForwardVector(fw)

    EmitSoundOn("Hero_Spectre.Reality", caster)
end
---------------------
function modifier_spectre_reality_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_spectre_reality_custom_buff:GetModifierDamageOutgoing_Percentage()
    return self.fDamage * self:GetStackCount()
end

function modifier_spectre_reality_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()
end

function modifier_spectre_reality_custom_buff:OnRefresh()
    if not IsServer() then return end

    local dagger = self:GetParent():FindAbilityByName("spectre_spectral_dagger_custom")
    if not dagger then return end
    if dagger:GetLevel() < 1 then return end

    self.damage = dagger:GetSpecialValueFor("illusion_outgoing")

    self:InvokeBonusDamage()
end

function modifier_spectre_reality_custom_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_spectre_reality_custom_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_spectre_reality_custom_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end