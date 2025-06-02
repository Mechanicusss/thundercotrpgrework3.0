modifier_rebels_sword_disarmor_separate = class({})
--------------------------------------------------------------------------------

function modifier_rebels_sword_disarmor_separate:IsHidden()          return false;   end
function modifier_rebels_sword_disarmor_separate:IsDebuff()          return true;    end 
function modifier_rebels_sword_disarmor_separate:IsPurgable()        return true;    end
function modifier_rebels_sword_disarmor_separate:DestroyOnExpire()   return true;    end

--------------------------------------------------------------------------------

function modifier_rebels_sword_disarmor_separate:GetTexture()
    return "../items/custom/rebels_sword_big"
end

--------------------------------------------------------------------------------

function modifier_rebels_sword_disarmor_separate:DeclareFunctions() return 
{
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
}
end

--------------------------------------------------------------------------------

function modifier_rebels_sword_disarmor_separate:GetModifierPhysicalArmorBonus(kv)        
    --return -self:GetAbility():GetSpecialValueFor("disarmor_const")  
    return -1400
end 