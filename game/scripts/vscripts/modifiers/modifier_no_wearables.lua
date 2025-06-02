LinkLuaModifier("modifier_no_wearables", "modifiers/modifier_no_wearables", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

no_wearables = class(ItemBaseClass)
modifier_no_wearables = class(no_wearables)

-----------------
function no_wearables:GetIntrinsicModifierName()
    return "modifier_no_wearables"
end
-----------------
function modifier_no_wearables:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_PRESERVE_PARTICLES_ON_MODEL_CHANGE 
    }

    return funcs
end

function modifier_no_wearables:OnCreated(props)
    if not IsServer() then return end

    self.mdl = props.mdl

    HideWearables(self:GetParent())
end

function modifier_no_wearables:GetModifierModelChange()
    return self.mdl
end


function modifier_no_wearables:PreserveParticlesOnModelChanged()
    return 0
end
