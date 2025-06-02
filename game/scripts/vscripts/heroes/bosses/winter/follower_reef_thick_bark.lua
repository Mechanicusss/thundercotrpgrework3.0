LinkLuaModifier("modifier_follower_reef_thick_bark", "heroes/bosses/winter/follower_reef_thick_bark", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

follower_reef_thick_bark = class(ItemBaseClass)
modifier_follower_reef_thick_bark = class(follower_reef_thick_bark)
-------------
function follower_reef_thick_bark:GetIntrinsicModifierName()
    return "modifier_follower_reef_thick_bark"
end

function modifier_follower_reef_thick_bark:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK, 
        MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK
    }
    return funcs
end

function modifier_follower_reef_thick_bark:GetModifierPhysical_ConstantBlock()
    return self:GetParent():GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("max_hp_block")/100)
end

function modifier_follower_reef_thick_bark:GetModifierMagical_ConstantBlock()
    return self:GetParent():GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("max_hp_block")/100)
end