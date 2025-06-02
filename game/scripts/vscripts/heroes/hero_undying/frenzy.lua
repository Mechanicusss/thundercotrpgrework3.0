LinkLuaModifier("modifier_undying_frenzy_custom", "heroes/hero_undying/frenzy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_undying_frenzy_custom_buff", "heroes/hero_undying/frenzy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_undying_frenzy_custom_buff_aura", "heroes/hero_undying/frenzy", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

undying_frenzy_custom = class(ItemBaseClass)
modifier_undying_frenzy_custom = class(undying_frenzy_custom)
modifier_undying_frenzy_custom_buff = class(ItemBaseClassBuff)
modifier_undying_frenzy_custom_buff_aura = class(ItemBaseClassAura)
-------------
function undying_frenzy_custom:OnSpellStart()
    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_undying_frenzy_custom_buff", {duration=self:GetSpecialValueFor("duration")})
    EmitSoundOn("Hero_Undying.FleshGolem.Cast", caster)
end
function undying_frenzy_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
-------------
function modifier_undying_frenzy_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT, --GetModifierBaseAttackTimeConstant
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function modifier_undying_frenzy_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movespeed")
end

function modifier_undying_frenzy_custom_buff:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function modifier_undying_frenzy_custom_buff:GetModifierModelScale()
    return 2
end

function modifier_undying_frenzy_custom_buff:GetModifierBaseAttackTimeConstant()
    return self:GetAbility():GetSpecialValueFor("bat")
end

function modifier_undying_frenzy_custom_buff:GetEffectName()
    return "particles/units/heroes/hero_necrolyte/necrolyte_spirit_ground_aura.vpcf"
end

function modifier_undying_frenzy_custom_buff:IsAura()
  return true
end

function modifier_undying_frenzy_custom_buff:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_undying_frenzy_custom_buff:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_undying_frenzy_custom_buff:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_undying_frenzy_custom_buff:GetModifierAura()
    return "modifier_undying_frenzy_custom_buff_aura"
end

function modifier_undying_frenzy_custom_buff:GetAuraEntityReject(target)
    if target:IsMagicImmune() then return true end

    return false
end

function modifier_undying_frenzy_custom_buff_aura:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.dmg = self:GetAbility():GetLevelSpecialValueFor("max_hp_damage", (self:GetAbility():GetLevel() - 1))
    end

    self:StartIntervalThink(0.25)
end

function modifier_undying_frenzy_custom_buff_aura:OnIntervalThink()
    local dmg = self:GetCaster():GetMaxHealth() * (self.dmg/100)
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = dmg/4,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(),
    })
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), dmg/4, nil)
end