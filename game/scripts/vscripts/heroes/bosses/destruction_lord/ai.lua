LinkLuaModifier("boss_destruction_lord_ai", "heroes/bosses/destruction_lord/ai", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_destruction_lord_ai_frozen", "heroes/bosses/destruction_lord/ai", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_destruction_lord_ai_tombstone", "heroes/bosses/destruction_lord/ai", LUA_MODIFIER_MOTION_NONE)

local BossModifierClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

boss_destruction_lord_ai = class(BossModifierClass)
boss_destruction_lord = class(BossModifierClass)
boss_destruction_lord_ai_frozen = class(BossModifierClass)
boss_destruction_lord_ai_tombstone = class(BossModifierClass)

local BOSS_SPAWN_DELAY = 10 
local BOSS_MAX_LEVEL = 3
local BOSS_RESPAWN_INTERVAL = 90
local AI_STATE_IDLE = 0
local AI_STATE_AGGRESSIVE = 1
local AI_STATE_RETURNING = 2
local AI_THINK_INTERVAL = 0.5

local BOSS_DAMAGE_REDUCTION = 25
local BOSS_DEATH_DROPS = 3

function Init()
    if not IsServer() then
        return
    end
end

function boss_destruction_lord:Spawn(bossName)
    local zone = Entities:FindByName(nil, "boss_destruction_lord_spawn_circle")
    if not zone or zone == nil then return end
    
    local tombstone = CreateUnitByName("boss_destruction_lord_tower", zone:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
    tombstone:AddNewModifier(tombstone, nil, "boss_destruction_lord_ai_tombstone", { bossName = bossName })
    tombstone:SetForwardVector(-tombstone:GetForwardVector())
end

function boss_destruction_lord_ai:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
        --MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function boss_destruction_lord_ai:GetModifierProvidesFOWVision()
    if _G.FinalGameWavesEnabled then return 0 end
    return 1
end

function boss_destruction_lord_ai:GetModifierStatusResistance()
    return 90
end

function boss_destruction_lord_ai:OnCreated(params)
    if not IsServer() then
        return
    end

    self.zone = Entities:FindByName(nil, "boss_spawn_destruction_lord_zone_radius")

    self.state = AI_STATE_IDLE

    self.globalCooldown = false
    self.globalCooldownTimer = nil

    self.aggroRange = params.aggroRange

    -- The boss
    self.unit = self:GetParent()

    -- Spawn position
    self.spawnPos = Entities:FindByName(nil, "boss_destruction_lord_spawn_circle"):GetAbsOrigin() 

    self.aggroTarget = nil

    -- Add Vfx ambient
    self.vfxBodyAmbient = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_destruction_lord/wraith_king_destruction_lord_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.unit)
    ParticleManager:SetParticleControlEnt(self.vfxBodyAmbient, 0, self.unit, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.unit:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(self.vfxBodyAmbient)

    self.vfxWeaponAmbient = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_destruction_lord/wraith_king_destruction_lord_weapon.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.unit)
    ParticleManager:SetParticleControlEnt(self.vfxWeaponAmbient, 0, self.unit, PATTACH_ABSORIGIN_FOLLOW, "attach_attack1", self.unit:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(self.vfxWeaponAmbient)

    -- Start the AI
    self:StartIntervalThink(AI_THINK_INTERVAL)

    local level = GetLevelFromDifficulty()

    -- Making sure they get leveled up properly --
    Timers:CreateTimer(1.0, function()
        for i = 0, self.unit:GetAbilityCount() - 1 do
            local abil = self.unit:GetAbilityByIndex(i)
            if abil ~= nil then
                abil:SetLevel(level)
            end
        end
    end)
end

function boss_destruction_lord_ai:OnTakeDamage(event)
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

function boss_destruction_lord_ai:OnIntervalThink()
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
        elseif (self.spawnPos - self.unit:GetAbsOrigin()):Length() > 200 then
            self.unit:MoveToPosition(self.spawnPos)
        end
    end

    if self.state == AI_STATE_AGGRESSIVE then
        -- If the first target is not available to be hit, we look for more targets in the aggro Range and select a random one
        -- If there are no more enemies, they reset to idle state
        if not self.unit:IsChanneling() and not self.unit:HasModifier("boss_destruction_lord_sonic_wave_thinker") then
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
            local soulTowers = self.unit:FindAbilityByName("boss_destruction_lord_soul_towers")
            if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and soulTowers:IsCooldownReady() and soulTowers:IsFullyCastable() and not self.globalCooldown then
                self.globalCooldown = true

                Timers:CreateTimer(1, function()
                    local castPoint = 2

                    if not self.unit:HasModifier("boss_destruction_lord_ai_frozen") and (not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and soulTowers:IsCooldownReady() and soulTowers:IsFullyCastable()) then
                        self.unit:AddNewModifier(self.unit, nil, "boss_destruction_lord_ai_frozen", { duration = 30 })
                        DrawWarningCircle(self.unit, self.unit:GetAbsOrigin(), soulTowers:GetEffectiveCastRange(self.unit:GetAbsOrigin(), self.aggroTarget), castPoint)
                    end

                    Timers:CreateTimer(castPoint, function()
                        if self.unit:IsChanneling() then return end
                        if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and soulTowers:IsCooldownReady() and soulTowers:IsFullyCastable() then
                            self.unit:CastAbilityNoTarget(soulTowers, -1)
                        end
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

function boss_destruction_lord_ai:OnDeath(event)
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

    GameRules:SendCustomMessage("<font color='yellow'>The Lord of Destruction has been defeated.</font>", 0, 0)
    GameRules:SendCustomMessage("<font color='red'>Prepare to face endless torment. Good luck!</font>", 0, 0)

    local gameMinutes = GameRules:GetGameTime()/60
    local baseExperience = (DIFFICULTY_GPOINTS_REWARD_HEAVEN + DIFFICULTY_GPOINTS_REWARD_LAVA + DIFFICULTY_GPOINTS_REWARD_WINTER + DIFFICULTY_GPOINTS_REWARD_WRAITH + DIFFICULTY_GPOINTS_REWARD_LAKE + DIFFICULTY_GPOINTS_REWARD_SPIDER + DIFFICULTY_GPOINTS_REWARD_FOREST + DIFFICULTY_GPOINTS_REWARD_ROSHAN)*2 -- Adjust this value as needed
    local scalingFactor = 0.15 -- Adjust this value to control the rate of scaling

    -- Calculate experience based on game time
    local experience = baseExperience * math.max(1 - math.log(gameMinutes + 1) * scalingFactor, 0)

    local heroes = HeroList:GetAllHeroes()
    for _,hero in ipairs(heroes) do
        if UnitIsNotMonkeyClone(hero) then
            hero:AddNewModifier(hero, nil, "modifier_stunned", {})
            hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})

            XpManager:AddExperience(hero, experience)
        end
    end

    Timers:CreateTimer(10.0, function()
        WaveManager:Init()
    end)
end
-------------------
function boss_destruction_lord_ai_frozen:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DISABLE_TURNING
    }
    return funcs
