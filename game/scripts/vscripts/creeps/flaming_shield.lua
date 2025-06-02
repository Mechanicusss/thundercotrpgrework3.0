LinkLuaModifier("modifier_creep_flaming_shield", "creeps/flaming_shield", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_creep_flaming_shield_aura", "creeps/flaming_shield", LUA_MODIFIER_MOTION_NONE)

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
}

creep_flaming_shield = class(ItemBaseClass)
modifier_creep_flaming_shield = class(creep_flaming_shield)
modifier_creep_flaming_shield_aura = class(ItemBaseClassAura)

-------------
function creep_flaming_shield:GetIntrinsicModifierName()
    return "modifier_creep_flaming_shield"
end

function modifier_creep_flaming_shield:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, --GetModifierIncomingDamage_Percentage
    }

    return funcs
end

function modifier_creep_flaming_shield:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_absorb")
end

function modifier_creep_flaming_shield:GetEffectName()
    return "particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf"
end

function modifier_creep_flaming_shield:IsAura()
  return true
end

function modifier_creep_flaming_shield:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_creep_flaming_shield:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_creep_flaming_shield:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_creep_flaming_shield:GetModifierAura()
    return "modifier_creep_flaming_shield_aura"
end

function modifier_creep_flaming_shield:GetAuraEntityReject(target)
    if target:IsMagicImmune() then return true end

    return false
end

function modifier_creep_flaming_shield_aura:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.dmg = self:GetAbility():GetLevelSpecialValueFor("damage", (self:GetAbility():GetLevel() - 1))
    end

    self:StartIntervalThink(0.1)
end

function modifier_creep_flaming_shield_aura:OnIntervalThink()
    local dmg = self.dmg/10

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = dmg,
        damage_type = DAMAGE_TYPE_PURE,
        ability = self:GetAbility(),
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, self:GetParent(), dmg, nil)
end