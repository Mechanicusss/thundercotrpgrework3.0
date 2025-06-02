LinkLuaModifier("modifier_lone_druid_destructive_claws_custom", "heroes/hero_lone_druid/lone_druid_destructive_claws_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

lone_druid_destructive_claws_custom = class(ItemBaseClass)
modifier_lone_druid_destructive_claws_custom = class(lone_druid_destructive_claws_custom)
-------------
function lone_druid_destructive_claws_custom:GetIntrinsicModifierName()
    return "modifier_lone_druid_destructive_claws_custom"
end
------------
function modifier_lone_druid_destructive_claws_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_lone_druid_destructive_claws_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker ~= parent then return end 

    local target = event.target 

    if not IsBossTCOTRPG(target) then return end 

    local talent = parent:FindAbilityByName("talent_lone_druid_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 2) then
        return
    end

    local ability = self:GetAbility()

    if not ability then return end 

    if ability:GetLevel() < 1 then return end

    if not ability:IsActivated() then return end

    return ability:GetSpecialValueFor("boss_damage_increase_pct")
end