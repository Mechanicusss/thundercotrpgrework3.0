LinkLuaModifier("boss_queen_of_pain_ai", "heroes/bosses/akasha/ai.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_queen_of_pain_ai_unstunnable", "heroes/bosses/akasha/ai.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_queen_of_pain_ai_frozen", "heroes/bosses/akasha/ai.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_queen_of_pain_counter", "heroes/bosses/akasha/ai.lua", LUA_MODIFIER_MOTION_NONE)

local BossModifierClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
}

local BossModifierClassCounter = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
    IsDebuff = function(self) return true end,
}

boss_queen_of_pain_ai = class(BossModifierClass)
boss_queen_of_pain = class(BossModifierClass)
boss_queen_of_pain_counter = class(BossModifierClassCounter)
boss_queen_of_pain_ai_unstunnable = class(BossModifierClass)
boss_queen_of_pain_ai_frozen = class(BossModifierClass)

local BOSS_NAME = "boss_queen_of_pain"
local BOSS_SPAWN_DELAY = 10 
local BOSS_MAX_LEVEL = 3
local BOSS_RESPAWN_INTERVAL = 90
local AI_STATE_IDLE = 0
local AI_STATE_AGGRESSIVE = 1
local AI_STATE_RETURNING = 2
local AI_THINK_INTERVAL = 0.5

local BOSS_DAMAGE_REDUCTION = 25
local BOSS_DEATH_DROPS = 3
local BOSS_DEATH_COUNTER = 0

function Init()
    if not IsServer() then
        return
    end
end

function boss_queen_of_pain:Spawn(bossName)
    local zone = Entities:FindByName(nil, "boss_qop_spawn_circle")
    if not zone or zone == nil then return end
    
    local unit = CreateUnitByName(bossName, zone:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)

    --unit:FaceTowards(Entities:FindByName(nil, "ent_dota_fountain_good"):GetAbsOrigin())
    unit:SetIdleAcquire(true)

    local counter = unit:AddNewModifier(unit, nil, "boss_queen_of_pain_counter", {})
    counter:SetStackCount(BOSS_DEATH_COUNTER)

    unit:AddItemByName("item_gem")
    unit:AddNewModifier(unit, nil, "boss_queen_of_pain_ai", { aggroRange = 600 })
end

function boss_queen_of_pain_ai:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
        --MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function boss_queen_of_pain_ai:GetModifierProvidesFOWVision()
    if _G.FinalGameWavesEnabled then return 0 end
    return 1
end

function boss_queen_of_pain_ai:GetModifierStatusResistance()
    return 90
end

function boss_queen_of_pain_ai:OnCreated(params)
    if not IsServer() then
        return
    end

    self.zone = Entities:FindByName(nil, "boss_spawn_qop_zone_radius")

    self.state = AI_STATE_IDLE

    self.globalCooldown = false
    self.globalCooldownTimer = nil

    self.aggroRange = params.aggroRange

    -- The boss
    self.unit = self:GetParent()

    -- Spawn position
    self.spawnPos = Entities:FindByName(nil, "boss_qop_spawn_circle"):GetAbsOrigin() 

    self.aggroTarget = nil

    -- Start the AI
    self:StartIntervalThink(AI_THINK_INTERVAL)
end

function boss_queen_of_pain_ai:OnTakeDamage(event)
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

