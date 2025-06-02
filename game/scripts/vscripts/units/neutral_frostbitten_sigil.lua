LinkLuaModifier("modifier_neutral_frostbitten_sigil", "units/neutral_frostbitten_sigil", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

neutral_frostbitten_sigil = class(ItemBaseClass)
modifier_neutral_frostbitten_sigil = class(neutral_frostbitten_sigil)
-------------
function neutral_frostbitten_sigil:GetIntrinsicModifierName()
    return "modifier_neutral_frostbitten_sigil"
end


function modifier_neutral_frostbitten_sigil:DeclareFunctions()
    local funcs = {
    }
    return funcs
end

function modifier_neutral_frostbitten_sigil:OnCreated()
    if not IsServer() then return end
    self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_tusk_frozen_sigil_aura", {})
end