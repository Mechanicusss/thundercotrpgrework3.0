LinkLuaModifier("modifier_talent_night_stalker_2", "heroes/hero_night_stalker/talents/talent_night_stalker_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_night_stalker_dark_ascension_custom_stacks_strength_to_spell", "heroes/hero_night_stalker/night_stalker_dark_ascension_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_night_stalker_2 = class(ItemBaseClass)
modifier_talent_night_stalker_2 = class(talent_night_stalker_2)
-------------
function talent_night_stalker_2:GetIntrinsicModifierName()
    return "modifier_talent_night_stalker_2"
end
-------------
function modifier_talent_night_stalker_2:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self:GetAbility(), "modifier_night_stalker_dark_ascension_custom_stacks_strength_to_spell", {})
end

function modifier_talent_night_stalker_2:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_night_stalker_dark_ascension_custom_stacks_strength_to_spell")
end