function boss_queen_of_pain_ai:OnIntervalThink()
    if _G.FinalGameWavesEnabled  and self.unit:IsAlive() then
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
        elseif (self.spawnPos - self.unit:GetAbsOrigin()):Length() > 100 then
            self.unit:MoveToPosition(self.spawnPos)
        end
    end

    if self.state == AI_STATE_AGGRESSIVE then
        -- If the first target is not available to be hit, we look for more targets in the aggro Range and select a random one
        -- If there are no more enemies, they reset to idle state
        if not self.unit:IsChanneling() and not self.unit:HasModifier("boss_queen_of_pain_sonic_wave_thinker") then
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

            -- Attempt to cast Scream of Pain
            local screamOfPain = self.unit:FindAbilityByName("boss_queen_of_pain_scream_of_pain")
            if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and screamOfPain:IsCooldownReady() and screamOfPain:IsFullyCastable() and not self.globalCooldown then
                self.globalCooldown = true

                Timers:CreateTimer(1, function()
                    local castPoint = 2

                    if not self.unit:HasModifier("boss_queen_of_pain_ai_frozen") and (not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and screamOfPain:IsCooldownReady() and screamOfPain:IsFullyCastable()) then
                        self.unit:AddNewModifier(self.unit, nil, "boss_queen_of_pain_ai_frozen", { duration = castPoint })
                        DrawWarningCircle(self.unit, self.unit:GetAbsOrigin(), screamOfPain:GetEffectiveCastRange(self.unit:GetAbsOrigin(), self.aggroTarget), castPoint)
                    end

                    Timers:CreateTimer(castPoint, function()
                        if self.unit:IsChanneling() then return end
                        if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and screamOfPain:IsCooldownReady() and screamOfPain:IsFullyCastable() then
                            self.unit:CastAbilityNoTarget(screamOfPain, -1)
                        end
                    end)

                    self.globalCooldownTimer = Timers:CreateTimer(1, function()
                        self.globalCooldown = false
                    end)
                end)
            end

            -- Attempt to cast Shadow Strike
            local shadowStrike = self.unit:FindAbilityByName("boss_queen_of_pain_shadow_strike")
            if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and shadowStrike:IsCooldownReady() and shadowStrike:IsFullyCastable() and not self.globalCooldown then
                self.globalCooldown = true

                Timers:CreateTimer(1, function()
                    local castPoint = 2

                    if not self.unit:HasModifier("boss_queen_of_pain_ai_frozen") and (not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and shadowStrike:IsCooldownReady() and shadowStrike:IsFullyCastable()) then
                        self.unit:AddNewModifier(self.unit, nil, "boss_queen_of_pain_ai_frozen", { duration = castPoint })
                        DrawWarningCircle(self.unit, self.unit:GetAbsOrigin(), shadowStrike:GetEffectiveCastRange(self.unit:GetAbsOrigin(), self.aggroTarget), castPoint)
                    end

                    Timers:CreateTimer(castPoint, function()
                        if self.unit:IsChanneling() then return end
                        if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and shadowStrike:IsCooldownReady() and shadowStrike:IsFullyCastable() then
                            self.unit:CastAbilityNoTarget(shadowStrike, -1)
                        end
                    end)

                    self.globalCooldownTimer = Timers:CreateTimer(1, function()
                        self.globalCooldown = false
                    end)
                end)
            end

            self.unit:SetForceAttackTarget(self.aggroTarget)
        end
        
        -- Attempt to cast Sonic Cataclysm
        local sonicWave = self.unit:FindAbilityByName("boss_queen_of_pain_sonic_wave")
        if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and sonicWave:IsCooldownReady() and sonicWave:IsFullyCastable() and not self.globalCooldown then
            self.globalCooldown = true

            local castPoint = 5

            self.unit:AddNewModifier(self.unit, nil, "boss_queen_of_pain_ai_frozen", { duration = castPoint })
            DrawWarningCircle(self.unit, self.unit:GetAbsOrigin(), sonicWave:GetEffectiveCastRange(self.unit:GetAbsOrigin(), self.aggroTarget), castPoint)

            Timers:CreateTimer(castPoint, function()
                self.unit:AddNewModifier(self.unit, nil, "boss_queen_of_pain_ai_unstunnable", { duration = 2.0 })
                self.unit:CastAbilityNoTarget(sonicWave, -1)
            end)

            self.globalCooldownTimer = Timers:CreateTimer(1, function()
                self.globalCooldown = false
            end)
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

function boss_queen_of_pain_ai:OnDeath(event)
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

    BOSS_DEATH_COUNTER = BOSS_DEATH_COUNTER + 1
end

function boss_queen_of_pain_ai:GetModifierIncomingDamage_Percentage()
    --if self.state == AI_STATE_RETURNING then
        --return -100
    --end
    
    --return self:CalculateDamageReduction(BOSS_DAMAGE_REDUCTION, BOSS_DEATH_COUNTER)
end

function boss_queen_of_pain_ai:CalculateDamageReduction(base, deaths)
    local stacks = (1 - (base/100))

    for i = 1, deaths, 1 do
        stacks = stacks * ((1 - (base/100)))
    end

    stacks = (1 - stacks) * -100

    return stacks
end
--------------
function boss_queen_of_pain_ai_unstunnable:DeclareFunctions()
    local funcs = {}
    return funcs
end

function boss_queen_of_pain_ai_unstunnable:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end
function boss_queen_of_pain_ai_unstunnable:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = false,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }

    return state
end

function boss_queen_of_pain_ai_unstunnable:GetEffectName()
    return "particles/items_fx/black_king_bar_avatar.vpcf"
end
-------------------
function boss_queen_of_pain_ai_frozen:DeclareFunctions()
    local funcs = {}
    return funcs
end

function boss_queen_of_pain_ai_frozen:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end
function boss_queen_of_pain_ai_frozen:CheckState()
    local state = {
        [MODIFIER_STATE_ROOTED] = true,
    }

    return state
end
--------
function boss_queen_of_pain_counter:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function boss_queen_of_pain_counter:GetTexture()
    return "qoparcanascreamofpain"
end
---------
function boss_queen_of_pain_ai:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }

    return state
end