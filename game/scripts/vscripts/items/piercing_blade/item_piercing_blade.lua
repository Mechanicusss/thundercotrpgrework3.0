LinkLuaModifier("modifier_item_piercing_blade", "items/piercing_blade/item_piercing_blade", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_piercing_blade = class(ItemBaseClass)
item_piercing_blade2 = item_piercing_blade
item_piercing_blade3 = item_piercing_blade
item_piercing_blade4 = item_piercing_blade
item_piercing_blade5 = item_piercing_blade
modifier_item_piercing_blade = class(ItemBaseClass)
---
function item_piercing_blade:GetIntrinsicModifierName()
    return "modifier_item_piercing_blade"
end

function modifier_item_piercing_blade:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE
    }

    return funcs
end

function modifier_item_piercing_blade:GetModifierPreAttack_BonusDamage()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_piercing_blade:GetModifierProcAttack_BonusDamage_Pure(params)
    if IsServer() then
        -- get target
        local target = params.target if target==nil then target = params.unit end
        if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
            return 0
        end

        local ability = self:GetAbility()
        local attacker = self:GetParent()
        local total = attacker:GetAverageTrueAttackDamage(attacker) * ability:GetSpecialValueFor("attack_damage_to_pure_pct") * 0.01
        
        return total
    end
end