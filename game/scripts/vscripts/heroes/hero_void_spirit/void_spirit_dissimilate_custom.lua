LinkLuaModifier("modifier_void_spirit_dissimilate_custom", "heroes/hero_void_spirit/void_spirit_dissimilate_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_void_spirit_dissimilate_custom_aura", "heroes/hero_void_spirit/void_spirit_dissimilate_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

void_spirit_dissimilate_custom = class(ItemBaseClass)
modifier_void_spirit_dissimilate_custom = class(ItemBaseClassBuff)
modifier_void_spirit_dissimilate_custom_aura = class(ItemBaseClassDebuff)
-------------
function void_spirit_dissimilate_custom:GetAOERadius()
    return self:GetSpecialValueFor("aura_radius")
end

function void_spirit_dissimilate_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local duration = self:GetSpecialValueFor("duration")

    caster:AddNewModifier(
        caster,
        self,
        "modifier_void_spirit_dissimilate_custom",
        {
            duration = duration
        }
    )

    EmitSoundOn("Hero_VoidSpirit.Dissimilate.Cast", caster)
end
---------
function modifier_void_spirit_dissimilate_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ALWAYS_ETHEREAL_ATTACK,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_OVERRIDE_ATTACK_MAGICAL,
        MODIFIER_PROPERTY_OVERRIDE_ATTACK_DAMAGE,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
end

function modifier_void_spirit_dissimilate_custom:GetModifierOverrideAttackDamage() return 0 end

function modifier_void_spirit_dissimilate_custom:GetModifierProcAttack_BonusDamage_Magical(keys)
    ApplyDamage({
        attacker = self:GetCaster(),
        victim = keys.target,
        damage = keys.original_damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })
    return 0
end

function modifier_void_spirit_dissimilate_custom:GetOverrideAttackMagical()
    return 1
end

function modifier_void_spirit_dissimilate_custom:GetAllowEtherealAttack()
    return 1
end

function modifier_void_spirit_dissimilate_custom:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_void_spirit_dissimilate_custom:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

function modifier_void_spirit_dissimilate_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_muerta/muerta_ultimate_form__2ethereal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.pfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pfx, 1, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pfx, 3, parent:GetAbsOrigin())
end

function modifier_void_spirit_dissimilate_custom:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.pfx ~= nil then
        ParticleManager:DestroyParticle(self.pfx, false)
        ParticleManager:ReleaseParticleIndex(self.pfx)
    end
end

function modifier_void_spirit_dissimilate_custom:GetStatusEffectName()
    return "particles/status_fx/status_effect_void_spirit_pulse_buff.vpcf"
end

function modifier_void_spirit_dissimilate_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_void_spirit_dissimilate_custom:StatusEffectPriority()
    return 10001
end

function modifier_void_spirit_dissimilate_custom:IsAura()
  return false
end

function modifier_void_spirit_dissimilate_custom:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_void_spirit_dissimilate_custom:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_void_spirit_dissimilate_custom:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_void_spirit_dissimilate_custom:GetModifierAura()
    return "modifier_void_spirit_dissimilate_custom_aura"
end

function modifier_void_spirit_dissimilate_custom:GetAuraEntityReject(target)
    return true
end
--------------
function modifier_void_spirit_dissimilate_custom_aura:OnCreated()
    if not IsServer() then return end

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    self.damageTable = {
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(),
    }

    if self:GetCaster():HasModifier("modifier_void_spirit_aether_remnant_custom_emitter") then
        self.damageTable.attacker = self:GetCaster():GetOwner():GetAssignedHero()
    end

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_void_spirit_dissimilate_custom_aura:OnIntervalThink()
    self.damageTable.damage = self:GetCaster():GetMaxMana() * (self:GetAbility():GetSpecialValueFor("damage_from_mana")/100)
    ApplyDamage(self.damageTable)
end