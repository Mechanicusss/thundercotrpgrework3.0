LinkLuaModifier("modifier_lava_elemental_attack", "creeps/lava_elemental_attack", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lava_elemental_attack_debuff", "creeps/lava_elemental_attack", LUA_MODIFIER_MOTION_NONE)

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

lava_elemental_attack = class(ItemBaseClass)
modifier_lava_elemental_attack = class(lava_elemental_attack)
modifier_lava_elemental_attack_debuff = class(ItemBaseClassDebuff)
-------------
function lava_elemental_attack:GetIntrinsicModifierName()
    return "modifier_lava_elemental_attack"
end
-------------
function modifier_lava_elemental_attack:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_lava_elemental_attack:OnAttackLanded(event)
    if not IsServer() then return end 

    local caster = self:GetCaster()

    if caster ~= event.attacker then return end 

    local target = event.target 
    local ability = self:GetAbility()
    local duration = ability:GetSpecialValueFor("duration")

    local debuff = target:FindModifierByName("modifier_lava_elemental_attack_debuff")
    if not debuff then
        debuff = target:AddNewModifier(caster, ability, "modifier_lava_elemental_attack_debuff", {
            duration = duration
        })
    end

    if debuff then
        debuff:IncrementStackCount()
        debuff:ForceRefresh()
    end
end
---------------
function modifier_lava_elemental_attack_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
    }
end

function modifier_lava_elemental_attack_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_reduction") * self:GetStackCount()
end

function modifier_lava_elemental_attack_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res_reduction") * self:GetStackCount()
end