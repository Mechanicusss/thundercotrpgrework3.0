boss_sand_burrow = class({})
modifier_boss_sand_burrow_thinker_casting = class({})
LinkLuaModifier( "modifier_boss_sand_burrow", "heroes/bosses/sand/burrow", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_stunned_lua", "modifiers/modifier_generic_stunned_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_knockback_lua", "modifiers/modifier_generic_knockback_lua", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier( "modifier_boss_sand_burrow_thinker", "heroes/bosses/sand/burrow", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_boss_sand_burrow_thinker_casting", "heroes/bosses/sand/burrow", LUA_MODIFIER_MOTION_NONE )

_G.SandKingBurrowInitialLoc = nil

modifier_boss_sand_burrow_thinker = class({})
function modifier_boss_sand_burrow_thinker:IsHidden() return true end
function modifier_boss_sand_burrow_thinker:IsPurgable() return false end
function modifier_boss_sand_burrow_thinker:RemoveOnDeath() return false end

function boss_sand_burrow:GetIntrinsicModifierName()
    return "modifier_boss_sand_burrow_thinker"
end

function modifier_boss_sand_burrow_thinker_casting:IsHidden() return true end
function modifier_boss_sand_burrow_thinker_casting:IsPurgable() return false end
function modifier_boss_sand_burrow_thinker_casting:RemoveOnDeath() return false end

function modifier_boss_sand_burrow_thinker_casting:CheckState()
    local state = {
        [MODIFIER_STATE_CANNOT_TARGET_ENEMIES] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    }
    return state
end

function modifier_boss_sand_burrow_thinker_casting:OnCreated()
    if not IsServer() then return end

    self:GetParent():SetAttacking(nil)
    self:GetParent():SetForceAttackTarget(nil)

    self.cap = self:GetParent():GetAttackCapability()

    self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_1)

    self:GetParent():SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

    self:GetParent():AddNoDraw()
end

function modifier_boss_sand_burrow_thinker_casting:OnDestroy()
    if not IsServer() then return end

    self:GetParent():SetAttackCapability(self.cap)
    self:GetParent():RemoveGesture(ACT_DOTA_CAST_ABILITY_1)
    self:GetParent():RemoveNoDraw()
end

function modifier_boss_sand_burrow_thinker:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_boss_sand_burrow_thinker:OnIntervalThink()
    local parent = self:GetParent()

    local burrow = self:GetAbility()
    if parent:IsAttacking() and burrow:IsCooldownReady() and not parent:IsSilenced() then
        parent:AddNewModifier(parent, burrow, "modifier_boss_sand_burrow_thinker_casting", { duration = 10.5 })
        parent:CastAbilityImmediately(burrow, 1)
    end
end

--------------------------------------------------------------------------------
-- Custom KV
-- function boss_sand_burrow:GetCooldown( level )
--  if self:GetCaster():HasScepter() then
--      return self:GetSpecialValueFor( "cooldown_scepter" )
--  end

--  return self.BaseClass.GetCooldown( self, level )
-- end

--------------------------------------------------------------------------------
-- Ability Start
BURROW_TIMER = nil
function boss_sand_burrow:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local point = self:GetCursorPosition()
    if target then point = target:GetOrigin() end
    local origin = caster:GetOrigin()

    if _G.SandKingBurrowInitialLoc == nil then
        caster:AddNewModifier(caster, self, "modifier_boss_sand_burrow_thinker_casting", { duration = 10.5 })
        _G.SandKingBurrowInitialLoc = caster:GetAbsOrigin()
    end

    local randomPosInt = 1
    if RollPercentage(50) then randomPosInt = -1 end

    local randomLoc = Vector(_G.SandKingBurrowInitialLoc.x+(RandomInt(300, 600)*randomPosInt), _G.SandKingBurrowInitialLoc.y+(RandomInt(300, 600)*randomPosInt), _G.SandKingBurrowInitialLoc.z)
    point = randomLoc

    caster:SetForwardVector(point)

    -- load data
    local anim_time = self:GetSpecialValueFor("burrow_anim_time")

    -- projectile data
    local projectile_name = "particles/units/heroes/hero_sandking/sandking_burrowstrike.vpcf"
    local projectile_start_radius = self:GetSpecialValueFor("burrow_width")
    local projectile_end_radius = projectile_start_radius
    local projectile_direction = (point-origin)
    projectile_direction.z = 0
    projectile_direction:Normalized()
    local projectile_speed = self:GetSpecialValueFor("burrow_speed")
    local projectile_distance = (point-origin):Length2D()

    -- create projectile
    local info = {
        Source = caster,
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin(),
        
        bDeleteOnHit = false,
        
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        
        EffectName = projectile_name,
        fDistance = projectile_distance,
        fStartRadius = projectile_start_radius,
        fEndRadius =projectile_end_radius,
        vVelocity = projectile_direction * projectile_speed,
    }
    ProjectileManager:CreateLinearProjectile(info)

    -- add modifier to caster
    caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_boss_sand_burrow", -- modifier name
        { 
            duration = anim_time,
            pos_x = point.x,
            pos_y = point.y,
            pos_z = point.z,
        } -- kv
    )

    self:PlayEffects( origin, point )

    if BURROW_TIMER == nil then
        BURROW_TIMER = Timers:CreateTimer(0.75, function()
            if not caster:HasModifier("modifier_boss_sand_burrow_thinker_casting") then 
                caster:SetAbsOrigin(_G.SandKingBurrowInitialLoc)
                _G.SandKingBurrowInitialLoc = nil 
                Timers:RemoveTimer(BURROW_TIMER)
                BURROW_TIMER = nil
                return 
            end
            self:OnSpellStart()
            return 0.75
        end)
    end
end
--------------------------------------------------------------------------------
-- Projectile
function boss_sand_burrow:OnProjectileHit( target, location )
    if not target then return end

    -- cancel if linken
    if target:TriggerSpellAbsorb( self ) then return end

    -- apply stun
    local duration = self:GetSpecialValueFor( "burrow_duration" )
    target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_generic_stunned_lua", -- modifier name
        { duration = duration } -- kv
    )

    -- apply knockback
    target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_generic_knockback_lua", -- modifier name
        {
            duration = 0.52,
            z = 350,
            IsStun = true,
        } -- kv
    )

    -- apply damage
    local damageTable = {
        victim = target,
        attacker = self:GetCaster(),
        damage = self:GetAbilityDamage(),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self, --Optional.
    }
    ApplyDamage(damageTable)
end

--------------------------------------------------------------------------------
function boss_sand_burrow:PlayEffects( origin, target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_sandking/sandking_burrowstrike.vpcf"
    local sound_cast = "Ability.SandKing_BurrowStrike"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( effect_cast, 0, origin )
    ParticleManager:SetParticleControl( effect_cast, 1, target )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )
end

modifier_boss_sand_burrow = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_boss_sand_burrow:IsHidden()
    return true
end

function modifier_boss_sand_burrow:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_boss_sand_burrow:OnCreated( kv )
    if IsServer() then
        -- references
        self.point = Vector( kv.pos_x, kv.pos_y, kv.pos_z )

        -- Start interval
        self:StartIntervalThink( self:GetDuration()/2 )
    end
end

function modifier_boss_sand_burrow:OnDestroy( kv )

end

function modifier_boss_sand_burrow:OnIntervalThink()
    FindClearSpaceForUnit( self:GetParent(), self.point, true )
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_boss_sand_burrow:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
    }

    return state
end