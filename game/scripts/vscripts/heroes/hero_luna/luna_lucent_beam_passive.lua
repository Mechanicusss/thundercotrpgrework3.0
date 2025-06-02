LinkLuaModifier("modifier_luna_lucent_beam_passive", "heroes/hero_luna/luna_lucent_beam_passive", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

luna_lucent_beam_passive = class(ItemBaseClass)
modifier_luna_lucent_beam_passive = class(luna_lucent_beam_passive)
-------------
function luna_lucent_beam_passive:GetIntrinsicModifierName()
    return "modifier_luna_lucent_beam_passive"
end

function modifier_luna_lucent_beam_passive:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_luna_lucent_beam_passive:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_luna_lucent_beam_passive:OnIntervalThink()
    if self:GetParent():HasModifier("modifier_item_aghanims_shard") then
        self:GetParent():RemoveModifierByName("modifier_item_aghanims_shard")
        DisplayError(self:GetParent():GetPlayerID(), "Item Not Allowed On This Hero")
    end
end

function modifier_luna_lucent_beam_passive:OnTakeDamage(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local victim = event.unit

    if unit ~= parent then
        return
    end

    if unit:IsIllusion() then return end

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL or (event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK and event.damage_flags ~= 1280) or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end
    
    local chance = ability:GetLevelSpecialValueFor("chance", (ability:GetLevel() - 1))

    if not RollPercentage(chance) then
        return
    end

    local beam = parent:FindAbilityByName("luna_lucent_beam")
    if beam == nil or beam:GetLevel() < 1 then return end

    SpellCaster:Cast(beam, victim, false)
end