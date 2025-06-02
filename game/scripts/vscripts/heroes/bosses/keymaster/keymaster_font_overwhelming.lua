LinkLuaModifier("modifier_keymaster_font_overwhelming", "heroes/bosses/keymaster/keymaster_font_overwhelming", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_keymaster_font_overwhelming_aura", "heroes/bosses/keymaster/keymaster_font_overwhelming", LUA_MODIFIER_MOTION_NONE)

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

keymaster_font_overwhelming = class(ItemBaseClass)
modifier_keymaster_font_overwhelming = class(keymaster_font_overwhelming)
modifier_keymaster_font_overwhelming_aura = class(ItemBaseClassAura)
-------------
function keymaster_font_overwhelming:GetIntrinsicModifierName()
    return "modifier_keymaster_font_overwhelming"
end

function keymaster_font_overwhelming:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
------------
function modifier_keymaster_font_overwhelming:DeclareFunctions()
    local funcs = {}

    return funcs
end

function modifier_keymaster_font_overwhelming:OnCreated()
    if not IsServer() then return end
end

function modifier_keymaster_font_overwhelming:IsAura()
  return true
end

function modifier_keymaster_font_overwhelming:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC)
end

function modifier_keymaster_font_overwhelming:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_keymaster_font_overwhelming:GetAuraRadius()
  return self:GetAbility():GetLevelSpecialValueFor("radius", (self:GetAbility():GetLevel() - 1))
end

function modifier_keymaster_font_overwhelming:GetModifierAura()
    return "modifier_keymaster_font_overwhelming_aura"
end

function modifier_keymaster_font_overwhelming:GetAuraEntityReject(target)
    return not self:GetCaster():HasModifier("modifier_abaddon_borrowed_time")
end
-----------
function modifier_keymaster_font_overwhelming_aura:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()
    
    if ability and not ability:IsNull() then
        self.slow = self:GetAbility():GetLevelSpecialValueFor("slow", (self:GetAbility():GetLevel() - 1))
        self.interval = self:GetAbility():GetLevelSpecialValueFor("interval", (self:GetAbility():GetLevel() - 1))

        self:StartIntervalThink(self.interval)
    end
end

function modifier_keymaster_font_overwhelming_aura:OnIntervalThink()
    local unit = self:GetParent()
    local caster = self:GetCaster()
    local curseOfAvernus = caster:FindAbilityByName("abaddon_frostmourne")

    if not unit:IsAlive() or not curseOfAvernus then return end

    local debuff = unit:FindModifierByNameAndCaster("modifier_abaddon_frostmourne_debuff", caster)
    local debuffBonus = unit:FindModifierByNameAndCaster("modifier_abaddon_frostmourne_debuff_bonus", caster)
    local stacks = unit:GetModifierStackCount("modifier_abaddon_frostmourne_debuff", caster)

    if debuffBonus then return end

    if not debuff then
        unit:AddNewModifier(caster, curseOfAvernus, "modifier_abaddon_frostmourne_debuff", { 
            duration = curseOfAvernus:GetSpecialValueFor("curse_duration")
        })

        unit:SetModifierStackCount("modifier_abaddon_frostmourne_debuff", caster, 1)
    else
        debuff:ForceRefresh()
    end

    if stacks < curseOfAvernus:GetSpecialValueFor("hit_count") then
        unit:SetModifierStackCount("modifier_abaddon_frostmourne_debuff", caster, (stacks + 1))
    end

    if stacks == curseOfAvernus:GetSpecialValueFor("hit_count") then
        unit:RemoveModifierByNameAndCaster("modifier_abaddon_frostmourne_debuff", caster)
        unit:AddNewModifier(caster, curseOfAvernus, "modifier_abaddon_frostmourne_debuff_bonus", { 
            duration = curseOfAvernus:GetSpecialValueFor("slow_duration")
        })
        unit:EmitSound("Hero_Abaddon.Curse.Proc")
    end
end

function modifier_keymaster_font_overwhelming_aura:OnRemoved()
    if not IsServer() then return end

    self:StartIntervalThink(-1)
end

function modifier_keymaster_font_overwhelming_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
    }

    return funcs
end

function modifier_keymaster_font_overwhelming_aura:GetModifierMoveSpeedBonus_Percentage()
    return self.slow or self:GetAbility():GetLevelSpecialValueFor("slow", (self:GetAbility():GetLevel() - 1))
end