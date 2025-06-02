LinkLuaModifier("modifier_boss_spider", "bosses/spider", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spider_follower", "bosses/spider", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spider_follower_web_ai", "bosses/spider", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spider_follower_web_spider_ai", "bosses/spider", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spider_follower_web_spider_ai_detonating", "bosses/spider", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassAI = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_spider = class(BaseClass)
modifier_boss_spider = class(boss_spider)
modifier_boss_spider_follower = class(boss_spider)
modifier_boss_spider_follower_web_ai = class(BaseClassAI)
modifier_boss_spider_follower_web_spider_ai = class(BaseClassAI)
modifier_boss_spider_follower_web_spider_ai_detonating = class(BaseClassAI)
--------------------
-- BOSS VARIABLES --
--------------------
BOSS_STAGE = 1
BOSS_MAX_STAGE = 3
PARTICLE_ID = nil
HAS_SPIN_WEB = false

BOSS_NAME = "npc_dota_creature_80_boss"
--------------------
function boss_spider:GetIntrinsicModifierName()
    return "modifier_boss_spider"
end

function modifier_boss_spider:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_STATUS_RESISTANCE
    }
    return funcs
end

function modifier_boss_spider:AddCustomTransmitterData()
    return
    {
        status = self.fStatus,
    }
end

function modifier_boss_spider:HandleCustomTransmitterData(data)
    if data.status ~= nil then
        self.fStatus = tonumber(data.status)
    end
end

function modifier_boss_spider:InvokeStatusResistance()
    if IsServer() == true then
        self.fStatus = self.status

        self:SendBuffRefreshToClients()
    end
end

function modifier_boss_spider:GetModifierStatusResistance()
    return self.fStatus
end

function modifier_boss_spider:CheckState()
    local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true
    }

    return state
end

function modifier_boss_spider:GetModifierProvidesFOWVision()
    return 1
end

function modifier_boss_spider:OnTakeDamage(event)
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

function modifier_boss_spider:GetModifierHealthRegenPercentage()
    if self.canRegen then return 10 end
end

function modifier_boss_spider:OnCreated(kv)
    self:SetHasCustomTransmitterData(true)
    
    if not IsServer() then return end

    self.boss = self:GetParent()
    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)
    self.canRegen = true
    self.regenTimer = nil

    local level = GetLevelFromDifficulty()

    -- Abilities --
    self.poisonBite = self.boss:FindAbilityByName("boss_spider_poison_bite")
    if not self.boss:FindAbilityByName("boss_spider_poison_bite") then
        self.poisonBite = self.boss:AddAbility("boss_spider_poison_bite")
    end

    self.poisonBspinWebite = self.boss:FindAbilityByName("boss_spider_spin_web")
    if not self.boss:FindAbilityByName("boss_spider_spin_web") then
        self.spinWeb = self.boss:AddAbility("boss_spider_spin_web")
    end

    self.silkenBola = self.boss:FindAbilityByName("boss_spider_silken_bola")
    if not self.boss:FindAbilityByName("boss_spider_silken_bola") then
        self.silkenBola = self.boss:AddAbility("boss_spider_silken_bola")
    end

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

    -- Spin her web only once --
    if self.spinWeb ~= nil and not HAS_SPIN_WEB then
        SpellCaster:Cast(self.spinWeb, self.boss, true)
        HAS_SPIN_WEB = true
    end
    --

    self:StartIntervalThink(1.0)
end

function modifier_boss_spider:OnIntervalThink()
    if not self.boss:IsAlive() then return end
    
    if self.boss:GetAggroTarget() == nil then return end
    if self.boss:IsSilenced() or self.boss:IsStunned() or self.boss:IsHexed() then return end

    if self.silkenBola ~= nil and self.silkenBola:IsCooldownReady() then
        SpellCaster:Cast(self.silkenBola, self.boss, true)
    end
end

function modifier_boss_spider:IsFollower(follower)
    if not follower or follower:IsNull() then return false end

    if follower:GetUnitName() == "npc_dota_creature_40_crip" then return true end
    if follower:GetUnitName() == "npc_dota_creature_40_crip_2" then return true end
    if follower:GetUnitName() == "npc_dota_creature_40_crip_3" then return true end
    if follower:GetUnitName() == "npc_dota_creature_40_crip_4" then return true end
    if follower:GetUnitName() == "npc_dota_creature_40_crip_5" then return true end
    if follower:GetUnitName() == "npc_dota_creature_40_crip_6" then return true end
    if follower:GetUnitName() == "npc_dota_creature_40_crip_10" then return true end

    return false
end

function modifier_boss_spider:ProgressToNext()
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
        if minion:GetUnitName() == "npc_dota_creature_40_crip" or
        minion:GetUnitName() == "npc_dota_creature_40_crip_2" or
        minion:GetUnitName() == "npc_dota_creature_40_crip_3" or
        minion:GetUnitName() == "npc_dota_creature_40_crip_4" or
        minion:GetUnitName() == "npc_dota_creature_40_crip_5" or
        minion:GetUnitName() == "npc_dota_creature_40_crip_6" or
        minion:GetUnitName() == "npc_dota_creature_40_crip_10" then
            if minion ~= nil then
                local mod = minion:FindModifierByNameAndCaster("modifier_boss_spider_follower", minion)
                if mod ~= nil then
                    mod:ForceRefresh()
                end
            end
        end
    end

    EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", self:GetParent())
