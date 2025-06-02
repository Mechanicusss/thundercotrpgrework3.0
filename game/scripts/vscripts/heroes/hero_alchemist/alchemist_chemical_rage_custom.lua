LinkLuaModifier("modifier_alchemist_chemical_rage_custom", "heroes/hero_alchemist/alchemist_chemical_rage_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_alchemist_chemical_rage_custom_buff", "heroes/hero_alchemist/alchemist_chemical_rage_custom", LUA_MODIFIER_MOTION_NONE)

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

alchemist_chemical_rage_custom = class(ItemBaseClass)
modifier_alchemist_chemical_rage_custom = class(alchemist_chemical_rage_custom)
modifier_alchemist_chemical_rage_custom_buff = class(ItemBaseClassBuff)
-------------
function alchemist_chemical_rage_custom:GetIntrinsicModifierName()
    return "modifier_alchemist_chemical_rage_custom"
end

function alchemist_chemical_rage_custom:GetAOERadius()
    if not self:GetCaster():HasScepter() then return end

    return self:GetSpecialValueFor("aura_radius")
end

function modifier_alchemist_chemical_rage_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }
    return funcs
end

function modifier_alchemist_chemical_rage_custom:OnCreated()
end

function modifier_alchemist_chemical_rage_custom:OnAttack(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()
    
    if not RollPercentage(ability:GetSpecialValueFor("chance")) or parent:HasModifier("modifier_alchemist_chemical_rage_custom_buff") then return end

    parent:AddNewModifier(parent, ability, "modifier_alchemist_chemical_rage_custom_buff", {
        duration = ability:GetSpecialValueFor("duration")
    })
end

function modifier_alchemist_chemical_rage_custom:IsAura()
    return true
end

function modifier_alchemist_chemical_rage_custom:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_alchemist_chemical_rage_custom:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_alchemist_chemical_rage_custom:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_alchemist_chemical_rage_custom:GetModifierAura()
    return "modifier_alchemist_chemical_rage_custom_buff"
end

function modifier_alchemist_chemical_rage_custom:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_alchemist_chemical_rage_custom:GetAuraEntityReject(target)
    if target == self:GetParent() then return true end
    if not self:GetParent():HasScepter() then return true end
    if not self:GetParent():HasModifier("modifier_alchemist_chemical_rage_custom_buff") then return true end
end
-----
function modifier_alchemist_chemical_rage_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT, --GetModifierBaseAttackTimeConstant
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
        MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
    }

    return funcs
end

function modifier_alchemist_chemical_rage_custom_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local parent = self:GetParent()

    self.damage = parent:GetAverageTrueAttackDamage(parent) * (self:GetAbility():GetSpecialValueFor("increased_damage")/100)

    self:InvokeBonusDamage()

    EmitSoundOn("Hero_Alchemist.ChemicalRage.Cast", parent)

    self:PlayEffects()
end

function modifier_alchemist_chemical_rage_custom_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage
    }
end

function modifier_alchemist_chemical_rage_custom_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_alchemist_chemical_rage_custom_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_alchemist_chemical_rage_custom_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_alchemist_chemical_rage_custom_buff:GetModifierBaseAttackTimeConstant()
    return self:GetAbility():GetSpecialValueFor("fixed_bat")
end

function modifier_alchemist_chemical_rage_custom_buff:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("max_hp_regen")
end

function modifier_alchemist_chemical_rage_custom_buff:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("move_speed")
end

function modifier_alchemist_chemical_rage_custom_buff:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    StopSoundOn("Hero_Alchemist.ChemicalRage", parent)
end

function modifier_alchemist_chemical_rage_custom_buff:GetActivityTranslationModifiers()
    return "chemical_rage"
end

function modifier_alchemist_chemical_rage_custom_buff:GetAttackSound()
    return "Hero_Alchemist.ChemicalRage.Attack"
end

function modifier_alchemist_chemical_rage_custom_buff:GetHeroEffectName()
    return "particles/units/heroes/hero_alchemist/alchemist_chemical_rage_hero_effect.vpcf"
end

function modifier_alchemist_chemical_rage_custom_buff:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_alchemist/alchemist_chemical_rage.vpcf"
    local sound_cast = "Hero_Alchemist.ChemicalRage"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )

    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetAbsOrigin() )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
end

