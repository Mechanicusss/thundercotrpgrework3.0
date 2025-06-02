LinkLuaModifier("modifier_boss_lava", "bosses/lava", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_lava_follower", "bosses/lava", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

boss_lava = class(BaseClass)
modifier_boss_lava = class(boss_lava)
modifier_boss_lava_follower = class(boss_lava)
--------------------
-- BOSS VARIABLES --
--------------------
BOSS_STAGE = 1
BOSS_MAX_STAGE = 3
PARTICLE_ID = nil

BOSS_NAME = "npc_dota_creature_100_boss"
--------------------
function boss_lava:GetIntrinsicModifierName()
    return "modifier_boss_lava"
end

function modifier_boss_lava:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_STATUS_RESISTANCE
    }
    return funcs
end

function modifier_boss_lava:CheckState()
    local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true
    }

    return state
end

function modifier_boss_lava:GetModifierProvidesFOWVision()
    return 1
end

function modifier_boss_lava:OnTakeDamage(event)
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

function modifier_boss_lava:GetModifierHealthRegenPercentage()
    if self.canRegen then return 10 end
end

function modifier_boss_lava:AddCustomTransmitterData()
    return
    {
        status = self.fStatus,
    }
end

function modifier_boss_lava:HandleCustomTransmitterData(data)
    if data.status ~= nil then
        self.fStatus = tonumber(data.status)
    end
end

function modifier_boss_lava:InvokeStatusResistance()
    if IsServer() == true then
        self.fStatus = self.status

        self:SendBuffRefreshToClients()
    end
end

function modifier_boss_lava:GetModifierStatusResistance()
    return self.fStatus
end

function modifier_boss_lava:OnCreated(kv)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.boss = self:GetParent()
    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)
    self.canRegen = true
    self.regenTimer = nil

    local level = GetLevelFromDifficulty()

    self.status = 25 * BOSS_STAGE
    self:InvokeStatusResistance()

    self.dragonTail = self.boss:FindAbilityByName("boss_dragon_tail_explosion")
    self.sunApocalypse = self.boss:FindAbilityByName("boss_dragon_sun_apocalypse")

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

function modifier_boss_lava:OnIntervalThink()
    self.boss:SetSkin(1)
    
    if not self.boss:IsAlive() then return end

    local target = self.boss:GetAggroTarget()
    if target then
        if self.dragonTail and self.dragonTail:GetLevel() > 0 then
            if self.dragonTail:IsFullyCastable() and not self.boss:IsStunned() and not self.boss:IsSilenced() and not self.boss:IsHexed() then
                if (target:GetAbsOrigin()-self.boss:GetAbsOrigin()):Length2D() <= self.dragonTail:GetEffectiveCastRange(self.boss:GetAbsOrigin(), self.boss) then
                    SpellCaster:Cast(self.dragonTail, target:GetAbsOrigin(), true)
                end
            end
        end

        if self.sunApocalypse and self.sunApocalypse:GetLevel() > 0 then
            if self.sunApocalypse:IsFullyCastable() and not self.boss:IsStunned() and not self.boss:IsSilenced() and not self.boss:IsHexed() then
                if (target:GetAbsOrigin()-self.boss:GetAbsOrigin()):Length2D() <= self.sunApocalypse:GetEffectiveCastRange(self.boss:GetAbsOrigin(), self.boss) then
                    SpellCaster:Cast(self.sunApocalypse, target:GetAbsOrigin(), true)
                end
            end
        end
    end
end

function modifier_boss_lava:IsFollower(follower)
    if not follower or follower:IsNull() then return false end

    if follower:GetUnitName() == "npc_dota_creature_lava_1" then return true end
    if follower:GetUnitName() == "npc_dota_creature_lava_2" then return true end
    if follower:GetUnitName() == "npc_dota_creature_140_crip_Robo" then return true end

    return false
end

