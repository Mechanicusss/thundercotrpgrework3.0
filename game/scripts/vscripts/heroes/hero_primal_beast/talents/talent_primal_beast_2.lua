LinkLuaModifier("modifier_talent_primal_beast_2", "heroes/hero_primal_beast/talents/talent_primal_beast_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_primal_beast_2 = class(ItemBaseClass)
modifier_talent_primal_beast_2 = class(talent_primal_beast_2)
-------------
function talent_primal_beast_2:GetIntrinsicModifierName()
    return "modifier_talent_primal_beast_2"
end

function talent_primal_beast_2:OnUpgrade()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local trample = caster:FindAbilityByName("primal_beast_trample_custom")

    if trample and trample:GetToggleState() then
        trample:ToggleAbility()
    end
end
-------------
function modifier_talent_primal_beast_2:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local trample = caster:FindAbilityByName("primal_beast_trample_custom")

    if trample and trample:GetToggleState() then
        trample:ToggleAbility()
    end
end

function modifier_talent_primal_beast_2:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local trample = caster:FindAbilityByName("primal_beast_trample_custom")

    if trample and trample:GetToggleState() then
        trample:ToggleAbility()
    end
end