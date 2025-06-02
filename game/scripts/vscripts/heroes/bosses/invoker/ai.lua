LinkLuaModifier("boss_invoker_ai", "heroes/bosses/invoker/ai", LUA_MODIFIER_MOTION_NONE)

local BossModifierClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
}

boss_invoker_ai = class(BossModifierClass)
boss_invoker = class(BossModifierClass)

local BOSS_NAME = "boss_invoker"
local BOSS_SPAWN_DELAY = 1200 -- 1200 = 20 minutes
local AI_STATE_IDLE = 0
local AI_STATE_AGGRESSIVE = 1
local AI_STATE_RETURNING = 2
local AI_THINK_INTERVAL = 0.5
local BOSS_ABILITY_INTERVAL = 3 -- Casts every X seconds, same as how long all cooldowns for his skills are
local BOSS_DEATH_COUNTER = 0
local BOSS_DEATH_DROPS = 3

local abilityTable = {
    "invoker_sun_strike_lua",
    "invoker_chaos_meteor_lua",
    "invoker_emp_lua",
    "invoker_cold_snap_lua",
    "invoker_alacrity_lua"
}

function Init()
    if not IsServer() then
        return
    end

    Timers:CreateTimer(BOSS_SPAWN_DELAY, function ()
        boss_invoker:Spawn(BOSS_NAME)
    end)
end

function boss_invoker:Spawn(bossName)
    local zone = Entities:FindByName(nil, "boss_invoker_spawn_circle")
    if not zone or zone == nil then return end
    local unit = CreateUnitByName(bossName, zone:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)

    local playerNumbers = HeroList:GetHeroCount()
    if playerNumbers > 2 then
        unit:CreatureLevelUp(playerNumbers)
    end
    
    unit:AddItemByName("item_gem")
    unit:AddNewModifier(unit, nil, "boss_invoker_ai", { aggroRange = 900 })
end

function boss_invoker_ai:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }

    return funcs
end

function boss_invoker_ai:OnCreated(params)
    if not IsServer() then
        return
    end

    self.zone = Entities:FindByName(nil, "boss_spawn_invoker_zone_radius")

    self.state = AI_STATE_IDLE

    self.aggroRange = params.aggroRange

    self.aggroTarget = nil

    -- The boss
    self.unit = self:GetParent()

    -- Spawn position
    self.spawnPos = Entities:FindByName(nil, "boss_invoker_spawn_circle"):GetAbsOrigin() 

    -- Start the AI
    self:StartIntervalThink(AI_THINK_INTERVAL)

    self.abilityTimer = nil
end

function boss_invoker_ai:OnTakeDamage(event)
    if not IsServer() or self.zone == nil then return end

    if event.unit ~= self.unit then return end

    if event.attacker:GetUnitName() == "npc_dota_unit_undying_zombie" or event.attacker:GetUnitName() == "npc_dota_unit_undying_zombie_torso" then
        event.attacker:ForceKill(false)
        return
    end

    if self.state ~= AI_STATE_IDLE or self.aggroTarget ~= nil then return end

    self.aggroTarget = event.attacker
    self.state = AI_STATE_AGGRESSIVE
end

function boss_invoker_ai:OnIntervalThink()
    -- If the boss moves out of the spawn zone
    if self.unit:GetHealthPercent() < 25 and BOSS_ABILITY_INTERVAL ~= 6 then
        BOSS_ABILITY_INTERVAL = BOSS_ABILITY_INTERVAL/2
    end

    if not IsInTrigger(self.unit, self.zone) then
        self.unit:MoveToPosition(self.spawnPos)
        self.state = AI_STATE_RETURNING
    end

    local units = FindUnitsInRadius(self.unit:GetTeam(), self.spawnPos, nil,
        self.aggroRange, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER, false)

    if self.state == AI_STATE_IDLE then
        -- Boss cannot attack while idle
        self.unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

        if #units > 0 then
            self.aggroTarget = units[1] -- Attack a random unit
            self.state = AI_STATE_AGGRESSIVE
        end
    end

    if self.state == AI_STATE_AGGRESSIVE then
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

        -- The boss is able to attack when aggressive
        if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() then
            self:CastRandomAbility(self.unit, self.zone, self.aggroTarget, self.aggroRange)
        end
        
        self.unit:SetForceAttackTarget(self.aggroTarget)
    end

    if self.state == AI_STATE_RETURNING then
        self.unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

        if (self.spawnPos - self.unit:GetAbsOrigin()):Length() < 100 then
            self.aggroTarget = {}
            self.state = AI_STATE_IDLE
        end

        self.unit:MoveToPosition(self.spawnPos)
    end
end

