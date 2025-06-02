LinkLuaModifier("modifier_boss_skafian", "bosses/skafian", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_skafian_follower", "bosses/skafian", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_skafian = class(BaseClass)
modifier_boss_skafian = class(boss_skafian)
modifier_boss_skafian_follower = class(boss_skafian)
--------------------
-- BOSS VARIABLES --
--------------------
BOSS_STAGE = 1
BOSS_MAX_STAGE = 3
PARTICLE_ID = nil

BOSS_NAME = "npc_dota_creature_30_boss"
--------------------
function boss_skafian:GetIntrinsicModifierName()
    return "modifier_boss_skafian"
end

function modifier_boss_skafian:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_STATUS_RESISTANCE
    }
    return funcs
end

function modifier_boss_skafian:AddCustomTransmitterData()
    return
    {
        status = self.fStatus,
    }
end

function modifier_boss_skafian:HandleCustomTransmitterData(data)
    if data.status ~= nil then
        self.fStatus = tonumber(data.status)
    end
end

function modifier_boss_skafian:InvokeStatusResistance()
    if IsServer() == true then
        self.fStatus = self.status

        self:SendBuffRefreshToClients()
    end
end

function modifier_boss_skafian:GetModifierStatusResistance()
    return self.fStatus
end

function modifier_boss_skafian:CheckState()
    local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true
    }

    return state
end

function modifier_boss_skafian:GetModifierProvidesFOWVision()
    return 1
end

function modifier_boss_skafian:OnTakeDamage(event)
    if not IsServer() then return end

    if event.unit ~= self.boss then return end

    self.canRegen = false
    if self.regenTimer ~= nil then
        Timers:RemoveTimer(self.regenTimer)
    end
    
    self.regenTimer = Timers:CreateTimer(10.0, function()
        self.canRegen = true
    end)
end

function modifier_boss_skafian:GetModifierHealthRegenPercentage()
    if self.canRegen and not self:GetParent():HasModifier("modifier_boss_skafian_lycanthropy_buff") then return 10 end
end

function modifier_boss_skafian:OnCreated(kv)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.boss = self:GetParent()
    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)
    self.canRegen = true
    self.regenTimer = nil

    local level = GetLevelFromDifficulty()

    -- Abilities --
    self.howl = self.boss:FindAbilityByName("boss_skafian_howl")
    if not self.boss:FindAbilityByName("boss_skafian_howl") then
        self.howl = self.boss:AddAbility("boss_skafian_howl")
    end

    self.wolfBite = self.boss:FindAbilityByName("boss_skafian_wolf_bite")
    if not self.boss:FindAbilityByName("boss_skafian_wolf_bite") then
        self.wolfBite = self.boss:AddAbility("boss_skafian_wolf_bite")
    end

    self.lycantrophy = self.boss:FindAbilityByName("boss_skafian_lycanthropy")
    if not self.boss:FindAbilityByName("boss_skafian_lycanthropy") then
        self.lycantrophy = self.boss:AddAbility("boss_skafian_lycanthropy")
    end

    -- Status Res --
    self.status = 25 * BOSS_STAGE
    self:InvokeStatusResistance()

    -- Making sure they get leveled up properly --
    Timers:CreateTimer(1.0, function()
        for i = 0, self.boss:GetAbilityCount() - 1 do
            local abil = self.boss:GetAbilityByIndex(i)
            if abil ~= nil then
                abil:SetLevel(level)
            end
        end
    end)

    self:StartIntervalThink(1.0)
end

