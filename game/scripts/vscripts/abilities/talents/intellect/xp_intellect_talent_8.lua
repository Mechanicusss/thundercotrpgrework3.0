LinkLuaModifier("modifier_xp_intellect_talent_8", "abilities/talents/intellect/xp_intellect_talent_8", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_8 = class(ItemBaseClass)
modifier_xp_intellect_talent_8 = class(xp_intellect_talent_8)
-------------
function xp_intellect_talent_8:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_8"
end
-------------
function modifier_xp_intellect_talent_8:OnCreated()
end

function modifier_xp_intellect_talent_8:OnDestroy()
end

function modifier_xp_intellect_talent_8:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
    }
end

function modifier_xp_intellect_talent_8:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target

    if self:GetCaster() ~= attacker or not UnitIsNotMonkeyClone(attacker) then return end
    if not IsBossTCOTRPG(victim) and not IsCreepTCOTRPG(victim) then return end

    if event.damage_type == DAMAGE_TYPE_PHYSICAL then return end
    if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then return end

    local distance = (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D()
    if distance < 300 then return end

    if distance > 900 then
        distance = 900
    end

    local multiplier = (distance / 20)

    return multiplier
end