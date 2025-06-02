LinkLuaModifier("modifier_talent_tiny_1", "heroes/hero_tiny/talents/talent_tiny_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_tiny_1_debuff", "heroes/hero_tiny/talents/talent_tiny_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

talent_tiny_1 = class(ItemBaseClass)
modifier_talent_tiny_1 = class(talent_tiny_1)
modifier_talent_tiny_1_debuff = class(ItemBaseClassDebuff)
-------------
function talent_tiny_1:GetIntrinsicModifierName()
    return "modifier_talent_tiny_1"
end
------------
function modifier_talent_tiny_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ALWAYS_ETHEREAL_ATTACK,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_OVERRIDE_ATTACK_MAGICAL,
        MODIFIER_PROPERTY_OVERRIDE_ATTACK_DAMAGE,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_talent_tiny_1:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end
    if not parent:HasModifier("modifier_tiny_tree_grab_custom_tree") then return end

    event.target:AddNewModifier(parent, self:GetAbility(), "modifier_talent_tiny_1_debuff", {
        duration = self:GetAbility():GetSpecialValueFor("duration")
    })
end

function modifier_talent_tiny_1:GetModifierOverrideAttackDamage() 
    if not self:GetParent():HasModifier("modifier_tiny_tree_grab_custom_tree") then return end
    return 0 
end

function modifier_talent_tiny_1:GetModifierProcAttack_BonusDamage_Magical(keys)
    if not self:GetParent():HasModifier("modifier_tiny_tree_grab_custom_tree") then return end

    ApplyDamage({
        attacker = self:GetCaster(),
        victim = keys.target,
        damage = keys.original_damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })

    return 0
end

function modifier_talent_tiny_1:GetOverrideAttackMagical()
    if not self:GetParent():HasModifier("modifier_tiny_tree_grab_custom_tree") then return end
    return 1
end

function modifier_talent_tiny_1:GetAllowEtherealAttack()
    if not self:GetParent():HasModifier("modifier_tiny_tree_grab_custom_tree") then return end
    return 1
end

function modifier_talent_tiny_1:GetAbsoluteNoDamagePhysical()
    if not self:GetParent():HasModifier("modifier_tiny_tree_grab_custom_tree") then return end
    return 1
end
-------
function modifier_talent_tiny_1_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }
end

function modifier_talent_tiny_1_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_reduction")
end