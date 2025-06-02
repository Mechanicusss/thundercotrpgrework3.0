item_kingslayer = class({})

LinkLuaModifier("modifier_item_kingslayer", "kingslayer", LUA_MODIFIER_MOTION_NONE)

function item_kingslayer:GetIntrinsicModifierName() 
    return "modifier_item_kingslayer" 
end

modifier_item_kingslayer = class({})


function modifier_item_kingslayer:DeclareFunctions() 
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING, --GetModifierPercentageManacostStacking
        MODIFIER_PROPERTY_MANA_DRAIN_AMPLIFY_PERCENTAGE, --GetModifierManaDrainAmplify_Percentage
    } 
end

function modifier_item_kingslayer:IsHidden()
    return true
end

function modifier_item_kingslayer:OnCreated()
    if self:GetAbility() == nil then
        return
    end

    self.intel = self:GetAbility():GetSpecialValueFor("bonus_intellect")
    self.amp = self:GetAbility():GetSpecialValueFor("spell_amp")
    self.life = self:GetAbility():GetSpecialValueFor("manacost_reduction")
end

function modifier_item_kingslayer:GetModifierBonusStats_Intellect() 
    return self.intel
end
function modifier_item_kingslayer:GetModifierSpellAmplify_Percentage() 
    return self.amp
end
function modifier_item_kingslayer:GetModifierManaDrainAmplify_Percentage() 
    return -self.life
end
function modifier_item_kingslayer:GetModifierPercentageManacostStacking() 
    return self.life
end
