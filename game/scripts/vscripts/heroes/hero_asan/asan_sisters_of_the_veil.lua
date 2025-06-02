LinkLuaModifier("modifier_asan_sisters_of_the_veil", "heroes/hero_asan/asan_sisters_of_the_veil", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

asan_sisters_of_the_veil = class(ItemBaseClass)
modifier_asan_sisters_of_the_veil = class(asan_sisters_of_the_veil)
-------------
function asan_sisters_of_the_veil:GetIntrinsicModifierName()
    return "modifier_asan_sisters_of_the_veil"
end

function modifier_asan_sisters_of_the_veil:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_asan_sisters_of_the_veil:GetModifierIncomingDamage_Percentage(event)
    if event.attacker ~= self:GetParent() and event.target == self:GetParent() and (self:GetAbility():IsCooldownReady()) then
        local chance = self:GetAbility():GetSpecialValueFor("chance")

        local talent = self:GetParent():FindAbilityByName("special_bonus_unique_asan_3_custom")
    
        if talent ~= nil and talent:GetLevel() > 0 then
            chance = chance + talent:GetSpecialValueFor("value")
        end

        if RandomInt(1,100)<=chance then
            if IsServer() then
                self:GetParent():PerformAttack(
                    event.attacker,
                    true,
                    true,
                    true,
                    true,
                    false,
                    false,
                    true
                )

                SendOverheadEventMessage(
                    nil,
                    OVERHEAD_ALERT_MISS,
                    self:GetParent(),
                    1,
                    nil
                )

                local talent = self:GetParent():FindAbilityByName("special_bonus_unique_asan_6_custom")
    
                if talent ~= nil and talent:GetLevel() > 0 then
                    event.attacker:AddNewModifier(self:GetParent(), nil, "modifier_stunned", {
                        duration = talent:GetSpecialValueFor("value")
                    })
                end

                self:GetAbility():UseResources(false, false, false, true)
            end

            return -100
        end
    end
end