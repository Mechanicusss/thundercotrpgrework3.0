LinkLuaModifier("modifier_grimstroke_dark_portrait_custom", "heroes/hero_grimstroke/grimstroke_dark_portrait_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_grimstroke_dark_portrait_custom_taunt", "heroes/hero_grimstroke/grimstroke_dark_portrait_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

grimstroke_dark_portrait_custom = class(ItemBaseClass)
modifier_grimstroke_dark_portrait_custom = class(grimstroke_dark_portrait_custom)
modifier_grimstroke_dark_portrait_custom_taunt = class(ItemBaseClass)
-------------
function grimstroke_dark_portrait_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local modifierKeys = {
        outgoing_damage = 0,
        incoming_damage = 0.0,
        bounty_base = 0.0,
        outgoing_damage_structure = 0,
        outgoing_damage_roshan = 0
    }

    local illusion = CreateIllusions(
        caster,
        caster,
        modifierKeys,
        1,
        0,
        false,
        true
    )

    local copy = illusion[1]

    copy:SetAbsOrigin(point)

    for i=0, copy:GetAbilityCount()-1 do
        local abil = copy:GetAbilityByIndex(i)
        if abil ~= nil then
            copy:RemoveAbilityByHandle(abil)
        end
    end

    copy:AddNewModifier(caster, self, "modifier_grimstroke_dark_portrait_custom", {})

    EmitSoundOn("Hero_Grimstroke.DarkPortrait.Cast", caster)
end
----
function modifier_grimstroke_dark_portrait_custom:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:SetMana(parent:GetMaxMana())

    local soulBind = parent:AddAbility("grimstroke_soul_bind_custom")

    local grimStrokeSoulBind = caster:FindAbilityByName("grimstroke_soul_bind_custom")
    if grimStrokeSoulBind == nil or not grimStrokeSoulBind then return end

    soulBind:SetLevel(grimStrokeSoulBind:GetLevel())

    SpellCaster:Cast(soulBind, parent, true)

    self:StartIntervalThink(0.1)

    EmitSoundOn("Hero_Grimstroke.DarkPortrait.Target", parent)
end

function modifier_grimstroke_dark_portrait_custom:OnIntervalThink()
    if not self:GetParent():HasModifier("modifier_grimstroke_soul_bind_custom_self_buff") then
        self:Destroy()
        return
    end

    local victims = FindUnitsInRadius(self:GetParent():GetTeam(), self:GetParent():GetAbsOrigin(), nil,
            self:GetAbility():GetSpecialValueFor("taunt_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and not victim:IsInvulnerable() and not victim:IsMagicImmune() and victim:GetUnitName() ~= "npc_dota_boss_aghanim" then
            victim:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_grimstroke_dark_portrait_custom_taunt", {})
        end
    end

    if #victims > 0 then
        self:GetParent():FaceTowards(victims[1]:GetAbsOrigin())
    end
end

function modifier_grimstroke_dark_portrait_custom:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_DISARMED] = true
    }
end

function modifier_grimstroke_dark_portrait_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    }
end

function modifier_grimstroke_dark_portrait_custom:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_grimstroke_dark_portrait_custom:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_grimstroke_dark_portrait_custom:GetAbsoluteNoDamagePure()
    return 1
end
--------
function modifier_grimstroke_dark_portrait_custom_taunt:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_grimstroke_dark_portrait_custom_taunt:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if caster:IsAlive() then
        parent:SetForceAttackTarget(caster)
    else
        parent:SetForceAttackTarget(nil)
        self:Destroy()
    end
end