LinkLuaModifier("boss_hephaestus_ai", "heroes/bosses/hephaestus/ai.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_hephaestus_ai_unstunnable", "heroes/bosses/hephaestus/ai.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_hephaestus_ai_frozen", "heroes/bosses/hephaestus/ai.lua", LUA_MODIFIER_MOTION_NONE)

local BossModifierClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
}

boss_hephaestus_ai = class(BossModifierClass)
boss_hephaestus = class(BossModifierClass)
boss_hephaestus_ai_unstunnable = class(BossModifierClass)
boss_hephaestus_ai_frozen = class(BossModifierClass)

local BOSS_NAME = "boss_hephaestus"
local BOSS_SPAWN_DELAY = 10 
local BOSS_MAX_LEVEL = 3
local BOSS_RESPAWN_INTERVAL = 90
local AI_STATE_IDLE = 0
local AI_STATE_AGGRESSIVE = 1
local AI_STATE_RETURNING = 2
local AI_THINK_INTERVAL = 0.5

local BOSS_DAMAGE_REDUCTION = 25
local BOSS_DEATH_DROPS = 5
local BOSS_DEATH_COUNTER = 0

function Init()
    if not IsServer() then
        return
    end
end

function boss_hephaestus:Spawn(bossName)
    local zone = Entities:FindByName(nil, "boss_hephaestus_spawn_circle")
    if not zone or zone == nil then return end
    
    local unit = CreateUnitByName(bossName, zone:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)

    --unit:FaceTowards(Entities:FindByName(nil, "ent_dota_fountain_good"):GetAbsOrigin())
    unit:SetIdleAcquire(true)

    unit:AddItemByName("item_gem")
    unit:AddItemByName("item_hephaestus_essence")
    unit:AddNewModifier(unit, nil, "boss_hephaestus_ai", { aggroRange = 900 })


    _G.HephaestusKilled = false
end

function boss_hephaestus_ai:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
        --MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function boss_hephaestus_ai:GetModifierProvidesFOWVision()
    if _G.FinalGameWavesEnabled then return 0 end
    return 0
end

function boss_hephaestus_ai:GetModifierStatusResistance()
    return 90
end

function boss_hephaestus_ai:OnCreated(params)
    if not IsServer() then
        return
    end

    self.zone = Entities:FindByName(nil, "boss_spawn_hephaestus_zone_radius")

    self.state = AI_STATE_IDLE

    self.globalCooldown = false
    self.globalCooldownTimer = nil

    self.aggroRange = params.aggroRange

    -- The boss
    self.unit = self:GetParent()

    -- Spawn position
    self.spawnPos = Entities:FindByName(nil, "boss_hephaestus_spawn_circle"):GetAbsOrigin() 

    self.aggroTarget = nil

    -- Start the AI
    self:StartIntervalThink(AI_THINK_INTERVAL)

    -- Making sure they get leveled up properly --
    Timers:CreateTimer(1.0, function()
        for i = 0, self.unit:GetAbilityCount() - 1 do
            local abil = self.unit:GetAbilityByIndex(i)
            if abil ~= nil then
                if abil:GetAbilityName() == "creature_lava_melting_strike" then
                    abil:SetActivated(true)
                    abil:SetHidden(false)
                end

                if abil:GetAbilityName() == "doom_boss_infernal_blade" then
                    abil:SetActivated(true)
                    abil:SetHidden(false)
                    abil:ToggleAutoCast()
                end
            end
        end
    end)
end

function boss_hephaestus_ai:OnTakeDamage(event)
    if not IsServer() or self.zone == nil then return end

    if event.unit ~= self.unit then return end

    if event.attacker:GetUnitName() == "npc_dota_unit_undying_zombie" or event.attacker:GetUnitName() == "npc_dota_unit_undying_zombie_torso" then
        event.attacker:ForceKill(false)
        return
    end

    if event.attacker:IsAttackImmune() then return end

    if self.state ~= AI_STATE_IDLE or self.aggroTarget ~= nil then return end

    self.aggroTarget = event.attacker
    self.state = AI_STATE_AGGRESSIVE
end

