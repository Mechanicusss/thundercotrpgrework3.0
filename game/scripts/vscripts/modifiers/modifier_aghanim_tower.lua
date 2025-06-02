-- Custom Twin Gate implementation requires use of the order filter
LinkLuaModifier("modifier_aghanim_tower", "modifiers/modifier_aghanim_tower.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_aghanim_tower = class(BaseClass)
modifier_aghanim_tower = class(modifier_aghanim_tower)
-------------
function modifier_aghanim_tower:GetIntrinsicModifierName()
    return "modifier_aghanim_tower"
end

function modifier_aghanim_tower:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_invulnerable")
end

function modifier_aghanim_tower:CheckState()
    return {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_PROVIDES_VISION] = false,
    }
end

function modifier_aghanim_tower:CanParentBeAutoAttacked()
    return false
end

function modifier_aghanim_tower:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION 
    }
end

function modifier_aghanim_tower:GetModifierProvidesFOWVision()
    return 0
end