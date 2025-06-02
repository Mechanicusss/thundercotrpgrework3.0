LinkLuaModifier("boss_skeleton_king_ai", "heroes/bosses/skeleton_king/ai", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_skeleton_king_ai_unstunnable", "heroes/bosses/skeleton_king/ai", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_skeleton_king_ai_frozen", "heroes/bosses/skeleton_king/ai", LUA_MODIFIER_MOTION_NONE)

local BossModifierClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

boss_skeleton_king_ai = class(BossModifierClass)
boss_skeleton_king = class(BossModifierClass)
boss_skeleton_king_ai_unstunnable = class(BossModifierClass)
boss_skeleton_king_ai_frozen = class(BossModifierClass)

local BOSS_NAME = "boss_skeleton_king"
local BOSS_SPAWN_DELAY = 10 
local BOSS_MAX_LEVEL = 3
local BOSS_RESPAWN_INTERVAL = 90
local AI_STATE_IDLE = 0
local AI_STATE_AGGRESSIVE = 1
local AI_STATE_RETURNING = 2
local AI_THINK_INTERVAL = 0.5

local BOSS_DEATH_COUNTER = 0

function Init()
    if not IsServer() then
        return
    end
end

function boss_skeleton_king:Spawn(bossName, loc)
    local zone = Entities:FindByName(nil, "boss_skeleton_king_spawn_circle")
    if not zone or zone == nil then return end

    local point = zone:GetAbsOrigin() 

    if loc ~= nil then
        point = loc
    end
    
    local unit = CreateUnitByName(bossName, point, true, nil, nil, DOTA_TEAM_NEUTRALS)

    --unit:FaceTowards(Entities:FindByName(nil, "ent_dota_fountain_good"):GetAbsOrigin())
    unit:SetIdleAcquire(true)

    unit:AddItemByName("item_gem")
    unit:AddNewModifier(unit, nil, "boss_skeleton_king_ai", { aggroRange = 1200, reincarnated = (loc ~= nil) })

    _G.skeletonKingKilled = false
end

function boss_skeleton_king_ai:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS 
        --MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }

    return funcs
end

function boss_skeleton_king_ai:GetActivityTranslationModifiers()
    return "run"
end

function boss_skeleton_king_ai:GetModifierProvidesFOWVision()
    return 0
end

function boss_skeleton_king_ai:GetModifierStatusResistance()
    return 90
end