end

function boss_destruction_lord_ai_frozen:GetModifierDisableTurning()
    return 1
end

function boss_destruction_lord_ai_frozen:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(1.77778)
    self:OnIntervalThink()
end

function boss_destruction_lord_ai_frozen:OnIntervalThink()
    EmitSoundOn("Visage_Familar.BellToll", self:GetParent())
    self:GetParent():StartGesture(ACT_DOTA_GENERIC_CHANNEL_1)
end

function boss_destruction_lord_ai_frozen:OnDestroy()
    self:GetParent():RemoveGesture(ACT_DOTA_GENERIC_CHANNEL_1)
end

function boss_destruction_lord_ai_frozen:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end
function boss_destruction_lord_ai_frozen:CheckState()
    local state = {
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
    }

    return state
end
---------
function boss_destruction_lord_ai:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }

    return state
end
------------
function boss_destruction_lord_ai_tombstone:OnCreated(params)
    if not IsServer() then return end 

    self.dead = false

    self.bossName = params.bossName
end

function boss_destruction_lord_ai_tombstone:OnDeath(event)
    if not IsServer() then return end 

    if self:GetParent() ~= event.unit then return end

    if self.dead then return end

    local unit = CreateUnitByName(self.bossName, self:GetParent():GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)

    unit:SetIdleAcquire(true)

    unit:AddItemByName("item_gem")
    unit:AddNewModifier(unit, nil, "boss_destruction_lord_ai", { aggroRange = 600 })

    EmitSoundOn("Hero_SkeletonKing.Death", event.unit)
    EmitSoundOn("Hero_SkeletonKing.Reincarnate", event.unit)

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/wraith_king_reincarnate.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControlEnt(self.vfx, 0, unit, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(self.vfx)

    self.dead = true
end

function boss_destruction_lord_ai_tombstone:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }
end

function boss_destruction_lord_ai_tombstone:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_DEATH
    }
end

function boss_destruction_lord_ai_tombstone:GetAbsoluteNoDamagePhysical( params )
    return 1
end

function boss_destruction_lord_ai_tombstone:GetAbsoluteNoDamageMagical( params )
    return 1
end

function boss_destruction_lord_ai_tombstone:GetAbsoluteNoDamagePure( params )
    return 1
end

function boss_destruction_lord_ai_tombstone:OnTakeDamage(params)
    if IsServer() then
        if self:GetParent() == params.unit then
            local nDamage = 0
            if params.attacker and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and params.damage_type == DAMAGE_TYPE_PHYSICAL then
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