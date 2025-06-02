LinkLuaModifier("modifier_talent_tiny_2", "heroes/hero_tiny/talents/talent_tiny_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_tiny_2 = class(ItemBaseClass)
modifier_talent_tiny_2 = class(talent_tiny_2)
-------------
function talent_tiny_2:GetIntrinsicModifierName()
    return "modifier_talent_tiny_2"
end
------------
function modifier_talent_tiny_2:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    local fury = parent:FindAbilityByName("tiny_unleashed_fury_custom")
    if fury ~= nil then
        fury:SetActivated(true)
        fury:SetHidden(false)
        fury:SetLevel(1)
    end
end

function modifier_talent_tiny_2:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    local fury = parent:FindAbilityByName("tiny_unleashed_fury_custom")
    if fury ~= nil then
        fury:SetHidden(true)
        fury:SetActivated(false)
    end
end