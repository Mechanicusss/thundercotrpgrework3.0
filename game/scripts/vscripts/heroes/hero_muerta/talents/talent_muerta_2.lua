LinkLuaModifier("modifier_talent_muerta_2", "heroes/hero_muerta/talents/talent_muerta_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_muerta_2 = class(ItemBaseClass)
modifier_talent_muerta_2 = class(talent_muerta_2)
-------------
function talent_muerta_2:GetIntrinsicModifierName()
    return "modifier_talent_muerta_2"
end
-------------
function modifier_talent_muerta_2:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
end

function modifier_talent_muerta_2:GetModifierSpellAmplify_Percentage()
    if self:GetCaster():HasModifier("modifier_muerta_the_calling_custom_emitter_aura") then
        return self:GetAbility():GetSpecialValueFor("self_spell_amp")
    end
end