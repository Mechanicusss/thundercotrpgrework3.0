LinkLuaModifier("modifier_boss_zombie", "bosses/zombie", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_zombie_follower", "bosses/zombie", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_zombie_tombstone_follower", "bosses/zombie", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_zombie_tombstone_follower_recharging", "bosses/zombie", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_zombie_tombstone_follower_zombie", "bosses/zombie", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local BaseClassTombstone = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

local BaseClassTombstoneRecharging = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

boss_zombie = class(BaseClass)
modifier_boss_zombie = class(boss_zombie)
modifier_boss_zombie_follower = class(BaseClassTombstone)
modifier_boss_zombie_tombstone_follower = class(boss_zombie)
modifier_boss_zombie_tombstone_follower_recharging = class(BaseClassTombstoneRecharging)
modifier_boss_zombie_tombstone_follower_zombie = class(BaseClassTombstoneRecharging)
--------------------
-- BOSS VARIABLES --
--------------------
BOSS_STAGE = 1
BOSS_MAX_STAGE = 3
PARTICLE_ID = nil

BOSS_NAME = "npc_dota_creature_40_boss"
--------------------
function boss_zombie:GetIntrinsicModifierName()
    return "modifier_boss_zombie"
end
---
function modifier_boss_zombie:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_STATUS_RESISTANCE
    }
    return funcs
end

function modifier_boss_zombie:AddCustomTransmitterData()
    return
    {
        status = self.fStatus,
    }
end

function modifier_boss_zombie:HandleCustomTransmitterData(data)
    if data.status ~= nil then
        self.fStatus = tonumber(data.status)
    end
end

function modifier_boss_zombie:InvokeStatusResistance()
    if IsServer() == true then
        self.fStatus = self.status

        self:SendBuffRefreshToClients()
    end
end

function modifier_boss_zombie:GetModifierStatusResistance()
    return self.fStatus
end

function modifier_boss_zombie:CheckState()
    local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR_FOR_ENEMIES] = true
    }

    return state
end

function modifier_boss_zombie:GetModifierProvidesFOWVision()
    return 1
end

function modifier_boss_zombie:OnTakeDamage(event)
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

function modifier_boss_zombie:GetModifierHealthRegenPercentage()
    if self.canRegen then return 10 end
end

function modifier_boss_zombie:OnCreated(kv)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.boss = self:GetParent()
    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)
    self.canRegen = true
    self.regenTimer = nil

    local level = GetLevelFromDifficulty()

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

function modifier_boss_zombie:OnIntervalThink()
    if self.boss:GetAggroTarget() == nil then return end
end

function modifier_boss_zombie:IsFollower(follower)
    if not follower or follower:IsNull() then return false end

    if follower:GetUnitName() == "npc_dota_creature_40_crip_7" then return true end
    if follower:GetUnitName() == "npc_dota_creature_40_crip_8" then return true end
    if follower:GetUnitName() == "npc_dota_creature_40_crip_9" then return true end

    return false
end

function modifier_boss_zombie:ProgressToNext()
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
        if minion:GetUnitName() == "npc_dota_creature_40_crip_7" or
        minion:GetUnitName() == "npc_dota_creature_40_crip_8" or 
        minion:GetUnitName() == "npc_dota_creature_40_crip_9"  then
            local mod = minion:FindModifierByNameAndCaster("modifier_boss_zombie_follower", minion)
            if mod ~= nil then
                mod:ForceRefresh()
            end
        end
    end

    EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", self:GetParent())
end