function modifier_boss_lava:OnDeath(event)
    if not IsServer() then return end

    local victim = event.unit

    if victim ~= self:GetParent() then return end

    local respawnTime = BOSS_RESPAWN_TIME

    Timers:CreateTimer(respawnTime, function()
        if IsPvP() then return end
        
        CreateUnitByNameAsync(BOSS_NAME, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_lava", {
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
                if hero:FindItemInAnyInventory("item_last_soul") == nil and _G.autoPickup[hero:GetPlayerID()] ~= AUTOLOOT_ON_NO_SOULS then
                    --hero:AddItemByName("item_elder_soul")
                end
                
                hero:ModifyGold(35000, false, 0)
            end
        end
    end

    DropNeutralItemAtPositionForHero("item_last_soul", victim:GetAbsOrigin(), victim, -1, true)
end

function modifier_boss_lava:ProgressToNext()
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
        if minion:GetUnitName() == "npc_dota_creature_lava_1" or
        minion:GetUnitName() == "npc_dota_creature_lava_2" then
            minion:FindModifierByNameAndCaster("modifier_boss_lava_follower", minion):ForceRefresh()
        end
    end

    EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", self:GetParent())
end
-----------
function modifier_boss_lava_follower:DeclareFunctions(props)
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_boss_lava_follower:OnCreated(kv)
    if not IsServer() then return end

    local parent = self:GetParent()

    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)

    self.fireball = parent:FindAbilityByName("lava_drake_flames")
    self.meteor = parent:FindAbilityByName("invoker_chaos_meteor_lua")

    if parent:GetUnitName() == "npc_dota_creature_lava_2" then
        self.particle = ParticleManager:CreateParticle("particles/econ/items/invoker/glorious_inspiration/invoker_forge_spirit_ambient_esl.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(self.particle, 0, parent:GetOrigin())
        ParticleManager:SetParticleControl(self.particle, 1, parent:GetOrigin())
    end

    if parent:GetUnitName() == "npc_dota_creature_140_crip_Robo" then
        self.particle = ParticleManager:CreateParticle("particles/econ/items/warlock/warlock_golem_obsidian/golem_ambient_obsidian.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.particle, 7, parent, PATTACH_POINT_FOLLOW, "attach_mane2", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.particle, 10, parent, PATTACH_POINT_FOLLOW, "attach_attack1", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.particle, 11, parent, PATTACH_POINT_FOLLOW, "attach_attack2", parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.particle, 12, parent, PATTACH_POINT_FOLLOW, "attach_mane2", parent:GetAbsOrigin(), true)
    end

    self:StartIntervalThink(1)
end

function modifier_boss_lava_follower:CheckState()
    local state = {
        --[MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
    return state
end

function modifier_boss_lava_follower:OnIntervalThink()
    local parent = self:GetParent()

    local flameGuard = parent:FindAbilityByName("creature_lava_flame_guard")
    
    if parent:IsAlive() then
        if _G.FinalGameWavesEnabled then
            Timers:CreateTimer(parent:entindex()/1000, function()
                UTIL_RemoveImmediate(parent)
            end)
            return
        end
    
        if flameGuard ~= nil then 
            if flameGuard:IsCooldownReady() and not parent:IsSilenced() then
                SpellCaster:Cast(flameGuard, parent, true)
            end
        end
    end

    local target = parent:GetAggroTarget()

    if target then
        if self.meteor and self.meteor:GetLevel() > 0 then
            if self.meteor:IsFullyCastable() and not parent:IsStunned() and not parent:IsSilenced() and not parent:IsHexed() then
                if (target:GetAbsOrigin()-parent:GetAbsOrigin()):Length2D() <= self.meteor:GetEffectiveCastRange(parent:GetAbsOrigin(), parent) then
                    SpellCaster:Cast(self.meteor, target:GetAbsOrigin(), true)
                end
            end
        end

        if self.fireball and self.fireball:GetLevel() > 0 then
            if self.fireball:IsFullyCastable() and not parent:IsStunned() and not parent:IsSilenced() and not parent:IsHexed() then
                if (target:GetAbsOrigin()-parent:GetAbsOrigin()):Length2D() <= self.fireball:GetEffectiveCastRange(parent:GetAbsOrigin(), parent) then
                    SpellCaster:Cast(self.fireball, target:GetAbsOrigin(), true)
                end
            end
        end
    end
end

function modifier_boss_lava_follower:OnDeath(event)
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

    -- Drops --
    local Tome_Chance = event.attacker:GenerateDropChance()
    local Meteorite_Chance = event.attacker:GenerateDropChance()
    local EnrageCrystal_Chance = event.attacker:GenerateDropChance()
    
    if parent:GetUnitName() == "npc_dota_creature_lava_1" or parent:GetUnitName() == "npc_dota_creature_lava_2" then
        if Meteorite_Chance <= 0.5 and not _G.ItemDroppedMeteoriteSword then
            DropNeutralItemAtPositionForHero("item_fallen_meteor", parent:GetAbsOrigin(), parent, 1, false)
            _G.ItemDroppedMeteoriteSword = true
        end

        if Tome_Chance <= 25 then
            DropNeutralItemAtPositionForHero("item_tome_un_5", parent:GetAbsOrigin(), parent, 1, false)
        end
    end

    if parent:GetUnitName() == "npc_dota_creature_lava_2" then
        --if EnrageCrystal_Chance <= 0.45 and not _G.ItemDroppedEnrageCrystal then
            --DropNeutralItemAtPositionForHero("item_stygian_crystal", parent:GetAbsOrigin(), parent, 1, false)
        --    _G.ItemDroppedEnrageCrystal = true
        --end

        if event.attacker:GenerateDropChance() <= 2.5 then
            local runes = {
                "item_socket_rune_legendary_exodus_shield",
            }
    
            local rune = runes[RandomInt(1, #runes)]
    
            DropNeutralItemAtPositionForHero(rune, parent:GetAbsOrigin(), parent, -1, true)
        end
    end

    Timers:CreateTimer(respawnTime, function()
      CreateUnitByNameAsync(unitName, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_lava_follower", {
                posX = self.spawnPosition.x,
                posY = self.spawnPosition.y,
                posZ = self.spawnPosition.z,
            })

            if RollPercentage(ELITE_SPAWN_CHANCE) then
                unit:AddNewModifier(unit, nil, "modifier_creep_elite", {})
            end

            if modifier_boss_lava:IsFollower(unit) then unit:AddNewModifier(unit, nil, "modifier_boss_lava_follower", {}):ForceRefresh() end
        end)
    end)
end

function modifier_boss_lava_follower:OnRefresh()
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
