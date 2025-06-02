-- Thanks to Dota IMBA for parts of the code!
-- https://github.com/EarthSalamander42/dota_imba/blob/3e61bdfc972513230ce495132f8230c8926d882a/game/scripts/vscripts/components/abilities/heroes/hero_weaver#L77
LinkLuaModifier("modifier_weaver_the_swarm_custom", "heroes/hero_weaver/weaver_the_swarm_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weaver_the_swarm_custom_beetle_thinker", "heroes/hero_weaver/weaver_the_swarm_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weaver_the_swarm_custom_beetle", "heroes/hero_weaver/weaver_the_swarm_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_weaver_the_swarm_custom_beetle_debuff", "heroes/hero_weaver/weaver_the_swarm_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

weaver_the_swarm_custom = class(ItemBaseClass)
modifier_weaver_the_swarm_custom = class(weaver_the_swarm_custom)
modifier_weaver_the_swarm_custom_beetle_thinker = class(ItemBaseClassDebuff)
modifier_weaver_the_swarm_custom_beetle_debuff = class(ItemBaseClassDebuff)
modifier_weaver_the_swarm_custom_beetle = class(ItemBaseClassDebuff)
-------------
function weaver_the_swarm_custom:OnProjectileHit(hTarget, hLoc, pid)
    if not hTarget then return end
    --make sure one target cant get multiple beetles attached

    if hTarget:HasModifier("modifier_weaver_the_swarm_custom_beetle_debuff") then return end 

    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    CreateModifierThinker(caster, self, "modifier_weaver_the_swarm_custom_beetle_thinker", {
        duration = duration,
        targetindex = hTarget:entindex()
    }, hLoc, caster:GetTeamNumber(), false)

    -- Destroy the beetle once it latches onto a target
    return true
end

function weaver_the_swarm_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local origin = caster:GetAbsOrigin()

    EmitSoundOn("Hero_Weaver.Swarm.Cast", caster)

    local count = self:GetSpecialValueFor("count")

    local start_pos = nil

    for i = 1, count do
        start_pos = self:GetCaster():GetAbsOrigin() + RandomVector(RandomInt(0, self:GetSpecialValueFor("spawn_radius")))

        -- projectile data
        local projectile_name = "particles/units/heroes/hero_weaver/weaver_swarm_projectile.vpcf"
        local projectile_start_radius = self:GetSpecialValueFor("radius")
        local projectile_end_radius = projectile_start_radius
        local projectile_direction = (point-origin)
        projectile_direction.z = 0
        projectile_direction:Normalized()
        local projectile_speed = self:GetSpecialValueFor("speed")
        local projectile_distance = 3000
        local projectile_travel_time = 4

        -- create projectile
        local info = {
            Source = caster,
            Ability = self,
            vSpawnOrigin = start_pos,
            
            bDeleteOnHit = false,
            
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            
            EffectName = projectile_name,
            fDistance = projectile_distance * projectile_travel_time,
            fStartRadius = projectile_start_radius,
            fEndRadius = projectile_end_radius,
            vVelocity = (self:GetCursorPosition() - self:GetCaster():GetAbsOrigin()):Normalized() * projectile_speed * Vector(1, 1, 0),
            fExpireTime 		= GameRules:GetGameTime() + 10.0,

            bProvidesVision		= true,
            iVisionRadius 		= 321,
        }

        ProjectileManager:CreateLinearProjectile(info)
    end
end
----------------
function modifier_weaver_the_swarm_custom_beetle_thinker:OnCreated(params)
    if not IsServer() then return end 

    local parent = self:GetParent()
    local caster = self:GetCaster()

    EmitSoundOn("Hero_Weaver.SwarmAttach", parent)
    
    self.attachedTarget = EntIndexToHScript(params.targetindex)

    if not self.attachedTarget or self.attachedTarget:IsNull() then return end 

    self.attachedTarget:AddNewModifier(caster, self:GetAbility(), "modifier_weaver_the_swarm_custom_beetle_debuff", {})

    -- Using the default dota NPC for beetle might be something I regret later
    self.beetle = CreateUnitByName("npc_dota_weaver_swarm", self.attachedTarget:GetAbsOrigin() + self.attachedTarget:GetForwardVector() * 64, true, nil, nil, caster:GetTeam())
    self.beetle:SetForwardVector((self.attachedTarget:GetAbsOrigin() - self.beetle:GetAbsOrigin()):Normalized())
    self.beetle:AddNewModifier(caster, self:GetAbility(), "modifier_weaver_the_swarm_custom_beetle", {})

    self:StartIntervalThink(FrameTime())
end

function modifier_weaver_the_swarm_custom_beetle_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if not self.attachedTarget or self.attachedTarget:IsNull() then
        self.beetle:ForceKill(false)
        self:StartIntervalThink(-1)
        self:Destroy()
        return
    end

    if self.attachedTarget:IsInvisible() or not self.attachedTarget:IsAlive() then
        self.beetle:ForceKill(false)
    end

    parent:SetAbsOrigin(self.attachedTarget:GetAbsOrigin())

    self.beetle:SetAbsOrigin(self.attachedTarget:GetAbsOrigin() + self.attachedTarget:GetForwardVector() * 64)
    self.beetle:SetForwardVector((self.attachedTarget:GetAbsOrigin() - self.beetle:GetAbsOrigin()):Normalized())
end

function modifier_weaver_the_swarm_custom_beetle_thinker:OnDestroy()
    if not IsServer() then return end 

    if not self.attachedTarget:IsNull() then
        self.attachedTarget:RemoveModifierByName("modifier_weaver_the_swarm_custom_beetle_debuff")
    end

    if not self.beetle:IsNull() then
        self.beetle:ForceKill(false)
    end

    UTIL_Remove(self:GetParent())
end
----------
function modifier_weaver_the_swarm_custom_beetle_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_weaver_the_swarm_custom_beetle_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_reduction") * self:GetStackCount()
end

function modifier_weaver_the_swarm_custom_beetle_debuff:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    local interval = ability:GetSpecialValueFor("attack_rate")

    self:StartIntervalThink(interval)
end

function modifier_weaver_the_swarm_custom_beetle_debuff:OnIntervalThink()
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self:GetAbility():GetSpecialValueFor("damage") + (self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster()) * (self:GetAbility():GetSpecialValueFor("damage_from_attack")/100)),
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility()
    })

    self:IncrementStackCount()

    local caster = self:GetCaster()

    if not caster:HasModifier("modifier_item_aghanims_shard") then return end 
    if (caster:GetAbsOrigin()-self:GetParent():GetAbsOrigin()):Length2D() > caster:Script_GetAttackRange() then return end
    if caster:IsInvisible() then return end

    caster:PerformAttack(
        self:GetParent(),
        true,
        true,
        true,
        false,
        true,
        false,
        false
    )
end

function modifier_weaver_the_swarm_custom_beetle_debuff:GetEffectName()
	return "particles/units/heroes/hero_weaver/weaver_swarm_debuff.vpcf"
end
----------
function modifier_weaver_the_swarm_custom_beetle:CheckState()
    local state = {
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true
    }   

    return state
end

function modifier_weaver_the_swarm_custom_beetle:OnDestroy()
    if not IsServer() then return end 

    UTIL_Remove(self:GetParent())
end

function modifier_weaver_the_swarm_custom_beetle:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    }
end

-- These aren't working right now
function modifier_weaver_the_swarm_custom_beetle:GetOverrideAnimation()
	return ACT_DOTA_IDLE
end

function modifier_weaver_the_swarm_custom_beetle:GetAbsoluteNoDamageMagical()
    return 1
end

function modifier_weaver_the_swarm_custom_beetle:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_weaver_the_swarm_custom_beetle:GetAbsoluteNoDamagePure()
    return 1
end