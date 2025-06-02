LinkLuaModifier("boss_queen_of_pain_sonic_wave_modifier", "heroes/bosses/akasha/sonic_wave", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_queen_of_pain_sonic_wave_thinker", "heroes/bosses/akasha/sonic_wave", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_queen_of_pain_sonic_wave_thinker_animation", "heroes/bosses/akasha/sonic_wave", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_queen_of_pain_sonic_wave_debuff", "heroes/bosses/akasha/sonic_wave", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
}

local BaseClassDebuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end
}

boss_queen_of_pain_sonic_wave = class(BaseClass)
boss_queen_of_pain_sonic_wave_modifier = class(BaseClass)
boss_queen_of_pain_sonic_wave_thinker = class(BaseClass)
boss_queen_of_pain_sonic_wave_thinker_animation = class(BaseClass)
boss_queen_of_pain_sonic_wave_debuff = class(BaseClassDebuff)

function boss_queen_of_pain_sonic_wave:GetIntrinsicModifierName()
    return "boss_queen_of_pain_sonic_wave_modifier"
end

function boss_queen_of_pain_sonic_wave:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "boss_queen_of_pain_sonic_wave_thinker", {})
end

function boss_queen_of_pain_sonic_wave:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("boss_queen_of_pain_sonic_wave_thinker")

    caster:FadeGesture(ACT_DOTA_CAST_ABILITY_4)
end

function boss_queen_of_pain_sonic_wave:OnProjectileHit(hTarget, vLocation)
    if not IsServer() then return end
    if hTarget == nil then return end

    local caster = self:GetCaster()
    local damage = self:GetLevelSpecialValueFor("damage", (self:GetLevel() - 1))
    local interval = self:GetLevelSpecialValueFor("summon_interval", (self:GetLevel() - 1))
    local knockbackDistance = self:GetLevelSpecialValueFor("knockback_distance", (self:GetLevel() - 1))
    local position = caster:GetAbsOrigin()
    local len = (hTarget:GetAbsOrigin() - position):Length2D()
    len = math.abs(knockbackDistance - knockbackDistance * ( len / 900 ))

    local knockbackModifierTable =
    {
        should_stun = 0,
        knockback_duration = 1,
        duration = 1,
        knockback_distance = len,
        knockback_height = 0,
        center_x = position.x,
        center_y = position.y,
        center_z = position.z
    }

    hTarget:AddNewModifier(hTarget, nil, "modifier_knockback", knockbackModifierTable)
    hTarget:AddNewModifier(hTarget, self, "boss_queen_of_pain_sonic_wave_debuff", { duration = interval })

    local damage = {
        victim = hTarget,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
    }

    ApplyDamage(damage)
end
----------
function boss_queen_of_pain_sonic_wave_thinker:OnCreated()
    if not IsServer() then return end

    self.projectile = "particles/econ/items/queen_of_pain/qop_arcana/qop_arcana_sonic_wave.vpcf"
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    self.distance = self.ability:GetLevelSpecialValueFor("distance", (self.ability:GetLevel() - 1))
    self.startingAoe = self.ability:GetLevelSpecialValueFor("starting_aoe", (self.ability:GetLevel() - 1))
    self.finalAoe = self.ability:GetLevelSpecialValueFor("final_aoe", (self.ability:GetLevel() - 1))
    self.velocity = self.ability:GetLevelSpecialValueFor("speed", (self.ability:GetLevel() - 1))
    self.interval = self.ability:GetLevelSpecialValueFor("summon_interval", (self.ability:GetLevel() - 1))

    self.order = RandomInt(0, 1)

    -- Cast it once at the start
    boss_queen_of_pain_sonic_wave_thinker:CastSonicWaves(self.caster, self.ability, self.projectile, self.distance, self.startingAoe, self.finalAoe, self.velocity, self.order)

    self:StartIntervalThink(self.interval)
end

