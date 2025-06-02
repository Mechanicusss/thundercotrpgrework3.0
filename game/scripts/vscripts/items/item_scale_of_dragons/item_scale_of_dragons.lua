LinkLuaModifier("modifier_item_scale_of_dragons", "items/item_scale_of_dragons/item_scale_of_dragons", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_scale_of_dragons_debuff", "items/item_scale_of_dragons/item_scale_of_dragons", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDeBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_scale_of_dragons = class(ItemBaseClass)
modifier_item_scale_of_dragons = class(item_scale_of_dragons)
modifier_item_scale_of_dragons_debuff = class(ItemBaseClassDeBuff)
-------------
function item_scale_of_dragons:GetIntrinsicModifierName()
    return "modifier_item_scale_of_dragons"
end

function modifier_item_scale_of_dragons:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_scale_of_dragons:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    target:AddNewModifier(parent, self:GetAbility(), "modifier_item_scale_of_dragons_debuff", {
        duration = self:GetAbility():GetSpecialValueFor("duration")
    })
end
-------------
function modifier_item_scale_of_dragons_debuff:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(1)
end

function modifier_item_scale_of_dragons_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local damage = caster:GetAverageTrueAttackDamage(caster) * (self:GetAbility():GetSpecialValueFor("damage_from_attack")/100)

    ApplyDamage({
        victim = parent,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, parent, damage, nil)
end

function modifier_item_scale_of_dragons_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS   
    }
end

function modifier_item_scale_of_dragons_debuff:GetModifierPhysicalArmorBonus()
    return self:GetParent():GetPhysicalArmorBaseValue() * (self:GetAbility():GetSpecialValueFor("armor_reduction_pct")/100)
end

function modifier_item_scale_of_dragons_debuff:GetEffectName() return "particles/units/heroes/hero_shredder/shredder_flame_thrower_tree_afterburn.vpcf" end