function boss_hephaestus_ai:OnIntervalThink()
    if _G.FinalGameWavesEnabled and self.unit:IsAlive() then
        Timers:CreateTimer(self.unit:entindex()/1000, function()
            UTIL_RemoveImmediate(self.unit)
        end)
        return
    end

    -- If the boss moves out of the spawn zone
    if not IsInTrigger(self.unit, self.zone) then
        self.unit:MoveToPosition(self.spawnPos)
        self.state = AI_STATE_RETURNING
    end

    if self.state == AI_STATE_IDLE then
        --self.unit:FaceTowards(Entities:FindByName(nil, "ent_dota_fountain_good"):GetAbsOrigin())

        -- Find enemies while boss is idle
        local units = FindUnitsInRadius(self.unit:GetTeam(), self.spawnPos, nil,
            self.aggroRange, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        -- Boss cannot attack while idle
        if self.unit:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK then
            self.unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
        end

        if #units > 0 then
            local target = units[1]

            if target:IsAlive() and not target:IsAttackImmune() and not target:IsUntargetableFrom(self.unit) and not target:IsUnselectable() and not target:IsInvulnerable() and self.unit:CanEntityBeSeenByMyTeam(target) then
                self.aggroTarget = target
                self.state = AI_STATE_AGGRESSIVE
            end
        elseif (self.zone:GetAbsOrigin() - self.unit:GetAbsOrigin()):Length() > (self.aggroRange*2) then
            self.unit:MoveToPosition(self.spawnPos)
        end

        local flameGuard = self.unit:FindAbilityByName("creature_lava_flame_guard")
    
        if flameGuard ~= nil then 
            if flameGuard:IsCooldownReady() and not self.unit:IsSilenced() then
                SpellCaster:Cast(flameGuard, self.unit, true)
            end
        end
    end

    if self.state == AI_STATE_AGGRESSIVE then
        -- If the first target is not available to be hit, we look for more targets in the aggro Range and select a random one
        -- If there are no more enemies, they reset to idle state
        if not self.unit:IsChanneling() then
            if self.aggroTarget == nil or not self.aggroTarget:IsAlive() or self.aggroTarget:IsUntargetableFrom(self.unit) or self.aggroTarget:IsUnselectable() or self.aggroTarget:IsInvulnerable() or not self.unit:CanEntityBeSeenByMyTeam(self.aggroTarget) then
                local units = FindUnitsInRadius(self.unit:GetTeam(), self.zone:GetAbsOrigin(), nil,
                    self.aggroRange, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE), DOTA_UNIT_TARGET_FLAG_NONE,
                    FIND_CLOSEST, false)

                if #units > 0 then
                    self.aggroTarget = units[1]
                else
                    self.unit:MoveToPosition(self.spawnPos)
                    self.state = AI_STATE_RETURNING
                end
            end

            -- The boss is able to attack when aggressive
            if self.unit:GetAttackCapability() == DOTA_UNIT_CAP_NO_ATTACK then
                self.unit:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
            end

            -- Attempt to cast
            local fatalBonds = self.unit:FindAbilityByName("creature_lava_fatal_bonds")
            if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and fatalBonds:IsCooldownReady() and fatalBonds:IsFullyCastable() and not self.globalCooldown then
                self.globalCooldown = true

                Timers:CreateTimer(1, function()
                    local castPoint = 2

                    self.unit:AddNewModifier(self.unit, nil, "boss_hephaestus_ai_frozen", { duration = castPoint })
                    DrawWarningCircle(self.unit, self.unit:GetAbsOrigin(), fatalBonds:GetEffectiveCastRange(self.unit:GetAbsOrigin(), self.aggroTarget), castPoint)
                    
                    Timers:CreateTimer(castPoint, function()
                        SpellCaster:Cast(fatalBonds, self.aggroTarget, true)
                    end)

                    self.globalCooldownTimer = Timers:CreateTimer(1, function()
                        self.globalCooldown = false
                    end)
                end)
            end

            -- Attempt to cast
            local chaosMeteor = self.unit:FindAbilityByName("invoker_chaos_meteor_lua")
            if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and chaosMeteor:IsCooldownReady() and chaosMeteor:IsFullyCastable() and not self.globalCooldown then
                self.globalCooldown = true

                Timers:CreateTimer(1, function()
                    local castPoint = 2

                    self.unit:AddNewModifier(self.unit, nil, "boss_hephaestus_ai_frozen", { duration = castPoint })
                    DrawWarningCircle(self.unit, self.unit:GetAbsOrigin(), chaosMeteor:GetEffectiveCastRange(self.unit:GetAbsOrigin(), self.aggroTarget), castPoint)
                    
                    Timers:CreateTimer(castPoint, function()
                        SpellCaster:Cast(chaosMeteor, self.aggroTarget, true)
                    end)

                    self.globalCooldownTimer = Timers:CreateTimer(1, function()
                        self.globalCooldown = false
                    end)
                end)
            end

            -- Attempt to cast
            local fireBall = self.unit:FindAbilityByName("boss_hephaestus_fireball")
            if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and fireBall:IsCooldownReady() and fireBall:IsFullyCastable() and not self.globalCooldown then
                self.globalCooldown = true

                Timers:CreateTimer(1, function()
                    local castPoint = 2

                    self.unit:AddNewModifier(self.unit, nil, "boss_hephaestus_ai_frozen", { duration = castPoint })
                    DrawWarningCircle(self.unit, self.unit:GetAbsOrigin(), fireBall:GetEffectiveCastRange(self.unit:GetAbsOrigin(), self.aggroTarget), castPoint)
                    
                    Timers:CreateTimer(castPoint, function()
                        SpellCaster:Cast(fireBall, self.unit, true)
                    end)

                    self.globalCooldownTimer = Timers:CreateTimer(1, function()
                        self.globalCooldown = false
                    end)
                end)
            end

            self.unit:SetForceAttackTarget(self.aggroTarget)
        end
    end

    if self.state == AI_STATE_RETURNING then
        self.aggroTarget = nil
        
        if self.globalCooldownTimer ~= nil then
            Timers:RemoveTimer(self.globalCooldownTimer)
        end

        self.globalCooldown = true

        self.globalCooldownTimer = Timers:CreateTimer(1, function()
            self.globalCooldown = false
        end)

        if (self.spawnPos - self.unit:GetAbsOrigin()):Length() < 250 then
            self.state = AI_STATE_IDLE
        end

        self.unit:MoveToPosition(self.spawnPos)
    end
