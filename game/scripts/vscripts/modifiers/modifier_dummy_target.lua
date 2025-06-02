LinkLuaModifier("modifier_dummy_target", "modifiers/modifier_dummy_target.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dummy_target_regen", "modifiers/modifier_dummy_target.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

dummy_target = class(ItemBaseClass)
modifier_dummy_target = class(dummy_target)
modifier_dummy_target_regen = class(dummy_target)
-----------------
function dummy_target:GetIntrinsicModifierName()
    return "modifier_dummy_target"
end
-----------------
function modifier_dummy_target:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, --GetModifierIncomingDamage_Percentage
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_PROPERTY_MIN_HEALTH
    }

    return funcs
end

function modifier_dummy_target:GetMinHealth()
    if IsBossTCOTRPG(self:GetParent()) then
        return 1
    else
        return self:GetParent():GetMaxHealth()
    end
end

function modifier_dummy_target:GetModifierProvidesFOWVision()
    return 1
end

function modifier_dummy_target:CanParentBeAutoAttacked()
    return false
end

function modifier_dummy_target:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(10)
end

function modifier_dummy_target:OnIntervalThink()
    local parent = self:GetParent()

    parent:AddNewModifier(parent, nil, "modifier_dummy_target_regen", {})
end

function modifier_dummy_target:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }
    return state
end

function modifier_dummy_target:GetModifierIncomingDamage_Percentage(event)
    if not IsServer() then return end

    self:GetParent():RemoveModifierByName("modifier_dummy_target_regen")
    
    --if not event.attacker:IsRealHero() and not IsSummonTCOTRPG(event.attacker) then return -99999 end
end

function modifier_dummy_target_regen:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_dummy_target_regen:OnIntervalThink()
    local parent = self:GetParent()

    parent:SetHealth(parent:GetMaxHealth())
end