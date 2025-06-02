LinkLuaModifier("modifier_medusa_mana_leech", "heroes/hero_medusa/medusa_mana_leech", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

medusa_mana_leech = class(ItemBaseClass)
modifier_medusa_mana_leech = class(medusa_mana_leech)
-------------
function medusa_mana_leech:GetIntrinsicModifierName()
    return "modifier_medusa_mana_leech"
end

function modifier_medusa_mana_leech:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_medusa_mana_leech:OnAttackLanded(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if not unit:IsRealHero() or unit:IsIllusion() or (not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim)) then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    local mana = event.damage * (ability:GetSpecialValueFor("attack_to_mana_leech_pct")/100)

    unit:GiveMana(mana)

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_MANA_ADD,
        unit,
        mana,
        nil
    )

    ability:UseResources(false, false, false, true)
end