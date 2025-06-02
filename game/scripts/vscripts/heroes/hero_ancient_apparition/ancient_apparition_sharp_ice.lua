LinkLuaModifier("modifier_ancient_apparition_sharp_ice", "heroes/hero_ancient_apparition/ancient_apparition_sharp_ice", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

ancient_apparition_sharp_ice = class(ItemBaseClass)
modifier_ancient_apparition_sharp_ice = class(ancient_apparition_sharp_ice)
-------------
function ancient_apparition_sharp_ice:GetIntrinsicModifierName()
    return "modifier_ancient_apparition_sharp_ice"
end

function ancient_apparition_sharp_ice:GetCooldown(level)
    if self:GetCaster():HasModifier("modifier_ancient_apparition_frozen_time_scepter_buff") then
        return 0
    end

    local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_ancient_apparition_5_custom")
    if talent ~= nil then
        if talent:GetLevel() > 0 then
            return self.BaseClass.GetCooldown(self, level) - self:GetCaster():FindAbilityByName("special_bonus_unique_ancient_apparition_5_custom"):GetSpecialValueFor("value")
        end
    end

    return self.BaseClass.GetCooldown(self, level) or 0
end
------------------
function modifier_ancient_apparition_sharp_ice:DeclareFunctions()
    local funcs = {
         MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
    return funcs
end

function modifier_ancient_apparition_sharp_ice:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent or event.target == parent then return end
    if not event.inflictor then return end
    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    ability:UseResources(false, false, false, true)

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
        event.target,
        event.damage * ability:GetSpecialValueFor("crit_multiplier"),
        nil
    )

    return ability:GetSpecialValueFor("crit_multiplier") * 100
end
---------
