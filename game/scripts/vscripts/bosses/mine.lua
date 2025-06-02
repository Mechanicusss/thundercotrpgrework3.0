LinkLuaModifier("modifier_boss_mine", "bosses/mine", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_mine_follower", "bosses/mine", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_mine = class(BaseClass)
modifier_boss_mine = class(boss_mine)
modifier_boss_mine_follower = class(boss_mine)
--------------------
-- BOSS VARIABLES --
--------------------
BOSS_STAGE = 1
BOSS_MAX_STAGE = 3
PARTICLE_ID = nil

BOSS_NAME = "npc_dota_creature_70_boss"
--------------------
function boss_mine:GetIntrinsicModifierName()
    return "modifier_boss_mine"
end

function modifier_boss_mine:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
    }
    return funcs
end

function modifier_boss_mine:GetActivityTranslationModifiers()
    return "run"
end

function modifier_boss_mine:AddCustomTransmitterData()
    return
    {
        status = self.fStatus,
    }
end

function modifier_boss_mine:HandleCustomTransmitterData(data)
    if data.status ~= nil then
        self.fStatus = tonumber(data.status)
    end
end

function modifier_boss_mine:InvokeStatusResistance()
    if IsServer() == true then
        self.fStatus = self.status

        self:SendBuffRefreshToClients()
    end
end

function modifier_boss_mine:GetModifierStatusResistance()
    return self.fStatus
end

function modifier_boss_mine:CheckState()
    local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true
    }

    return state
end

function modifier_boss_mine:GetModifierProvidesFOWVision()
    return 1
end

function modifier_boss_mine:OnTakeDamage(event)
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

function modifier_boss_mine:GetModifierHealthRegenPercentage()
    if self.canRegen then return 10 end
end

function modifier_boss_mine:OnCreated(kv)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.boss = self:GetParent()
    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)
    self.canRegen = true
    self.regenTimer = nil

    self.boss:AddItemByName("item_warlock_soul")

    local level = GetLevelFromDifficulty()

    self.status = 25 * BOSS_STAGE
    self:InvokeStatusResistance()

    self.devour = self.boss:FindAbilityByName("boss_doom_devour")

    -- Making sure they get leveled up properly --
    Timers:CreateTimer(1.0, function()
        for i = 0, self.boss:GetAbilityCount() - 1 do
            local abil = self.boss:GetAbilityByIndex(i)
            if abil ~= nil then
                abil:SetLevel(level)
            end
        end
    end)

    self:StartIntervalThink(1)
end

function modifier_boss_mine:OnIntervalThink()
    if self.boss:GetAggroTarget() == nil then return end

    -- Attempt to cast
    local target = self.boss:GetAggroTarget()
    if target then
        if self.devour and self.devour:GetLevel() > 0 then
            if self.devour:IsFullyCastable() and not self.boss:IsStunned() and not self.boss:IsSilenced() and not self.boss:IsHexed() and self.boss:GetLevel() > target:GetLevel() then
                if (target:GetAbsOrigin()-self.boss:GetAbsOrigin()):Length2D() <= self.devour:GetEffectiveCastRange(self.boss:GetAbsOrigin(), self.boss) then
                    SpellCaster:Cast(self.devour, target, true)
                end
            end
        end
    end
end

function modifier_boss_mine:IsFollower(follower)
    if not follower or follower:IsNull() then return false end

    if follower:GetUnitName() == "npc_dota_creature_70_crip" then return true end
    if follower:GetUnitName() == "npc_dota_creature_70_crip_2" then return true end

    return false
end

function modifier_boss_mine:ProgressToNext()
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
        if minion:GetUnitName() == "npc_dota_creature_70_crip" or
        minion:GetUnitName() == "npc_dota_creature_70_crip_2" then
            minion:FindModifierByNameAndCaster("modifier_boss_mine_follower", minion):ForceRefresh()
        end
    end

    EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", self:GetParent())
end

