LinkLuaModifier("modifier_xp_strength_talent_4", "abilities/talents/strength/xp_strength_talent_4", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_strength_talent_4_magical", "abilities/talents/strength/xp_strength_talent_4", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_strength_talent_4_physical", "abilities/talents/strength/xp_strength_talent_4", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_strength_talent_4 = class(ItemBaseClass)
modifier_xp_strength_talent_4 = class(xp_strength_talent_4)
modifier_xp_strength_talent_4_magical = class(ItemBaseClassBuff)
modifier_xp_strength_talent_4_physical = class(ItemBaseClassBuff)
-------------
function xp_strength_talent_4:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_4"
end
-------------
function modifier_xp_strength_talent_4:OnCreated()
end

function modifier_xp_strength_talent_4:OnDestroy()
end

function modifier_xp_strength_talent_4:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_xp_strength_talent_4:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit or parent == event.attacker then return end 

    if not IsCreepTCOTRPG(event.attacker) and not IsBossTCOTRPG(event.attacker) then return end 

    if parent:HasModifier("modifier_xp_strength_talent_4_physical") or parent:HasModifier("modifier_xp_strength_talent_4_magical") then return end

    if event.damage_type == DAMAGE_TYPE_PHYSICAL then
        local mod = parent:AddNewModifier(parent, nil, "modifier_xp_strength_talent_4_physical", {
            duration = 3
        })

        if mod ~= nil then
            mod:SetStackCount(self:GetStackCount())
        end
    end

    if event.damage_type == DAMAGE_TYPE_MAGICAL then
        local mod = parent:AddNewModifier(parent, nil, "modifier_xp_strength_talent_4_magical", {
            duration = 3
        })

        if mod ~= nil then
            mod:SetStackCount(self:GetStackCount())
        end
    end
end
---------------
function modifier_xp_strength_talent_4_physical:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_xp_strength_talent_4_physical:GetModifierPhysicalArmorBonus()
    return self:GetParent():GetStrength() * ((0.5/100) * self:GetStackCount())
end
---------------
function modifier_xp_strength_talent_4_magical:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
end

function modifier_xp_strength_talent_4_magical:GetModifierMagicalResistanceBonus()
    return self:GetParent():GetStrength() * ((0.5/100) * self:GetStackCount())
end