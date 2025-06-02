LinkLuaModifier("modifier_boss_reef", "bosses/reef", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_reef_follower", "bosses/reef", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_reef = class(BaseClass)
modifier_boss_reef = class(boss_reef)
modifier_boss_reef_follower = class(boss_reef)
--------------------
-- BOSS VARIABLES --
--------------------
BOSS_STAGE = 1
BOSS_MAX_STAGE = 3
PARTICLE_ID = nil

BOSS_NAME = "npc_dota_creature_80_boss"
--------------------
function boss_reef:GetIntrinsicModifierName()
    return "modifier_boss_reef"
end
---
function modifier_boss_reef:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_STATUS_RESISTANCE
    }
    return funcs
end

function modifier_boss_reef:AddCustomTransmitterData()
    return
    {
        status = self.fStatus,
    }
end

function modifier_boss_reef:HandleCustomTransmitterData(data)
    if data.status ~= nil then
        self.fStatus = tonumber(data.status)
    end
end

function modifier_boss_reef:InvokeStatusResistance()
    if IsServer() == true then
        self.fStatus = self.status

        self:SendBuffRefreshToClients()
    end
end

function modifier_boss_reef:GetModifierStatusResistance()
    return self.fStatus
end

function modifier_boss_reef:CheckState()
    local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true
    }

    return state
end

function modifier_boss_reef:GetModifierProvidesFOWVision()
    return 1
end

function modifier_boss_reef:OnTakeDamage(event)
    if not IsServer() then return end

    if event.unit ~= self.boss then return end

    self.canRegen = false
    if self.regenTimer ~= nil then
        Timers:RemoveTimer(self.regenTimer)
    end
    
    self.regenTimer = Timers:CreateTimer(5.0, function()
        self.canRegen = true
    end)
end

function modifier_boss_reef:GetModifierHealthRegenPercentage()
    if self.canRegen then return 10 end
end

function modifier_boss_reef:OnCreated(kv)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.boss = self:GetParent()
    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)
    self.canRegen = true
    self.regenTimer = nil

    local level = GetLevelFromDifficulty()

    self.status = 25 * BOSS_STAGE
    self:InvokeStatusResistance()

    if not self.boss:FindAbilityByName("boss_ice_wyvern_arctic_burn") then 
        self.boss:AddAbility("boss_ice_wyvern_arctic_burn")
    end

    if not self.boss:FindAbilityByName("boss_ice_wyvern_winters_curse") then 
        self.boss:AddAbility("boss_ice_wyvern_winters_curse") 
    end

    if not self.boss:FindAbilityByName("boss_ice_wyvern_splinter_blast") then 
        self.boss:AddAbility("boss_ice_wyvern_splinter_blast") 
    end

    if not self.boss:FindAbilityByName("boss_ice_wyvern_cold_embrace") then 
        self.boss:AddAbility("boss_ice_wyvern_cold_embrace") 
    end

    -- Making sure they get leveled up properly --
    Timers:CreateTimer(1.0, function()
        self.boss:AddItemByName("item_ultimate_scepter")
        self.boss:AddItemByName("item_aghanims_shard")

        for i = 0, self.boss:GetAbilityCount() - 1 do
            local abil = self.boss:GetAbilityByIndex(i)
            if abil ~= nil then
                abil:SetLevel(level)
            end
        end
    end)

    self:StartIntervalThink(1.0)
end