function boss_skeleton_king_ai:OnCreated(params)
    if not IsServer() then
        return
    end

    self.zone = Entities:FindByName(nil, "boss_spawn_skeleton_king_zone_radius")

    self.state = AI_STATE_IDLE

    self.globalCooldown = false
    self.globalCooldownTimer = nil

    self.aggroRange = params.aggroRange

    self.reincarnated = params.reincarnated

    -- The boss
    self.unit = self:GetParent()

    -- Spawn position
    self.spawnPos = Entities:FindByName(nil, "boss_skeleton_king_spawn_circle"):GetAbsOrigin() 

    self.aggroTarget = nil

    local hero = self.unit

    hero:SetOriginalModel("models/items/wraith_king/arcana/wraith_king_arcana.vmdl")
    hero.PapichBloodShard = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/wraith_king/arcana/wraith_king_arcana_weapon.vmdl"})
    hero.PapichBloodShard:SetModelScale(3)
    hero.PapichBloodShard:FollowEntity(hero, true)
    hero.PapichHead = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/wraith_king/arcana/wraith_king_arcana_head.vmdl"})
    hero.PapichHead:FollowEntity(hero, true)
    hero.PapichPauldrons = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/wraith_king/arcana/wraith_king_arcana_shoulder.vmdl"})
    hero.PapichPauldrons:FollowEntity(hero, true)
    hero.PapichPunch = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/wraith_king/blistering_shade/mesh/blistering_shade_alt.vmdl"})
    hero.PapichPunch:FollowEntity(hero, true)
    hero.PapichCape = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/wraith_king/arcana/wraith_king_arcana_back.vmdl"})
    hero.PapichCape:FollowEntity(hero, true)
    hero.PapichArmor = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/wraith_king/arcana/wraith_king_arcana_armor.vmdl"})
    hero.PapichArmor:FollowEntity(hero, true)
    hero.PapichEffect = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_ti6_bracer/wraith_king_ti6_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero.PapichEffect)
    ParticleManager:ReleaseParticleIndex(hero.PapichEffect)
    hero.HeadEffect = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_ambient_head.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero.PapichHead)
    ParticleManager:ReleaseParticleIndex(hero.HeadEffect)
    hero.AmbientEffect = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_ambient.vpcf", PATTACH_POINT_FOLLOW, hero)
    ParticleManager:SetParticleControl(hero.AmbientEffect, 0, hero:GetAbsOrigin())
    ParticleManager:SetParticleControl(hero.AmbientEffect, 1, hero:GetAbsOrigin())
    ParticleManager:SetParticleControl(hero.AmbientEffect, 2, hero:GetAbsOrigin())
    ParticleManager:SetParticleControl(hero.AmbientEffect, 3, hero:GetAbsOrigin())
    ParticleManager:SetParticleControl(hero.AmbientEffect, 4, hero:GetAbsOrigin())
    ParticleManager:SetParticleControl(hero.AmbientEffect, 5, hero:GetAbsOrigin())
    ParticleManager:SetParticleControl(hero.AmbientEffect, 6, hero:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(hero.AmbientEffect)

    local children = self.unit:GetChildren()
    local weaponEntity = nil

    for _,child in pairs(children) do
        if child:GetModelName() == "models/items/wraith_king/arcana/wraith_king_arcana_weapon.vmdl" then
            weaponEntity = child
            break
        end
    end

    if weaponEntity ~= nil then
        local weaponVfx = ParticleManager:CreateParticle("particles/econ/items/wraith_king/wraith_king_arcana/wk_arc_weapon.vpcf", PATTACH_POINT_FOLLOW, weaponEntity)
        
        ParticleManager:SetParticleControlEnt(
          weaponVfx,
          0,
          self.unit,
          PATTACH_WORLDORIGIN,
          "attach_attack2", --2 is used in other effects so assuming that's the correct one. although 1 doesn't work either.
          Vector(0,0,0), -- unknown
          true -- unknown, true
        )

        ParticleManager:SetParticleControlEnt(
          weaponVfx,
          1,
          weaponEntity,
          PATTACH_POINT_FOLLOW,
          "attach_gem_top_fx", --2 is used in other effects so assuming that's the correct one. although 1 doesn't work either.
          Vector(0,0,0), -- unknown
          true -- unknown, true
        )

        ParticleManager:SetParticleControlEnt(
          weaponVfx,
          2,
          weaponEntity,
          PATTACH_POINT_FOLLOW,
          "attach_gem_bot_fx", --2 is used in other effects so assuming that's the correct one. although 1 doesn't work either.
          Vector(0,0,0), -- unknown
          true -- unknown, true
        )

        ParticleManager:SetParticleControlEnt(
          weaponVfx,
          5,
          weaponEntity,
          PATTACH_POINT_FOLLOW,
          "attach_weapon_fx", --2 is used in other effects so assuming that's the correct one. although 1 doesn't work either.
          Vector(0,0,0), -- unknown
          true -- unknown, true
        )

        ParticleManager:ReleaseParticleIndex(weaponVfx)
    end

    for i=0, self.unit:GetAbilityCount()-1 do
        local abil = self.unit:GetAbilityByIndex(i)
        if abil ~= nil then
            if self.reincarnated == 0 then
                abil:SetLevel(1)
            else
                if abil:GetAbilityName() == "boss_skeleton_king_reincarnation" then
                    abil:UseResources(false, false, false, true)
                end

                abil:SetLevel(2)
            end
        end
    end

    -- Start the AI
    self:StartIntervalThink(AI_THINK_INTERVAL)
end

function boss_skeleton_king_ai:OnTakeDamage(event)
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

function boss_skeleton_king_ai:OnIntervalThink()
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
            local wraithFireBlast = self.unit:FindAbilityByName("boss_skeleton_king_hellfire_blast")
            if not self.unit:IsSilenced() and not self.unit:IsHexed() and not self.unit:IsStunned() and wraithFireBlast:IsCooldownReady() and wraithFireBlast:IsFullyCastable() and not self.globalCooldown then
                self.globalCooldown = true

                Timers:CreateTimer(1, function()
                    self.unit:StartGesture(ACT_DOTA_CAST_ABILITY_1)

                    Timers:CreateTimer(0.35, function()
                        SpellCaster:Cast(wraithFireBlast, self.aggroTarget, true)
                        self.unit:RemoveGesture(ACT_DOTA_CAST_ABILITY_1)
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

function boss_skeleton_king_ai:OnDeath(event)
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
end
--------------
function boss_skeleton_king_ai_unstunnable:DeclareFunctions()
    local funcs = {}
    return funcs
end

function boss_skeleton_king_ai_unstunnable:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end
function boss_skeleton_king_ai_unstunnable:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = false,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    }

    return state
end

function boss_skeleton_king_ai_unstunnable:GetEffectName()
    return "particles/items_fx/black_king_bar_avatar.vpcf"
end
-------------------
function boss_skeleton_king_ai_frozen:DeclareFunctions()
    local funcs = {}
    return funcs
end

function boss_skeleton_king_ai_frozen:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end
function boss_skeleton_king_ai_frozen:CheckState()
    local state = {
        [MODIFIER_STATE_ROOTED] = true,
    }

    return state
end
--------
---------
function boss_skeleton_king_ai:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
    }

    return state
end