function boss_invoker_ai:CastRandomAbility(boss, zone, target, range)
    if self.abilityTimer == nil and IsInTrigger(target, zone) then
        self.abilityTimer = Timers:CreateTimer(BOSS_ABILITY_INTERVAL, function()
            -- Do not cast if the target is not inside the zone since they're
            -- most likely no longer attacking the boss, should prevent 
            -- invoker from casting meteors etc in duels and when players respawn after dying to him
            local randomAbility = abilityTable[RandomInt(1, #abilityTable)]

            if randomAbility == "invoker_sun_strike_lua" then
                AbilitySunStrike(boss, zone, target, range)
                self.abilityTimer = nil
            elseif randomAbility == "invoker_chaos_meteor_lua" then
                AbilityMeteor(boss, zone, target, range)
                self.abilityTimer = nil
            elseif randomAbility == "invoker_emp_lua" then
                AbilityEmp(boss, zone, target, range)
                self.abilityTimer = nil
            elseif randomAbility == "invoker_cold_snap_lua" then
                AbilityColdSnap(boss, zone, target, range)
                self.abilityTimer = nil
            elseif randomAbility == "invoker_alacrity_lua" then
                AbilityAlacrity(boss, zone, target, range)
                self.abilityTimer = nil
            end
        end)
    end
end

function AbilitySunStrike(boss, zone, target, range)
    local sunstrike = boss:FindAbilityByName("invoker_sun_strike_lua")
    if sunstrike:IsFullyCastable() and sunstrike:IsCooldownReady() then
        SpellCaster:Cast(sunstrike, boss, true)
    end
end

function AbilityMeteor(boss, zone, target, range)
    local meteor = boss:FindAbilityByName("invoker_chaos_meteor_lua")
    if meteor:IsFullyCastable() and meteor:IsCooldownReady() then
        SpellCaster:Cast(meteor, target, true)
        --boss:CastAbilityOnPosition(target:GetOrigin(), meteor, -1)
    end
end

function AbilityEmp(boss, zone, target, range)
    local emp = boss:FindAbilityByName("invoker_emp_lua")
    if emp:IsFullyCastable() and emp:IsCooldownReady() then
        SpellCaster:Cast(emp, target, true)
        --boss:CastAbilityOnPosition(boss:GetOrigin(), emp, -1)
    end
end

function AbilityColdSnap(boss, zone, target, range)
    -- Apply coldsnap to everyone within aggro range (because thats more fun!)
    local coldsnap = boss:FindAbilityByName("invoker_cold_snap_lua")
    if coldsnap:IsFullyCastable() and coldsnap:IsCooldownReady() then
        local units = FindUnitsInRadius(boss:GetTeam(), zone:GetAbsOrigin(), nil,
            range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER, false)
        
        if #units > 0 then
            for _,unit in ipairs(units) do
                SpellCaster:Cast(coldsnap, unit, true)
                --boss:CastAbilityOnTarget(unit, coldsnap, -1)
            end
        end
    end
end

function AbilityAlacrity(boss, zone, target, range)
    local alacrity = boss:FindAbilityByName("invoker_alacrity_lua")
    if alacrity:IsFullyCastable() and alacrity:IsCooldownReady() then
        SpellCaster:Cast(alacrity, boss, true)
        --boss:CastAbilityOnTarget(boss, alacrity, -1)
    end
end

function boss_invoker_ai:IsHidden()
    return true
end

function boss_invoker_ai:RemoveOnDeath()
    return true
end

function boss_invoker_ai:OnDeath(event)
    if not IsServer() then
        return
    end

    if _G.IsResettingNewGamePlus then return end

    if event.unit ~= self:GetParent() then
        if self.aggroTarget == event.unit then
            self.aggroTarget = nil
            return
        end

        return
    end

    local pos = self.unit:GetAbsOrigin()

    Timers:CreateTimer(90, function ()
        boss_invoker:Spawn(BOSS_NAME)
    end)

    -- Drops --
    for i = 1, BOSS_DEATH_DROPS, 1 do
        Timers:CreateTimer((i/BOSS_DEATH_DROPS)+(i/5), function()
            local items = {
                "item_forgotten_book",
            }
            local chosenDrop = RandomInt(1, #items)
            DropNeutralItemAtPositionForHero(items[chosenDrop], Vector(pos.x+RandomInt(-100, 100), pos.y+RandomInt(-100, 100), pos.z), self.unit, 1, false)
        end)
    end

    if not _G.ItemDroppedCarlConversion then
        DropNeutralItemAtPositionForHero("item_carl_conversion", pos, self.unit, 1, false)
        _G.ItemDroppedCarlConversion = true
    end

    BOSS_DEATH_COUNTER = BOSS_DEATH_COUNTER + 1
end

function boss_invoker_ai:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_MISS] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }

    return state
end