function modifier_boss_skafian:OnIntervalThink()
    if not self.boss:IsAlive() then return end

    if self.boss:GetAggroTarget() == nil then return end
    if self.boss:IsSilenced() or self.boss:IsStunned() or self.boss:IsHexed() then return end

    if self.howl ~= nil and self.howl:IsCooldownReady() then
        SpellCaster:Cast(self.howl, self.boss, true)
    end

    if self.wolfBite ~= nil and self.wolfBite:IsCooldownReady() then
        local enemies = FindUnitsInRadius(self.boss:GetTeam(), self.boss:GetAbsOrigin(), nil,
            self.boss:Script_GetAttackRange()+100, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,enemy in ipairs(enemies) do
            if enemy:IsAlive() then
                SpellCaster:Cast(self.wolfBite, enemy, true)
                break
            end
        end
    end
end

function modifier_boss_skafian:IsFollower(follower)
    if not follower or follower:IsNull() then return false end

    if follower:GetUnitName() == "npc_dota_creature_1_crip" then return true end
    if follower:GetUnitName() == "npc_dota_creature_10_crip_2" then return true end
    if follower:GetUnitName() == "npc_dota_creature_10_crip_3" then return true end
    if follower:GetUnitName() == "npc_dota_creature_10_crip_4" then return true end
    if follower:GetUnitName() == "npc_dota_creature_30_crip" then return true end
    if follower:GetUnitName() == "npc_dota_creature_30_crip_2" then return true end
    if follower:GetUnitName() == "npc_dota_creature_30_crip_3" then return true end

    return false
end

function modifier_boss_skafian:ProgressToNext()
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
        if minion:GetUnitName() == "npc_dota_creature_1_crip" or 
        minion:GetUnitName() == "npc_dota_creature_10_crip_2" or 
        minion:GetUnitName() == "npc_dota_creature_10_crip_3" or 
        minion:GetUnitName() == "npc_dota_creature_10_crip_4" or 
        minion:GetUnitName() == "npc_dota_creature_30_crip_2" or 
        minion:GetUnitName() == "npc_dota_creature_30_crip_3" or 
        minion:GetUnitName() == "npc_dota_creature_30_crip" then
            minion:FindModifierByNameAndCaster("modifier_boss_skafian_follower", minion):ForceRefresh()
        end
    end

    EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", self:GetParent())
end

function modifier_boss_skafian:OnDeath(event)
    local victim = event.unit

    if victim ~= self:GetParent() then return end

    if not IsServer() then return end

    local respawnTime = BOSS_RESPAWN_TIME

    Timers:CreateTimer(respawnTime, function()
        if IsPvP() then return end
        
        CreateUnitByNameAsync(BOSS_NAME, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_skafian", {
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
                if hero:FindItemInAnyInventory("item_forest_soul") == nil and _G.autoPickup[hero:GetPlayerID()] ~= AUTOLOOT_ON_NO_SOULS then
                    --hero:AddItemByName("item_forest_soul")
                end
                
                hero:ModifyGold(10000, false, 0)
            end
        end
    end

    DropNeutralItemAtPositionForHero("item_forest_soul", victim:GetAbsOrigin(), victim, -1, true)

    -- Drops --
    if event.attacker:GenerateDropChance() <= 10.0 then
        local runes = {
            "item_socket_rune_legendary_adrenaline",
            "item_socket_rune_legendary_blood_rush",
        }

        local rune = runes[RandomInt(1, #runes)]

        DropNeutralItemAtPositionForHero(rune, victim:GetAbsOrigin(), victim, -1, true)
    end
    --
end
-----------
function modifier_boss_skafian_follower:DeclareFunctions(props)
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_boss_skafian_follower:OnCreated(kv)
    if not IsServer() then return end

    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)

    local parent = self:GetParent()

    self:OnRefresh()

    self.overgrowth = parent:FindAbilityByName("follower_skafian_overgrowth")
    self.leechSeed = parent:FindAbilityByName("follower_skafian_leech_seed")

    self:StartIntervalThink(1)
end

function modifier_boss_skafian_follower:CheckState()
    local state = {
        --[MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
    return state
end

function modifier_boss_skafian_follower:OnIntervalThink()
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

    -- Treant Overgrowth --
    if parent:GetUnitName() == "npc_dota_creature_10_crip_3" and self.overgrowth ~= nil then
        if self.overgrowth:IsCooldownReady() and not parent:IsSilenced() and not parent:IsStunned() and not parent:IsHexed() then
            SpellCaster:Cast(self.overgrowth, parent, true)
        end
    end

    -- Leech Seed --
    if parent:GetUnitName() == "npc_dota_creature_10_crip_4" and self.leechSeed ~= nil then
        if self.leechSeed:IsCooldownReady() and not parent:IsSilenced() and not parent:IsStunned() and not parent:IsHexed() then
            local enemies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
                650, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

            for _,enemy in ipairs(enemies) do
                if enemy:IsAlive() and not enemy:IsMagicImmune() then
                    SpellCaster:Cast(self.leechSeed, enemy, true)
                    break
                end
            end
        end
    end
end

function modifier_boss_skafian_follower:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local unitName = parent:GetUnitName()

    if event.unit ~= parent then return end

    local respawnTime = CREEP_RESPAWN_TIME

    if GetMapName() == "tcotrpg_1v1" then respawnTime = 15 end

    if FAST_BOSSES_VOTE_RESULT:upper() == "ENABLE" and IsCreepTCOTRPG(parent) then
        respawnTime = 1
    end

    if event.attacker:GenerateDropChance() <= 5 and (parent:GetUnitName() == "npc_dota_creature_1_crip" or parent:GetUnitName() == "npc_dota_creature_10_crip_2" or parent:GetUnitName() == "npc_dota_creature_10_crip_3" or parent:GetUnitName() == "npc_dota_creature_10_crip_4") then
        DropNeutralItemAtPositionForHero("item_bracer", parent:GetAbsOrigin(), parent, -1, true)
    end

    Timers:CreateTimer(respawnTime, function()        
      CreateUnitByNameAsync(unitName, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_skafian_follower", {
                posX = self.spawnPosition.x,
                posY = self.spawnPosition.y,
                posZ = self.spawnPosition.z,
            })

            if RollPercentage(ELITE_SPAWN_CHANCE) then
                unit:AddNewModifier(unit, nil, "modifier_creep_elite", {})
            end

            if modifier_boss_skafian:IsFollower(unit) then unit:AddNewModifier(unit, nil, "modifier_boss_skafian_follower", {}):ForceRefresh() end
        end)
    end)
end

function modifier_boss_skafian_follower:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()

    -- Mushroom Cloud (Poison Nova) --
    if parent:GetUnitName() == "npc_dota_creature_10_crip_2" then
        if not parent:FindAbilityByName("follower_skafian_mushroom_attack") then
            parent:AddAbility("follower_skafian_mushroom_attack")
        end
    end

    if parent:GetUnitName() == "npc_dota_creature_10_crip_3" then
        if not parent:FindAbilityByName("follower_skafian_overgrowth") then
            parent:AddAbility("follower_skafian_overgrowth")
        end
    end

    if parent:GetUnitName() == "npc_dota_creature_10_crip_4" then
        if not parent:FindAbilityByName("follower_skafian_healing") then
            parent:AddAbility("follower_skafian_healing")
        end

        if not parent:FindAbilityByName("follower_skafian_leech_seed") then
            parent:AddAbility("follower_skafian_leech_seed")
        end
    end

    local level = GetLevelFromDifficulty()

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
