LinkLuaModifier("modifier_boss_spectre_insanity", "heroes/bosses/spectre/insanity", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spectre_insanity_aura", "heroes/bosses/spectre/insanity", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spectre_insanity_aura_insane", "heroes/bosses/spectre/insanity", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

boss_spectre_insanity = class(ItemBaseClass)
modifier_boss_spectre_insanity = class(boss_spectre_insanity)
modifier_boss_spectre_insanity_aura = class(ItemBaseClassAura)
modifier_boss_spectre_insanity_aura_insane = class(ItemBaseClassDebuff)

-------------
function boss_spectre_insanity:GetIntrinsicModifierName()
    return "modifier_boss_spectre_insanity"
end

function boss_spectre_insanity:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function modifier_boss_spectre_insanity:IsAura()
  return true
end

function modifier_boss_spectre_insanity:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO)
end

function modifier_boss_spectre_insanity:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_boss_spectre_insanity:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_boss_spectre_insanity:GetModifierAura()
    return "modifier_boss_spectre_insanity_aura"
end

function modifier_boss_spectre_insanity:GetAuraEntityReject(target)
    if target:IsMagicImmune() then return true end
    return false
end
------
function modifier_boss_spectre_insanity_aura:OnCreated()
    if not IsServer() then return end
    local ability = self:GetAbility()
    self:StartIntervalThink(ability:GetSpecialValueFor("stack_interval"))
end

function modifier_boss_spectre_insanity_aura:OnIntervalThink()
    self:IncrementStackCount()

    if self:GetStackCount() >= self:GetAbility():GetSpecialValueFor("max_stacks") then
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_boss_spectre_insanity_aura_insane", { duration = self:GetAbility():GetSpecialValueFor("fear_duration") })
    end
end

function modifier_boss_spectre_insanity_aura:OnDestroy()
    self:SetStackCount(0)
end

function modifier_boss_spectre_insanity_aura:IsDebuff()
    return true
end

function modifier_boss_spectre_insanity_aura:DeclareFunctions()
    local funcs = {
         MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, --GetModifierIncomingDamage_Percentage
    }
    return funcs
end

function modifier_boss_spectre_insanity_aura:GetEffectName()
    return "particles/econ/items/spectre/spectre_arcana/spectre_arcana_rare_run.vpcf"
end

function modifier_boss_spectre_insanity_aura:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("stack_damage_increase_pct") * self:GetStackCount()
end

function modifier_boss_spectre_insanity_aura:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
--
function modifier_boss_spectre_insanity_aura_insane:CheckState()
    local state = {
        [MODIFIER_STATE_FEARED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
    return state
end

function modifier_boss_spectre_insanity_aura_insane:OnCreated()
    if not IsServer() then return end

    local base
    if self:GetParent():GetTeamNumber() == DOTA_TEAM_GOODGUYS then
        base = Entities:FindByName(nil, "ent_dota_fountain_good")
    elseif self:GetParent():GetTeamNumber() == DOTA_TEAM_BADGUYS then
        base = Entities:FindByName(nil, "ent_dota_fountain_bad")
    end

    self:GetParent():MoveToPosition(base:GetAbsOrigin())
end