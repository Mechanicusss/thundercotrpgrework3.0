LinkLuaModifier("tower_attack_modifier", "tower_attack", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tower_attack_debuff", "tower_attack", LUA_MODIFIER_MOTION_NONE)

local BaseTowerAttack = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local ModifierClassDebuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    RemoveOnDeath = function(self) return true end
}

tower_attack = class({})
tower_attack_modifier = class(BaseTowerAttack)
modifier_tower_attack_debuff = class(ModifierClassDebuff)

function tower_attack:GetIntrinsicModifierName()
    return "tower_attack_modifier"
end

function tower_attack_modifier:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }

    return funcs
end

function tower_attack_modifier:GetModifierAttackSpeedBonus_Constant()
    return 100
end

function tower_attack_modifier:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local target = event.target
    local attacker = event.attacker

    if (attacker ~= parent) or (not target) or (target:IsNull()) then
        return
    end

    if target:GetHealth() <= 1 then return end

    ApplyDamage({
        victim = target, 
        attacker = attacker, 
        damage = (target:GetMaxHealth() * 0.09), 
        damage_type = DAMAGE_TYPE_PURE
    })

    if target:HasModifier("modifier_tower_attack_debuff") == false then
        target:AddNewModifier(target, nil, "modifier_tower_attack_debuff", { duration = 12 });
    else
        target:SetModifierStackCount("modifier_tower_attack_debuff", target, (target:GetModifierStackCount("modifier_tower_attack_debuff", target) + 1))
        target:FindModifierByName("modifier_tower_attack_debuff"):ForceRefresh()
    end
end

function tower_attack_modifier:CheckState()
    local states = {
        [MODIFIER_STATE_CANNOT_MISS] = true
    }

    return states
end

function modifier_tower_attack_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BASE_PERCENTAGE, --GetModifierPhysicalArmorBase_Percentage (%)
        MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_tower_attack_debuff:OnDeath(event)
    if self:GetParent() ~= event.unit then
        return
    end

    self:GetParent():RemoveModifierByName("modifier_tower_attack_debuff")
end

function modifier_tower_attack_debuff:GetModifierPhysicalArmorBonus(event)
    local target = self:GetParent()

    return target:GetModifierStackCount("modifier_tower_attack_debuff", target) * - 1.5
end

function modifier_tower_attack_debuff:GetModifierPhysicalArmorBase_Percentage(event)
    local target = self:GetParent()

    return 100 - math.abs(target:GetModifierStackCount("modifier_tower_attack_debuff", target) * - 1.5)
end

function modifier_tower_attack_debuff:GetAttributes()
    local funcs = {
        MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
    }

    return funcs
end