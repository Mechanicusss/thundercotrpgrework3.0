LinkLuaModifier("modifier_drow_ranger_sharp_arrow_custom", "heroes/hero_drow_ranger/sharp_arrow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_sharp_arrow_custom_debuff", "heroes/hero_drow_ranger/sharp_arrow", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

drow_ranger_sharp_arrow_custom = class(ItemBaseClass)
modifier_drow_ranger_sharp_arrow_custom = class(drow_ranger_sharp_arrow_custom)
modifier_drow_ranger_sharp_arrow_custom_debuff = class(ItemBaseClassDebuff)
-------------
function drow_ranger_sharp_arrow_custom:GetIntrinsicModifierName()
    return "modifier_drow_ranger_sharp_arrow_custom"
end

function modifier_drow_ranger_sharp_arrow_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
    return funcs
end

function modifier_drow_ranger_sharp_arrow_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_drow_ranger_sharp_arrow_custom:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if unit:IsIllusion() then return end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end
    
    local chance = ability:GetLevelSpecialValueFor("chance", (ability:GetLevel() - 1))
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    if not RollPercentage(chance) then
        return
    end

    victim:AddNewModifier(caster, ability, "modifier_drow_ranger_sharp_arrow_custom_debuff", { duration = duration })
end
-------
function modifier_drow_ranger_sharp_arrow_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE
    }

    return funcs
end

function modifier_drow_ranger_sharp_arrow_custom_debuff:GetModifierPhysicalArmorBase_Percentage()
    return 100 + self:GetAbility():GetLevelSpecialValueFor("armor_reduction_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_drow_ranger_sharp_arrow_custom_debuff:GetEffectName()
    return "particles/items3_fx/star_emblem_brokenshield.vpcf"
end

function modifier_drow_ranger_sharp_arrow_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end
----