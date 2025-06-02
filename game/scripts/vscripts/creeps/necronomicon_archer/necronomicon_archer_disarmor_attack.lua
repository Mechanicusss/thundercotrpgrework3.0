LinkLuaModifier("modifier_necronomicon_archer_disarmor_attack", "creeps/necronomicon_archer/necronomicon_archer_disarmor_attack", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necronomicon_archer_disarmor_attack_debuff", "creeps/necronomicon_archer/necronomicon_archer_disarmor_attack", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

necronomicon_archer_disarmor_attack = class(ItemBaseClass)
modifier_necronomicon_archer_disarmor_attack = class(necronomicon_archer_disarmor_attack)
modifier_necronomicon_archer_disarmor_attack_debuff = class(ItemBaseClassDebuff)
-------------
function necronomicon_archer_disarmor_attack:GetIntrinsicModifierName()
    return "modifier_necronomicon_archer_disarmor_attack"
end

function modifier_necronomicon_archer_disarmor_attack:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
    return funcs
end

function modifier_necronomicon_archer_disarmor_attack:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker

    if self:GetParent() ~= attacker then
        return
    end

    --if not self:GetAbility():IsCooldownReady() then return end

    local debuff = event.target:FindModifierByName("modifier_necronomicon_archer_disarmor_attack_debuff")
    if not debuff then
        debuff = event.target:AddNewModifier(attacker, self:GetAbility(), "modifier_necronomicon_archer_disarmor_attack_debuff", {
            duration = self:GetAbility():GetSpecialValueFor("duration")
        })
    end

    if debuff then
        if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end

    --self:GetAbility():UseResources(false, false, true)
end
----
function modifier_necronomicon_archer_disarmor_attack_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
    return funcs
end

function modifier_necronomicon_archer_disarmor_attack_debuff:GetModifierPhysicalArmorBonus()
    if not self:GetAbility() or self:GetAbility() == nil then self:Destroy() return end
    return self:GetAbility():GetSpecialValueFor("disarmor") * self:GetStackCount()
end

function modifier_necronomicon_archer_disarmor_attack_debuff:GetAttributes()
   return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_necronomicon_archer_disarmor_attack_debuff:GetEffectName()
    return "particles/items3_fx/star_emblem_brokenshield.vpcf"
end

function modifier_necronomicon_archer_disarmor_attack_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end