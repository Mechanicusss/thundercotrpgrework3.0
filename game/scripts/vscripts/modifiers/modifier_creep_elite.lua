LinkLuaModifier("modifier_creep_elite", "modifiers/modifier_creep_elite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_creep_elite_cooldown", "modifiers/modifier_creep_elite", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

modifier_creep_elite = class(ItemBaseClass)
modifier_creep_elite_cooldown = class(ItemBaseClassDebuff)
------------------
function modifier_creep_elite:OnCreated()
    if not IsServer() then return end 

    local multi = 3

    local parent = self:GetParent()

    parent:SetRenderColor(255, 0, 0)
    parent:SetModelScale(parent:GetModelScale() * 1.25)
    parent:SetMaximumGoldBounty(parent:GetMaximumGoldBounty() * multi)
    parent:SetMinimumGoldBounty(parent:GetMaximumGoldBounty() * multi)
    parent:SetDeathXP(parent:GetDeathXP() * multi)

    self.abilities = {
        "creature_wave_silence",
        "creature_wave_taunt",
        "creep_wave_ministun",
        "creature_wave_solar_bind"
    }

    local randomAbility = self.abilities[RandomInt(1, #self.abilities)]

    if not parent:FindAbilityByName(randomAbility) then
        parent:AddAbility(randomAbility)
    end

    self:StartIntervalThink(2)
end

function modifier_creep_elite:OnIntervalThink()
    local parent = self:GetParent()

    if parent:GetAggroTarget() == nil then return end
 
    -- Ability casting logic --
    if self.target ~= nil and not self.target:IsNull() and #self.abilities > 0 then
        -- The unit will attempt to cast an ability on the target if the target is within 850 units
        if ((parent:GetAbsOrigin() - self.target:GetAbsOrigin()):Length2D() <= 850) then
            for _,name in ipairs(self.abilities) do
                local ability = parent:FindAbilityByName(name)
                if ability ~= nil and ability:IsCooldownReady() and not parent:IsSilenced() and not parent:IsStunned() and not parent:IsHexed()  then
                    local castTarget = nil

                    if bit.band(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) ~= 0 or bit.band(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_POINT) ~= 0 then
                        castTarget = self.target
                    end

                    if bit.band(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_NO_TARGET) ~= 0 then
                        castTarget = parent
                    end

                    -- Prevent friendly abilities from being cast on enemy heroes
                    -- Cast it on allies instead
                    if bit.band(ability:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_TEAM_FRIENDLY) ~= 0 then
                        local allies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
                            900, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                            FIND_CLOSEST, false)

                        for _,ally in ipairs(allies) do
                            if ally:IsAlive() then
                                castTarget = selectedAlly
                                break
                            end
                        end
                    end 

                    -- Don't cast it if it's autocast
                    if bit.band(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_AUTOCAST) ~= 0 then
                        castTarget = nil
                    end

                    if castTarget then
                        if string.match(ability:GetAbilityName(), "ice_blast_release") then
                            Timers:CreateTimer(1, function()
                                SpellCaster:Cast(ability, castTarget, true)
                            end)
                            break
                        else
                            SpellCaster:Cast(ability, castTarget, true)
                            break
                        end
                    end
                end
            end
        end
    end

    -- Targeting logic --
    if self.target ~= nil and not self.target:IsNull() then
        -- The target must be alive, not be attack immune
        if self.target:IsAlive() and not self.target:IsInvulnerable() and not self.target:IsUntargetableFrom(parent) then
        else
            self.target = nil
        end
    end

    -- We will continue to search for units even if there is a target already 
    -- to see if there's another target that is closer
    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and victim ~= self.target and not victim:HasModifier("modifier_wave_manager_fow_revealer") and not victim:HasModifier("modifier_chicken_ability_1_self_transmute") then
            if self.target ~= nil then
                local victimDistance = parent:GetRangeToUnit(victim)
                local currentTargetDistance = parent:GetRangeToUnit(self.target)

                -- If there is a unit that is closer to the unit than the current target,
                -- we change the target to be that unit instead
                if victimDistance < currentTargetDistance then
                    self.target = victim 
                    break
                end
            else
                self.target = victim 
                break
            end
        end
    end
end

function modifier_creep_elite:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_creep_elite:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.unit ~= parent then return end 

    local attacker = event.attacker

    if not attacker or attacker:IsNull() then return end 
    if not attacker:IsRealHero() then return end
    
    local cooldown = 30
    
    local chance = attacker:GenerateDropChance()

    -- Drops legendary hero gems
    if chance <= 5 then
        local legendaryHeroGems = {
            "item_socket_rune_legendary_drow_ranger_multishot",
            "item_socket_rune_legendary_drow_ranger_marksmanship",
            "item_socket_rune_legendary_medusa_split_shot",
            "item_socket_rune_legendary_faceless_void_time_lock",
            "item_socket_rune_legendary_faceless_void_chronosphere",
            "item_socket_rune_legendary_lina_light_strike_array",
            "item_socket_rune_legendary_tidehunter_anchor_smash",
            "item_socket_rune_legendary_axe_counter_helix",
            "item_socket_rune_legendary_axe_culling_blade",
            "item_socket_rune_legendary_luna_moon_beam",
            "item_socket_rune_legendary_lone_druid_bear",
        }

        local gemToDrop = legendaryHeroGems[RandomInt(1, #legendaryHeroGems)]

        local originalString = attacker:GetUnitName()
        local prefixToRemove = "npc_dota_hero_"

        -- Check if the string starts with the prefix
        if string.sub(originalString, 1, #prefixToRemove) == prefixToRemove then
            -- Remove the prefix
            local heroName = string.sub(originalString, #prefixToRemove + 1)

            local heroIsSame = false

            for _,legGem in ipairs(legendaryHeroGems) do
                if string.find(legGem, heroName) then
                    heroIsSame = true
                    break
                end
            end

            -- There's a 75% chance to drop a gem for the same hero as the player is using
            if heroIsSame then
                local matchingEntries = {}
        
                for _, gem in ipairs(legendaryHeroGems) do
                    if string.find(gem, heroName) then
                        table.insert(matchingEntries, gem)
                    end
                end

                -- Print the matching entries
                local increaseChanceToDropGems = {}
                for _, entry in ipairs(matchingEntries) do
                    table.insert(increaseChanceToDropGems, entry)
                end
                
                if RollPercentage(75) then
                    gemToDrop = increaseChanceToDropGems[RandomInt(1, #increaseChanceToDropGems)]
                end
            end
        end

        DropNeutralItemAtPositionForHero(gemToDrop, parent:GetAbsOrigin(), parent, 1, false)
    end

    -- Drops neutral items
    if attacker:HasModifier("modifier_creep_elite_cooldown") then return end

    if parent:GetLevel() < 50 then
        if chance <= ELITE_NEUTRAL_T1_CHANCE then
            local randomNeutral = NEUTRAL_ITEM_LIST_T1[RandomInt(1, #NEUTRAL_ITEM_LIST_T1)]
            DropNeutralItemAtPositionForHero(randomNeutral, parent:GetAbsOrigin(), parent, 1, false)

            attacker:AddNewModifier(attacker, nil, "modifier_creep_elite_cooldown", { duration = cooldown })
        end
    elseif parent:GetLevel() >= 100 and parent:GetLevel() < 300 then
        if chance <= ELITE_NEUTRAL_T2_CHANCE then
            local randomNeutral = NEUTRAL_ITEM_LIST_T2[RandomInt(1, #NEUTRAL_ITEM_LIST_T2)]
            DropNeutralItemAtPositionForHero(randomNeutral, parent:GetAbsOrigin(), parent, 1, false)

            attacker:AddNewModifier(attacker, nil, "modifier_creep_elite_cooldown", { duration = cooldown })
            return
        end 

        if chance <= ELITE_NEUTRAL_T1_CHANCE then
            local randomNeutral = NEUTRAL_ITEM_LIST_T1[RandomInt(1, #NEUTRAL_ITEM_LIST_T1)]
            DropNeutralItemAtPositionForHero(randomNeutral, parent:GetAbsOrigin(), parent, 1, false)

            attacker:AddNewModifier(attacker, nil, "modifier_creep_elite_cooldown", { duration = cooldown })
        end
    elseif parent:GetLevel() >= 300 then
        if chance <= ELITE_NEUTRAL_T3_CHANCE then
            local randomNeutral = NEUTRAL_ITEM_LIST_T3[RandomInt(1, #NEUTRAL_ITEM_LIST_T3)]
            DropNeutralItemAtPositionForHero(randomNeutral, parent:GetAbsOrigin(), parent, 1, false)

            attacker:AddNewModifier(attacker, nil, "modifier_creep_elite_cooldown", { duration = cooldown })
            return
        end

        if chance <= ELITE_NEUTRAL_T2_CHANCE then
            local randomNeutral = NEUTRAL_ITEM_LIST_T2[RandomInt(1, #NEUTRAL_ITEM_LIST_T2)]
            DropNeutralItemAtPositionForHero(randomNeutral, parent:GetAbsOrigin(), parent, 1, false)

            attacker:AddNewModifier(attacker, nil, "modifier_creep_elite_cooldown", { duration = cooldown })
            return
        end 
    end
end

function modifier_creep_elite:GetModifierExtraHealthPercentage()
    return 50
end

function modifier_creep_elite:GetModifierDamageOutgoing_Percentage()
    return 50
end

function modifier_creep_elite:GetModifierIncomingDamage_Percentage()
    return -50
end

function modifier_creep_elite:GetEffectName() return "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf" end
function modifier_creep_elite:GetTexture() return "wtf" end
function modifier_creep_elite:GetPriority() return 99 end