function modifier_boss_reef:OnIntervalThink()
    if self.boss:GetAggroTarget() == nil then return end

    local arcticBurn = self.boss:FindAbilityByName("boss_ice_wyvern_arctic_burn")
    if BOSS_STAGE >= 1 and arcticBurn ~= nil then 
        if not arcticBurn:GetToggleState() and not self.boss:IsSilenced() then
            arcticBurn:ToggleAbility()
        end
    end

    local wintersCurse = self.boss:FindAbilityByName("boss_ice_wyvern_winters_curse")
    local splinterBlast = self.boss:FindAbilityByName("boss_ice_wyvern_splinter_blast")
    local coldEmbrace = self.boss:FindAbilityByName("boss_ice_wyvern_cold_embrace")

    local enemiesNearby = FindUnitsInRadius(self.boss:GetTeam(), self.boss:GetAbsOrigin(), nil,
        self.boss:Script_GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,enemy in ipairs(enemiesNearby) do
        if enemy:IsAlive() then
            if wintersCurse ~= nil and wintersCurse:IsCooldownReady() and not self.boss:IsSilenced() and not self.boss:IsStunned() and not self.boss:IsHexed() then
                SpellCaster:Cast(wintersCurse, enemy, true)
            end

            if splinterBlast ~= nil and splinterBlast:IsCooldownReady() and not self.boss:IsSilenced() and not self.boss:IsStunned() and not self.boss:IsHexed() then
                SpellCaster:Cast(splinterBlast, enemy, true)
            end
        end
    end

    if self.boss:GetHealthPercent() <= 30 then
        if coldEmbrace ~= nil and coldEmbrace:IsCooldownReady() and not self.boss:IsSilenced() and not self.boss:IsStunned() and not self.boss:IsHexed() then
            SpellCaster:Cast(coldEmbrace, self.boss, true)
        end
    end
end

function modifier_boss_reef:IsFollower(follower)
    if not follower or follower:IsNull() then return false end

    if follower:GetUnitName() == "npc_dota_creature_130_crip2_death" then return true end
    if follower:GetUnitName() == "npc_dota_creature_130_crip1_death" then return true end
    if follower:GetUnitName() == "npc_dota_creature_130_crip3_death" then return true end
    if follower:GetUnitName() == "npc_dota_creature_130_crip4_death" then return true end
    if follower:GetUnitName() == "npc_dota_creature_130_crip5_death" then return true end

    return false
end

function modifier_boss_reef:ProgressToNext()
    if PARTICLE_ID ~= nil then
        ParticleManager:DestroyParticle(PARTICLE_ID, true)
        ParticleManager:ReleaseParticleIndex(PARTICLE_ID)
    end

    --todo: you also need to apply the new stage abilities to them when they respawn.
    --this just updates the currently spawned units.
    local followers = FindUnitsInRadius(self.boss:GetTeam(), self.boss:GetAbsOrigin(), nil,
        99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,minion in ipairs(followers) do
        if minion:GetUnitName() == "npc_dota_creature_130_crip2_death" or
        minion:GetUnitName() == "npc_dota_creature_130_crip1_death" or
        minion:GetUnitName() == "npc_dota_creature_130_crip3_death" or 
        minion:GetUnitName() == "npc_dota_creature_130_crip4_death" or 
        minion:GetUnitName() == "npc_dota_creature_130_crip5_death" then
            local mod = minion:FindModifierByNameAndCaster("modifier_boss_reef_follower", minion)
            if mod ~= nil then
                mod:ForceRefresh()
            end
        end
    end

    EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", self:GetParent())
end

function modifier_boss_reef:OnDeath(event)
    if not IsServer() then return end

    local victim = event.unit

    if victim ~= self:GetParent() then return end

    local respawnTime = BOSS_RESPAWN_TIME

    Timers:CreateTimer(respawnTime, function()
        if IsPvP() then return end
        
        CreateUnitByNameAsync(BOSS_NAME, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_reef", {
                posX = self.spawnPosition.x,
                posY = self.spawnPosition.y,
                posZ = self.spawnPosition.z,
            })
        end)
    end)

    if BOSS_STAGE < BOSS_MAX_STAGE then
        BOSS_STAGE = BOSS_STAGE + 1

        self.status = 25 * BOSS_STAGE
        self:InvokeStatusResistance()

        self:ProgressToNext()
    end

    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsTempestDouble() then
            if PlayerResource:GetConnectionState(hero:GetPlayerID()) == DOTA_CONNECTION_STATE_CONNECTED then
                if hero:FindItemInAnyInventory("item_elder_soul") == nil and _G.autoPickup[hero:GetPlayerID()] ~= AUTOLOOT_ON_NO_SOULS then
                    --hero:AddItemByName("item_elder_soul")
                end
                
                hero:ModifyGold(30000, false, 0)
            end
        end
    end

    DropNeutralItemAtPositionForHero("item_elder_soul", victim:GetAbsOrigin(), victim, -1, true)

    -- Drops --
    if event.attacker:GenerateDropChance() <= 10.0 then
        local runes = {
            "item_socket_rune_legendary_rejuvenation",
        }

        local rune = runes[RandomInt(1, #runes)]

        DropNeutralItemAtPositionForHero(rune, victim:GetAbsOrigin(), victim, -1, true)
    end
    --
end
-----------
function modifier_boss_reef_follower:DeclareFunctions(props)
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_boss_reef_follower:OnCreated(kv)
    if not IsServer() then return end

    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)

    self:StartIntervalThink(1.0)
end

function modifier_boss_reef_follower:CheckState()
    local state = {
        --[MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
    return state
end

function modifier_boss_reef_follower:OnIntervalThink()
    local parent = self:GetParent()

    if not parent:IsAlive() then return end

    if _G.FinalGameWavesEnabled then
        Timers:CreateTimer(parent:entindex()/1000, function()
            UTIL_RemoveImmediate(parent)
        end)
        return
    end
    
    if parent:GetAggroTarget() == nil then return end
    if parent:IsSilenced() or parent:IsStunned() or parent:IsHexed() then return end


end

function modifier_boss_reef_follower:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local unitName = parent:GetUnitName()

    if event.unit ~= parent then return end

    local respawnTime = CREEP_RESPAWN_TIME

    if GetMapName() == "tcotrpg_1v1" then respawnTime = 15 end

    if FAST_BOSSES_VOTE_RESULT:upper() == "ENABLE" and IsCreepTCOTRPG(parent) then
        respawnTime = 1
    end

    Timers:CreateTimer(respawnTime, function()
      CreateUnitByNameAsync(unitName, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_reef_follower", {
                posX = self.spawnPosition.x,
                posY = self.spawnPosition.y,
                posZ = self.spawnPosition.z,
            })

            if RollPercentage(ELITE_SPAWN_CHANCE) then
                unit:AddNewModifier(unit, nil, "modifier_creep_elite", {})
            end

            if modifier_boss_reef:IsFollower(unit) then unit:AddNewModifier(unit, nil, "modifier_boss_reef_follower", {}):ForceRefresh() end
        end)
    end)
end

function modifier_boss_reef_follower:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()

    local level = GetLevelFromDifficulty()

    if (parent:GetUnitName() == "npc_dota_creature_130_crip4_death" or parent:GetUnitName() == "npc_dota_creature_130_crip5_death") and not parent:FindAbilityByName("follower_reef_thick_bark") then
        self.thickBark = parent:AddAbility("follower_reef_thick_bark")
    end

    if parent:GetUnitName() == "npc_dota_creature_130_crip4_death" and not parent:FindAbilityByName("follower_reef_bleed") then
        self.bleed = parent:AddAbility("follower_reef_bleed")
    end

    if parent:GetUnitName() == "npc_dota_creature_130_crip5_death" and not parent:FindAbilityByName("follower_reef_entangling_treant") then
        --self.entangling = parent:AddAbility("follower_reef_entangling_treant")
    end

    if parent:GetUnitName() == "npc_dota_creature_130_crip5_death" and not parent:FindAbilityByName("follower_reef_slow") then
        self.reefSlow = parent:AddAbility("follower_reef_slow")
    end

    -- Making sure they get leveled up properly --
    Timers:CreateTimer(1.0, function()
        for i = 0, parent:GetAbilityCount() - 1 do
            local abil = parent:GetAbilityByIndex(i)
            if abil ~= nil then
                abil:SetLevel(level)
            end
        end
    end)
end
