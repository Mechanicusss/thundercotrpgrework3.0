LinkLuaModifier("modifier_clinkz_death_pact_custom", "heroes/hero_clinkz/clinkz_death_pact_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

clinkz_death_pact_custom = class(ItemBaseClass)
modifier_clinkz_death_pact_custom = class(clinkz_death_pact_custom)
-------------
function clinkz_death_pact_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local duration = self:GetSpecialValueFor("duration")

    caster:AddNewModifier(caster, self, "modifier_clinkz_death_pact_custom", {
        duration = duration
    })

    self:PlayEffects(caster)
end

function clinkz_death_pact_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_clinkz/clinkz_death_pact.vpcf"
    local sound_cast = "Hero_Clinkz.DeathPact.Cast"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        5,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(effect_cast)

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end
----------------------------
function modifier_clinkz_death_pact_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS 
    }
end

function modifier_clinkz_death_pact_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()
end

function modifier_clinkz_death_pact_custom:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()
    local convert = ability:GetSpecialValueFor("convert_pct")

    EmitSoundOn("Hero_Clinkz.DeathPact", parent)

    self.intellect = -(parent:GetBaseIntellect() * (convert/100))
    self.strength = -(parent:GetStrength() * (convert/100))

    self.agility = math.abs(self.intellect) + math.abs(self.strength)

    self:InvokeBonus()
end

function modifier_clinkz_death_pact_custom:GetModifierBonusStats_Strength()
    return self.fStrength
end

function modifier_clinkz_death_pact_custom:GetModifierBonusStats_Agility()
    return self.fAgility
end

function modifier_clinkz_death_pact_custom:GetModifierBonusStats_Intellect()
    return self.fIntellect
end

function modifier_clinkz_death_pact_custom:AddCustomTransmitterData()
    return
    {
        agility = self.fAgility,
        intellect = self.fIntellect,
        strength = self.fStrength,
    }
end

function modifier_clinkz_death_pact_custom:HandleCustomTransmitterData(data)
    if data.agility ~= nil and data.strength ~= nil and data.intellect ~= nil then
        self.fAgility = tonumber(data.agility)
        self.fIntellect = tonumber(data.intellect)
        self.fStrength = tonumber(data.strength)
    end
end

function modifier_clinkz_death_pact_custom:InvokeBonus()
    if IsServer() == true then
        self.fAgility = self.agility
        self.fIntellect = self.intellect
        self.fStrength = self.strength

        self:SendBuffRefreshToClients()
    end
end

function modifier_clinkz_death_pact_custom:GetEffectName()
    return "particles/units/heroes/hero_clinkz/clinkz_death_pact_buff.vpcf"
end