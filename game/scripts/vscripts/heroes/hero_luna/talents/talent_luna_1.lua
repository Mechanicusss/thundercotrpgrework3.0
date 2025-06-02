LinkLuaModifier("modifier_talent_luna_1", "heroes/hero_luna/talents/talent_luna_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_luna_1 = class(ItemBaseClass)
modifier_talent_luna_1 = class(talent_luna_1)
-------------
function talent_luna_1:GetIntrinsicModifierName()
    return "modifier_talent_luna_1"
end
-------------
function modifier_talent_luna_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_talent_luna_1:GetModifierTotalDamageOutgoing_Percentage(event)
    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    if not event.inflictor then return end
    if event.inflictor:GetAbilityName() ~= "luna_moon_beam_custom" then return end

    self:GetAbility():GetSpecialValueFor("damage_increase_pct")
end

function modifier_talent_luna_1:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(3)
end

function modifier_talent_luna_1:OnIntervalThink()
    local parent = self:GetParent()

    if not parent:IsAlive() then return end
    if parent:PassivesDisabled() then return end

    local ability = self:GetAbility()

    local radius = ability:GetSpecialValueFor("radius")

    local beam = parent:FindAbilityByName("luna_moon_beam_custom")

    if not beam then return end
    if beam:GetLevel() < 1 then return end

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() or victim:IsInvulnerable() or not parent:CanEntityBeSeenByMyTeam(victim) then break end

        SpellCaster:Cast(beam, victim, false)

        -- Stacks --
        local motm = parent:FindAbilityByName("luna_might_of_the_moon_custom")
        if motm ~= nil then
            local buff = parent:FindModifierByName("modifier_luna_might_of_the_moon_custom_stacks")
            
            if not buff then
                buff = parent:AddNewModifier(parent, motm, "modifier_luna_might_of_the_moon_custom_stacks", {})
            end

            if buff then
                if buff:GetStackCount() < motm:GetSpecialValueFor("max_stacks") then
                    buff:IncrementStackCount()
                end

                if buff:GetStackCount() == motm:GetSpecialValueFor("max_stacks") then
                    motm:SetActivated(true)

                    if parent:HasScepter() and not parent:HasModifier("modifier_luna_might_of_the_moon_custom_scepter") then
                        parent:AddNewModifier(parent, motm, "modifier_luna_might_of_the_moon_custom_scepter", {
                            duration = motm:GetSpecialValueFor("scepter_duration")
                        })
                    end
                end

                buff:ForceRefresh()
            end

            --- Damage 
            local bonusDamage = parent:FindModifierByName("modifier_luna_might_of_the_moon_custom_damage")

            if not bonusDamage then
                bonusDamage = parent:AddNewModifier(parent, motm, "modifier_luna_might_of_the_moon_custom_damage", {
                    duration = motm:GetSpecialValueFor("duration")
                })
            end

            if bonusDamage then
                if bonusDamage:GetStackCount() < motm:GetSpecialValueFor("max_stacks") then
                    bonusDamage:IncrementStackCount()
                end
                
                bonusDamage:ForceRefresh()
            end
        end
        break
    end
end