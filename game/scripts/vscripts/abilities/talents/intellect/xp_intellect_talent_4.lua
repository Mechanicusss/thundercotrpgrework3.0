LinkLuaModifier("modifier_xp_intellect_talent_4", "abilities/talents/intellect/xp_intellect_talent_4", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_4 = class(ItemBaseClass)
modifier_xp_intellect_talent_4 = class(xp_intellect_talent_4)
-------------
function xp_intellect_talent_4:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_4"
end
-------------
function modifier_xp_intellect_talent_4:OnCreated()
end

function modifier_xp_intellect_talent_4:OnDestroy()
end

function modifier_xp_intellect_talent_4:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_xp_intellect_talent_4:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.damage_type == DAMAGE_TYPE_PHYSICAL then return end 
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end 
    if not event.inflictor then return end

    local chance = 5 * self:GetStackCount()
    
    if RollPercentage(chance) then
        return 100
    end
end