end

function boss_hephaestus_ai:OnDeath(event)
    if not IsServer() then
        return
    end

    if event.unit ~= self:GetParent() then
        if self.aggroTarget == event.unit then
            self.aggroTarget = nil
            return
        end

        return
    end

    if IsPvP() then
        GameRules:SetGameWinner(event.attacker:GetTeamNumber())
        return
    end

    local pos = self.unit:GetAbsOrigin()

    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) and not hero:IsTempestDouble() then
            if PlayerResource:GetConnectionState(hero:GetPlayerID()) == DOTA_CONNECTION_STATE_CONNECTED then
                hero:AddItemByName("item_hephaestus_essence")
                
                hero:ModifyGold(99999, false, 0)
            end
        end
    end
    
    _G.HephaestusKilled = true
    
    if not _G.HephaestusKilledInitially then
        _G.HephaestusKilledInitially = true
    end

    BOSS_DEATH_COUNTER = BOSS_DEATH_COUNTER + 1
end
--------------
function boss_hephaestus_ai_unstunnable:DeclareFunctions()
    local funcs = {}
    return funcs
end

function boss_hephaestus_ai_unstunnable:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end
function boss_hephaestus_ai_unstunnable:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = false,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }

    return state
end

function boss_hephaestus_ai_unstunnable:GetEffectName()
    return "particles/items_fx/black_king_bar_avatar.vpcf"
end
-------------------
function boss_hephaestus_ai_frozen:DeclareFunctions()
    local funcs = {}
    return funcs
end

function boss_hephaestus_ai_frozen:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end
function boss_hephaestus_ai_frozen:CheckState()
    local state = {
        [MODIFIER_STATE_ROOTED] = true,
    }

    return state
end
--------
---------
function boss_hephaestus_ai:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }

    return state
end
