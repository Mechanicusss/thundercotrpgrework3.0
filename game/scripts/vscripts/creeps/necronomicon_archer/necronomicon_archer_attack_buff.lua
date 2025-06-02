LinkLuaModifier("modifier_necronomicon_archer_attack_buff", "creeps/necronomicon_archer/necronomicon_archer_attack_buff", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

necronomicon_archer_attack_buff = class(ItemBaseClass)
modifier_necronomicon_archer_attack_buff = class(necronomicon_archer_attack_buff)
-------------
function necronomicon_archer_attack_buff:GetIntrinsicModifierName()
    return "modifier_necronomicon_archer_attack_buff"
end

function modifier_necronomicon_archer_attack_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
    }
    return funcs
end

function modifier_necronomicon_archer_attack_buff:GetModifierBaseAttackTimeConstant()
    return self:GetAbility():GetSpecialValueFor("fixed_bat")
end