function modifier_boss_zombie:OnDeath(event)
    if not IsServer() then return end

    local victim = event.unit

    if victim ~= self:GetParent() then return end

    local respawnTime = BOSS_RESPAWN_TIME

    Timers:CreateTimer(respawnTime, function()
        if IsPvP() then return end
        
        CreateUnitByNameAsync(BOSS_NAME, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_zombie", {
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
                if hero:FindItemInAnyInventory("item_spider_soul") == nil and _G.autoPickup[hero:GetPlayerID()] ~= AUTOLOOT_ON_NO_SOULS then
                    --hero:AddItemByName("item_spider_soul")
                end
                
                hero:ModifyGold(15000, false, 0)
            end
        end
    end

    DropNeutralItemAtPositionForHero("item_spider_soul", victim:GetAbsOrigin(), victim, -1, true)

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
function modifier_boss_zombie_follower:DeclareFunctions(props)
    local funcs = {
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_boss_zombie_follower:OnCreated(kv)
    if not IsServer() then return end

    self.spawnPosition = Vector(kv.posX, kv.posY, kv.posZ)

    local parent = self:GetParent()

    -- Tombstone
    if parent:GetUnitName() == "npc_dota_creature_40_crip_7" then
        parent:AddNewModifier(parent, nil, "modifier_boss_zombie_tombstone_follower", {})
    end

    self:StartIntervalThink(1.0)
end

function modifier_boss_zombie_follower:CheckState()
    local parent = self:GetParent()

    if parent:GetUnitName() == "npc_dota_creature_40_crip_7" then
        return {
            [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
            [MODIFIER_STATE_ROOTED] = true,
            [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        }
    end
end

function modifier_boss_zombie_follower:OnIntervalThink()
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

function modifier_boss_zombie_follower:OnRemoved(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    local unitName = parent:GetUnitName()

    -- Don't respawn event zombies
    if parent:GetUnitName() == "npc_dota_creature_40_crip_8" or parent:GetUnitName() == "npc_dota_creature_40_crip_9" then return end 

    local respawnTime = CREEP_RESPAWN_TIME

    if FAST_BOSSES_VOTE_RESULT:upper() == "ENABLE" and IsCreepTCOTRPG(parent) then
        respawnTime = 1
    end

    Timers:CreateTimer(respawnTime, function()
      CreateUnitByNameAsync(unitName, self.spawnPosition, true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
            -- Async is faster and will help reduce stutter
            if RollPercentage(ELITE_SPAWN_CHANCE) and not parent:IsNull() and parent:GetUnitName() ~= "npc_dota_creature_40_crip_7" then
                unit:AddNewModifier(unit, nil, "modifier_creep_elite", {})
            end

            if modifier_boss_zombie:IsFollower(unit) then unit:AddNewModifier(unit, nil, "modifier_boss_zombie_follower", {
                posX = self.spawnPosition.x,
                posY = self.spawnPosition.y,
                posZ = self.spawnPosition.z,
            }):ForceRefresh() end
        end)
    end)
end

function modifier_boss_zombie_follower:OnRefresh()
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
--------
function modifier_boss_zombie_tombstone_follower:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_boss_zombie_tombstone_follower:GetAbsoluteNoDamagePhysical( params )
    return 1
end

function modifier_boss_zombie_tombstone_follower:GetAbsoluteNoDamageMagical( params )
    return 1
end

function modifier_boss_zombie_tombstone_follower:GetAbsoluteNoDamagePure( params )
    return 1
end

function modifier_boss_zombie_tombstone_follower:OnTakeDamage(params)
    if IsServer() then
        if self:GetParent() == params.unit then
            local nDamage = 0
            if params.attacker and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and params.damage_type == DAMAGE_TYPE_PHYSICAL and not self:GetParent():HasModifier("modifier_boss_zombie_tombstone_follower_recharging") then
                local bDeathWard = params.attacker:FindModifierByName( "modifier_aghsfort_witch_doctor_death_ward" ) ~= nil
                local bValidAttacker = params.attacker:IsRealHero() or bDeathWard
                if not bValidAttacker then
                    return 0
                end
            
                nDamage = 1

                self:GetParent():ModifyHealth( self:GetParent():GetHealth() - nDamage, nil, true, 0 )

                if self:GetParent():GetHealth() > 0 then
                    self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_boss_zombie_tombstone_follower_recharging", {
                        duration = 60
                    })

                    EmitSoundOn("Hero_Undying.Tombstone.Exit", self:GetParent())
                end
            end
        end
    end

    return 0
end

function modifier_boss_zombie_tombstone_follower:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }   

    return state
end
---------
function modifier_boss_zombie_tombstone_follower_recharging:GetStatusEffectName()
    return "particles/status_fx/status_effect_earth_spirit_petrify.vpcf"
end

function modifier_boss_zombie_tombstone_follower_recharging:StatusEffectPriority()
    return 10
end

function modifier_boss_zombie_tombstone_follower_recharging:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
end

function modifier_boss_zombie_tombstone_follower_recharging:OnCreated()
    if not IsServer() then return end

    self.spawnInterval = 3

    self.spawnedElite = false

    self:StartIntervalThink(self.spawnInterval)
end

function modifier_boss_zombie_tombstone_follower_recharging:OnIntervalThink()
    local parent = self:GetParent()
    local spawnOrigin = parent:GetAbsOrigin()

    if self:IsNull() then return end

    if not self.spawnedElite and parent:GetHealth() == 1 then
        self.spawnedElite = true

        CreateUnitByNameAsync("npc_dota_creature_40_crip_9", spawnOrigin, true, nil, nil, parent:GetTeam(), function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_zombie_follower", {
                posX = spawnOrigin.x,
                posY = spawnOrigin.y,
                posZ = spawnOrigin.z,
            })
    
            unit:AddNewModifier(parent, nil, "modifier_boss_zombie_tombstone_follower_zombie", { duration = 60 })
            EmitSoundOn("Hero_Undying.FleshGolem.Cast", unit)
        end)
    elseif parent:GetHealth() > 1 then
        CreateUnitByNameAsync("npc_dota_creature_40_crip_8", spawnOrigin, true, nil, nil, parent:GetTeam(), function(unit)
            --Async is faster and will help reduce stutter
            unit:AddNewModifier(unit, nil, "modifier_boss_zombie_follower", {
                posX = spawnOrigin.x,
                posY = spawnOrigin.y,
                posZ = spawnOrigin.z,
            })
    
            unit:AddNewModifier(parent, nil, "modifier_boss_zombie_tombstone_follower_zombie", { duration = 60 })
        end)
    end
end

function modifier_boss_zombie_tombstone_follower_recharging:OnRemoved()
    if not IsServer() then return end 

    local parent = self:GetParent()

    EmitSoundOn("Hero_Undying.Tombstone", parent)

    if not parent:IsNull() and parent:IsAlive() and parent:GetHealth() == "1" then        
        parent:ForceKill(false)
    end
end
------------
function modifier_boss_zombie_tombstone_follower_zombie:CheckState()

end

function modifier_boss_zombie_tombstone_follower_zombie:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent:IsNull() then return end

    local caster = self:GetCaster()

    if not caster:IsNull() and caster:IsAlive() then
        if parent:GetUnitName() == "npc_dota_creature_40_crip_9" then            
            caster:ForceKill(false)
        end
    end

    if parent:IsAlive() then
        UTIL_Remove(parent)
    end
end

function modifier_boss_zombie_tombstone_follower_zombie:OnCreated()
    if not IsServer() then return end

    self.target = nil

    self:StartIntervalThink(FrameTime())
end

function modifier_boss_zombie_tombstone_follower_zombie:OnIntervalThink()
    local caster = self:GetCaster()

    if caster:IsNull() or (not caster:IsNull() and not caster:IsAlive()) then 
        self:Destroy()
        return
    end

    local parent = self:GetParent()

    if (parent:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > 900 then
        self.target = nil
        parent:MoveToPosition(caster:GetAbsOrigin())
        return
    end

    if not caster:IsAlive() then
        self:Destroy()
        return
    end

    if self.target ~= nil then
        if self.target:IsAlive() then
            parent:SetForceAttackTarget(self.target)
        else
            parent:SetForceAttackTarget(nil)
            self.target = nil
        end
    end

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            900, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        self.target = victim 
        break
    end
end