function boss_queen_of_pain_sonic_wave_thinker:OnIntervalThink()
    if not IsServer() then return end

    if self.order == 0 then
        self.order = 1
    elseif self.order == 1 then
        self.order = 0
    end

    self.caster:AddNewModifier(self.caster, nil, "boss_queen_of_pain_sonic_wave_thinker_animation", { duration = self.interval })

    boss_queen_of_pain_sonic_wave_thinker:CastSonicWaves(self.caster, self.ability, self.projectile, self.distance, self.startingAoe, self.finalAoe, self.velocity, self.order)
end

function boss_queen_of_pain_sonic_wave_thinker:GetDiagonalAnglePosition(caster, delta)
    local r = RandomInt(10, 1000)

    local angle = caster:GetAnglesAsVector().y

    a = math.rad(delta)

    local point = Vector(math.cos(a), math.sin(a), 0):Normalized() * r

    return caster:GetOrigin() + point
end

function boss_queen_of_pain_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, targetPoint, projectile, position, distance, startingAoe, finalAoe, velocity)
    local info = {
        Ability = ability,
        EffectName = projectile,
        vSpawnOrigin = position,
        fDistance = distance,
        fStartRadius = startingAoe,
        fEndRadius = finalAoe,
        Source = caster,
        bHasFrontalCone = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,                            
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,                            
        bDeleteOnHit = false,
        vVelocity = ((targetPoint - position):Normalized()) * velocity,
        bProvidesVision = false
    }

    ProjectileManager:CreateLinearProjectile(info)
end

function boss_queen_of_pain_sonic_wave_thinker:CastSonicWaves(caster, ability, projectile, distance, startingAoe, finalAoe, velocity, order)
    local position = caster:GetAbsOrigin()

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_QueenOfPain.SonicWave.ArcanaLayer", caster)

    if order == 0 then
        -- First wave horizontal/vertical lines
        boss_queen_of_pain_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, Vector(position.x, position.y+distance, position.z), projectile, position, distance, startingAoe, finalAoe, velocity)
        boss_queen_of_pain_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, Vector(position.x, position.y-distance, position.z), projectile, position, distance, startingAoe, finalAoe, velocity)
        boss_queen_of_pain_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, Vector(position.x+distance, position.y, position.z), projectile, position, distance, startingAoe, finalAoe, velocity)
        boss_queen_of_pain_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, Vector(position.x-distance, position.y, position.z), projectile, position, distance, startingAoe, finalAoe, velocity)
    elseif order == 1 then
        -- Second wave diagonal lines
        boss_queen_of_pain_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, boss_queen_of_pain_sonic_wave_thinker:GetDiagonalAnglePosition(caster, 45), projectile, position, distance, startingAoe, finalAoe, velocity)
        boss_queen_of_pain_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, boss_queen_of_pain_sonic_wave_thinker:GetDiagonalAnglePosition(caster, 135), projectile, position, distance, startingAoe, finalAoe, velocity)
        boss_queen_of_pain_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, boss_queen_of_pain_sonic_wave_thinker:GetDiagonalAnglePosition(caster, 225), projectile, position, distance, startingAoe, finalAoe, velocity)
        boss_queen_of_pain_sonic_wave_thinker:CreateSonicWaveParticle(ability, caster, boss_queen_of_pain_sonic_wave_thinker:GetDiagonalAnglePosition(caster, 315), projectile, position, distance, startingAoe, finalAoe, velocity)
    end

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_QueenOfPain.SonicWave", caster)
end

function boss_queen_of_pain_sonic_wave_thinker:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true
    }
end
--------
function boss_queen_of_pain_sonic_wave_thinker_animation:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE 
    }

    return funcs
end

function boss_queen_of_pain_sonic_wave_thinker_animation:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_QueenOfPain.SonicWave.Precast.Arcana", caster)
end

function boss_queen_of_pain_sonic_wave_thinker_animation:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_4
end

function boss_queen_of_pain_sonic_wave_thinker_animation:GetOverrideAnimationRate()
    return 0.5
end
--------
function boss_queen_of_pain_sonic_wave_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function boss_queen_of_pain_sonic_wave_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true
    }

    return state
end

function boss_queen_of_pain_sonic_wave_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("movement_slow", (self:GetAbility():GetLevel() - 1))
end