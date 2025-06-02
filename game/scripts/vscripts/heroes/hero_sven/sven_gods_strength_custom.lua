LinkLuaModifier("modifier_sven_gods_strength_custom", "heroes/hero_sven/sven_gods_strength_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

sven_gods_strength_custom = class(ItemBaseClass)
modifier_sven_gods_strength_custom = class(sven_gods_strength_custom)
-------------
function sven_gods_strength_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_sven/sven_spell_gods_strength.vpcf", PATTACH_POINT_FOLLOW, caster )
    ParticleManager:SetParticleControl( effect_cast, 0, caster:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_Sven.GodsStrength", caster)

    if caster:HasModifier("modifier_sven_gods_strength_custom") then
        caster:RemoveModifierByName("modifier_sven_gods_strength_custom")
    end

    caster:AddNewModifier(caster, self, "modifier_sven_gods_strength_custom", {
        duration = self:GetSpecialValueFor("duration")
    })
end
-------------
function modifier_sven_gods_strength_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_sven_gods_strength_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if attacker ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    EmitSoundOn("Hero_Sven.GodsStrength.Attack", attacker)
    EmitSoundOn("Hero_Sven.Layer.GodsStrength", attacker)
end

function modifier_sven_gods_strength_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.total = caster:GetStrength() * (ability:GetSpecialValueFor("strength_increase_pct")/100)

    if caster:HasModifier("modifier_item_aghanims_shard") then
        local agility = caster:GetAgility() * (ability:GetSpecialValueFor("shard_attribute_conversion")/100)
        local intellect = caster:GetBaseIntellect() * (ability:GetSpecialValueFor("shard_attribute_conversion")/100)
        self.total = self.total + agility + intellect
    end

    self:InvokeBonus()
end

function modifier_sven_gods_strength_custom:GetModifierBonusStats_Strength()
    return self.fTotal
end

function modifier_sven_gods_strength_custom:GetEffectName()
    return "particles/units/heroes/hero_sven/sven_spell_gods_strength_ambient.vpcf"
end

function modifier_sven_gods_strength_custom:AddCustomTransmitterData()
    return
    {
        total = self.fTotal,
    }
end

function modifier_sven_gods_strength_custom:HandleCustomTransmitterData(data)
    if data.total ~= nil then
        self.fTotal = tonumber(data.total)
    end
end

function modifier_sven_gods_strength_custom:InvokeBonus()
    if IsServer() == true then
        self.fTotal = self.total

        self:SendBuffRefreshToClients()
    end
end

function modifier_sven_gods_strength_custom:GetHeroEffectName()
    return "particles/units/heroes/hero_sven/sven_gods_strength_hero_effect.vpcf"
end

function modifier_sven_gods_strength_custom:GetStatusEffectName()
    return "particles/status_fx/status_effect_gods_strength.vpcf"
end

function modifier_sven_gods_strength_custom:HeroEffectPriority()
    return 10
end

function modifier_sven_gods_strength_custom:StatusEffectPriority()
    return 10
end