end

function modifier_boss_spider:OnDeath(event)
    if not IsServer() then return end

    local victim = event.unit

    if victim ~= self:GetParent() then return end

    local respawnTime = BOSS_RESPAWN_TIME

    Timers:CreateTimer(respawnTime, function()
        if IsPvP() then return end
        
        CreateUnitByNameAsync(BOSS_NAME, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_spider", {
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

    if RollPercentage(3) and not _G.ItemDroppedAsanBlade3 then
        local drop = DropNeutralItemAtPositionForHero("item_asan_dagger_3", victim:GetAbsOrigin(), victim, -1, true)
        drop:GetContainedItem():SetStacksWithOtherOwners(true)
        _G.ItemDroppedAsanBlade3 = true
    end

    -- Drops --
    if event.attacker:GenerateDropChance() <= 10.0 then
        local runes = {
            "item_socket_rune_legendary_evasive_architect",
        }

        local rune = runes[RandomInt(1, #runes)]

        DropNeutralItemAtPositionForHero(rune, victim:GetAbsOrigin(), victim, -1, true)
    end
    --
end
-----------
function modifier_boss_spider_follower:DeclareFunctions(props)
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_boss_spider_follower:OnCreated(kv)
    if not IsServer() then return end

    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)

    self.respawnTimer = nil

    local parent = self:GetParent()
    if parent:GetUnitName() == "npc_dota_creature_40_crip_2" or parent:GetUnitName() == "npc_dota_creature_40_crip_10" then
        parent:AddNewModifier(parent, self:GetAbility(), "modifier_boss_spider_follower_web_ai", {})
    end

    self:StartIntervalThink(1)
end

function modifier_boss_spider_follower:CheckState()
    local state = {
        --[MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
    return state
end

function modifier_boss_spider_follower:OnIntervalThink()
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

function modifier_boss_spider_follower:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local unitName = parent:GetUnitName()

    if event.unit ~= parent then return end

    local respawnTime = CREEP_RESPAWN_TIME

    if GetMapName() == "tcotrpg_1v1" then respawnTime = 15 end

    if FAST_BOSSES_VOTE_RESULT:upper() == "ENABLE" and IsCreepTCOTRPG(parent) and parent:GetUnitName() ~= "npc_dota_creature_40_crip_10" and parent:GetUnitName() ~= "npc_dota_creature_40_crip_2" then
        respawnTime = 1
    end

    if self.respawnTimer ~= nil then return end 

    self.respawnTimer = Timers:CreateTimer(respawnTime, function()
      CreateUnitByNameAsync(unitName, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            self.respawnTimer = nil

            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_spider_follower", {
                posX = self.spawnPosition.x,
                posY = self.spawnPosition.y,
                posZ = self.spawnPosition.z,
            })

            if RollPercentage(ELITE_SPAWN_CHANCE) and unit:GetUnitName() ~= "npc_dota_creature_40_crip_2" and unit:GetUnitName() ~= "npc_dota_creature_40_crip_10" then
                unit:AddNewModifier(unit, nil, "modifier_creep_elite", {})
            end

            if modifier_boss_spider:IsFollower(unit) then unit:AddNewModifier(unit, nil, "modifier_boss_spider_follower", {}):ForceRefresh() end
        end)
    end)
end

function modifier_boss_spider_follower:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()

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
------------------------------
function modifier_boss_spider_follower_web_ai:OnCreated()
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    local interval = RandomInt(2, 4) -- Gives it some variety, so they wont spawn at the same time every time

    self:StartIntervalThink(interval)
end

function modifier_boss_spider_follower_web_ai:OnIntervalThink()
    local parent = self:GetParent()

    if parent:GetUnitName() == "npc_dota_creature_40_crip_10" then return end -- Don't spawn spiders from the trapped ogres 

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        700, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #victims < 1 then return end

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and parent:CanEntityBeSeenByMyTeam(victim) then
            self:SpawnSpider(victim)
            break
        end
    end
end

function modifier_boss_spider_follower_web_ai:SpawnSpider(target)
    if not target then return end

    local pos = target:GetAbsOrigin()

    CreateUnitByNameAsync("npc_dota_creature_40_crip_3", self.parent:GetAbsOrigin(), true, nil, nil, self.parent:GetTeamNumber(), function(unit)
        FindClearSpaceForUnit(unit, self.parent:GetAbsOrigin(), false)
        --Async is faster and will help reduce stutter
        unit:AddNewModifier(unit, self.ability, "modifier_boss_spider_follower_web_spider_ai", {
            target = target:entindex(),
            duration = 3
        })

        EmitSoundOn("Hero_Broodmother.SpawnSpiderlingsCast", unit)
    end)
end

function modifier_boss_spider_follower_web_ai:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_boss_spider_follower_web_ai:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local unitName = parent:GetUnitName()

    if event.unit ~= parent then return end

    if unitName ~= "npc_dota_creature_40_crip_10" then return end 

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)

    EmitSoundOn("Hero_Broodmother.SpawnSpiderlings", parent)

    -- We spawn spiders when the ogre-spidersacks are killed
    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
        700, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    if #victims < 1 then return end

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and parent:CanEntityBeSeenByMyTeam(victim) then
            local numSpiders = RandomInt(2,5)
            for i = 1, numSpiders, 1 do
                self:SpawnSpider(victim)
            end

            break
        end
    end
end

function modifier_boss_spider_follower_web_ai:GetAbsoluteNoDamagePhysical( params )
    return 1
end

function modifier_boss_spider_follower_web_ai:GetAbsoluteNoDamageMagical( params )
    return 1
end

function modifier_boss_spider_follower_web_ai:GetAbsoluteNoDamagePure( params )
    return 1
end

function modifier_boss_spider_follower_web_ai:OnTakeDamage(params)
    if IsServer() then
        if self:GetParent() == params.unit then
            local nDamage = 0
            if params.attacker then
                local bDeathWard = params.attacker:FindModifierByName( "modifier_aghsfort_witch_doctor_death_ward" ) ~= nil
                local bValidAttacker = params.attacker:IsRealHero() or bDeathWard
                if not bValidAttacker then
                    return 0
                end
            
                nDamage = 1

                self:GetParent():ModifyHealth( self:GetParent():GetHealth() - nDamage, nil, true, 0 )
            end
        end
    end

    return 0
end

function modifier_boss_spider_follower_web_ai:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }   

    return state
end

function modifier_boss_spider_follower_web_ai:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent:IsAlive() then
        parent:ForceKill(false)
    end

    parent:AddNoDraw()
end
--------------------------
function modifier_boss_spider_follower_web_spider_ai:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_boss_spider_follower_web_spider_ai:GetAbsoluteNoDamagePhysical( params )
    return 1
end

function modifier_boss_spider_follower_web_spider_ai:GetAbsoluteNoDamageMagical( params )
    return 1
end

function modifier_boss_spider_follower_web_spider_ai:GetAbsoluteNoDamagePure( params )
    return 1
end

function modifier_boss_spider_follower_web_spider_ai:OnTakeDamage(params)
    if IsServer() then
        if self:GetParent() == params.unit then
            local nDamage = 0
            if params.attacker then
                local bDeathWard = params.attacker:FindModifierByName( "modifier_aghsfort_witch_doctor_death_ward" ) ~= nil
                local bValidAttacker = params.attacker:IsRealHero() or bDeathWard
                if not bValidAttacker then
                    return 0
                end
            
                nDamage = 1

                self:GetParent():ModifyHealth( self:GetParent():GetHealth() - nDamage, nil, true, 0 )
            end
        end
    end

    return 0
end

function modifier_boss_spider_follower_web_spider_ai:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.unit then return end

    self.bKilled = true

    if event.attacker:GenerateDropChance() <= 2.5 then
        local drop = DropNeutralItemAtPositionForHero("item_socket_rune_legendary_lifesteal", parent:GetAbsOrigin(), parent, -1, true)
    end
end

function modifier_boss_spider_follower_web_spider_ai:OnCreated(params)
    if not IsServer() then return end

    if not params.target then return end

    self.target = EntIndexToHScript(params.target)

    if not self.target then return end

    self.bKilled = false

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_boss_spider_follower_web_spider_ai:OnIntervalThink()
    local parent = self:GetParent()

    parent:SetForceAttackTarget(self.target)

    if (parent:GetAbsOrigin() - self.target:GetAbsOrigin()):Length2D() <= 200 then
        self:Destroy()
    end
end

function modifier_boss_spider_follower_web_spider_ai:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.bKilled then return end

    parent:AddNewModifier(parent, nil, "modifier_boss_spider_follower_web_spider_ai_detonating", {})

    DrawWarningCircle(parent, parent:GetAbsOrigin(), 300, 2)

    local level = GetLevelFromDifficulty()
    local spiderDamage = 3500 * level

    self.explosionTimer = Timers:CreateTimer(2, function()
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf", PATTACH_POINT, parent)
        ParticleManager:SetParticleControl(particle, 0, parent:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(particle)

        EmitSoundOn("Hero_Broodmother.SpawnSpiderlings", parent)

        local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            300, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            if victim:IsAlive() and not victim:IsMagicImmune() then
                ApplyDamage({
                    victim = victim,
                    attacker = parent,
                    damage = spiderDamage,
                    damage_type = DAMAGE_TYPE_MAGICAL,
                })
            end
        end

        parent:ForceKill(false)
    end)
end

function modifier_boss_spider_follower_web_spider_ai:CheckState()
    local state = {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_DISARMED] = true,
    }   

    return state
end
-------------
function modifier_boss_spider_follower_web_spider_ai_detonating:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }   

    return state
end

function modifier_boss_spider_follower_web_spider_ai_detonating:GetEffectName()
    return "particles/units/heroes/hero_broodmother/broodmother_hunger_buff.vpcf"
end