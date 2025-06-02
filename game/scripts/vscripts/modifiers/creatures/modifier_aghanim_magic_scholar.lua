modifier_aghanim_magic_scholar = class({})
----------------------------------------------------------
function modifier_aghanim_magic_scholar:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE  
    }
end

function modifier_aghanim_magic_scholar:GetModifierIncomingDamage_Percentage(event)
    if event.target~=self:GetParent() then return end
    if event.damage_type == DAMAGE_TYPE_MAGICAL or event.damage_type == DAMAGE_TYPE_PURE then
        return self:GetAbility():GetSpecialValueFor("magic_reduction")
    end
end

function modifier_aghanim_magic_scholar:IsDebuff() return false end
function modifier_aghanim_magic_scholar:RemoveOnDeath() return true end
function modifier_aghanim_magic_scholar:IsHidden() return true end