function modifier_boss_mine:OnDeath(event)
    if not IsServer() then return end

    local victim = event.unit

    if victim ~= self:GetParent() then return end

    local respawnTime = BOSS_RESPAWN_TIME

    Timers:CreateTimer(respawnTime, function()
        if IsPvP() then return end
        
        CreateUnitByNameAsync(BOSS_NAME, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_mine", {
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
                if hero:FindItemInAnyInventory("item_warlock_soul") == nil and _G.autoPickup[hero:GetPlayerID()] ~= AUTOLOOT_ON_NO_SOULS then
                    --hero:AddItemByName("item_warlock_soul")
                end
                
                hero:ModifyGold(25000, false, 0)
            end
        end
    end

    DropNeutralItemAtPositionForHero("item_warlock_soul", victim:GetAbsOrigin(), victim, -1, true)
end
-----------
function modifier_boss_mine_follower:DeclareFunctions(props)
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_boss_mine_follower:OnCreated(kv)
    if not IsServer() then return end

    local parent = self:GetParent()

    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)

    if parent:GetUnitName() == "npc_dota_creature_70_crip_2" then
        self.particle = ParticleManager:CreateParticle("particles/wk_arc_minion_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(self.particle, 0, parent:GetAbsOrigin())
    end

    self:StartIntervalThink(1.0)
end

function modifier_boss_mine_follower:CheckState()
    local state = {
        --[MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
    return state
end

function modifier_boss_mine_follower:OnIntervalThink()
    local parent = self:GetParent()

    if parent:IsAlive() then
        if _G.FinalGameWavesEnabled then
            Timers:CreateTimer(parent:entindex()/1000, function()
                UTIL_RemoveImmediate(parent)
            end)
            return
        end
    
        local infernalBlade = parent:FindAbilityByName("doom_follower_infernal_blade")
        if infernalBlade ~= nil then 
            if not infernalBlade:GetAutoCastState() and not parent:IsSilenced() then
                infernalBlade:ToggleAutoCast()
            end
        end
    end
end

function modifier_boss_mine_follower:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local unitName = parent:GetUnitName()

    if event.unit ~= parent then return end

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end

    local respawnTime = CREEP_RESPAWN_TIME

    if GetMapName() == "tcotrpg_1v1" then respawnTime = 15 end

    if FAST_BOSSES_VOTE_RESULT:upper() == "ENABLE" and IsCreepTCOTRPG(parent) then
        respawnTime = 1
    end

    --[[
    if IsCreepTCOTRPG(event.unit) then
        if RandomFloat(0.0, 100.0) <= _G.morplingPartChance then
            local weapons = {
                "item_piece",
                "item_piece2",
                "item_piece3",
                "item_piece4",
                "item_piece5",
            }
            local chosenDrop = RandomInt(1, #weapons)
            DropNeutralItemAtPositionForHero(weapons[chosenDrop], event.attacker:GetAbsOrigin(), event.attacker, 1, false)
        end
    end
    --]]

    Timers:CreateTimer(respawnTime, function()
      CreateUnitByNameAsync(unitName, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_mine_follower", {
                posX = self.spawnPosition.x,
                posY = self.spawnPosition.y,
                posZ = self.spawnPosition.z,
            })

            if RollPercentage(ELITE_SPAWN_CHANCE) then
                unit:AddNewModifier(unit, nil, "modifier_creep_elite", {})
            end

            if modifier_boss_mine:IsFollower(unit) then unit:AddNewModifier(unit, nil, "modifier_boss_mine_follower", {}):ForceRefresh() end
        end)
    end)
end

function modifier_boss_mine_follower:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()

    local level = GetLevelFromDifficulty()

    if parent:GetUnitName() == "npc_dota_creature_70_crip_2" then
        if not parent:FindAbilityByName("doom_follower_infernal_blade") then
            parent:AddAbility("doom_follower_infernal_blade") 
        end

        if not parent:FindAbilityByName("doom_follower_flaming_fists") then
            parent:AddAbility("doom_follower_flaming_fists") 
        end

        if not parent:FindAbilityByName("doom_follower_permanent_immolation") then
            parent:AddAbility("doom_follower_permanent_immolation") 
        end
    end

    -- Making sure they get leveled up properly --
    Timers:CreateTimer(1.0, function()
        for i = 0, parent:GetAbilityCount() - 1 do
            local abil = parent:GetAbilityByIndex(i)
            if abil ~= nil then
                abil:SetLevel(level)
                if abil:GetAbilityName() == "centaur_khan_endurance_aura_custom" then
                    abil:SetActivated(true)
                    abil:SetHidden(false)
                end
            end
        end
    end)
end
