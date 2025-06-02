LinkLuaModifier("modifier_item_socket_rune_legendary_luna_moon_beam", "modifiers/runes/heroes/luna/modifier_item_socket_rune_legendary_luna_moon_beam", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_item_socket_rune_legendary_luna_moon_beam = class(BaseClass)
----------------------------------------------------------------
function modifier_item_socket_rune_legendary_luna_moon_beam:OnCreated()
    self.radius = 1200
    self.damageIncreasePct = 100

    if not IsServer() then return end

    local parent = self:GetParent()

    local interval = 1 / parent:GetAttacksPerSecond(false)
    local maxLimit = 0.25

    if interval < maxLimit then interval = maxLimit end

    local moonBeam = parent:FindAbilityByName("luna_moon_beam_custom")

    Timers:CreateTimer(interval, function()
        if not self or self:IsNull() then return end 

        local interval = 1 / parent:GetAttacksPerSecond(false)

        if interval < maxLimit then interval = maxLimit end

        if not moonBeam or moonBeam:IsNull() then return 1 end
        if moonBeam:GetLevel() < 1 or not moonBeam:GetAutoCastState() then return 1 end

        self:FireBeam()

        return interval
    end)
end

function modifier_item_socket_rune_legendary_luna_moon_beam:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_socket_rune_legendary_luna_moon_beam:GetModifierTotalDamageOutgoing_Percentage(event)
    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    if not event.inflictor then return end
    if event.inflictor:GetAbilityName() ~= "luna_moon_beam_custom" then return end

    return self.damageIncreasePct
end

function modifier_item_socket_rune_legendary_luna_moon_beam:FireBeam()
    local parent = self:GetParent()

    if not parent:IsAlive() then return end
    if parent:PassivesDisabled() then return end

    local ability = self:GetAbility()

    local radius = self.radius

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