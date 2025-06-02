LinkLuaModifier("modifier_lina_dragon_slave_custom", "heroes/hero_lina/lina_dragon_slave_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_dragon_slave_custom_stack", "heroes/hero_lina/lina_dragon_slave_custom", LUA_MODIFIER_MOTION_NONE)

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

lina_dragon_slave_custom = class(ItemBaseClass)
modifier_lina_dragon_slave_custom = class(lina_dragon_slave_custom)
modifier_lina_dragon_slave_custom_stack = class(ItemBaseClassDebuff)
-------------
function modifier_lina_dragon_slave_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_lina_dragon_slave_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end
    if parent:IsSilenced() then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() or ability:GetManaCost(-1) > parent:GetMana() then return end
    if not ability:GetAutoCastState() then return end

    local point = event.target

    parent:StartGesture(ACT_DOTA_CAST_ABILITY_1)
    SpellCaster:Cast(ability, point, true)
end
-------------
function lina_dragon_slave_custom:GetIntrinsicModifierName()
  return "modifier_lina_dragon_slave_custom"
end

function lina_dragon_slave_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local point = self:GetCursorPosition()

    if target then
        point = target:GetOrigin()
    end

    local projectile_name = "particles/units/heroes/hero_lina/lina_spell_dragon_slave.vpcf"
    local projectile_distance = self:GetSpecialValueFor( "dragon_slave_distance" )
    local projectile_speed = self:GetSpecialValueFor( "dragon_slave_speed" )
    local projectile_start_radius = self:GetSpecialValueFor( "dragon_slave_width_initial" )
    local projectile_end_radius = self:GetSpecialValueFor( "dragon_slave_width_end" )

    local direction = point-caster:GetOrigin()
    direction.z = 0
    local projectile_direction = direction:Normalized()

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
        fEndRadius = projectile_end_radius,
        vVelocity = projectile_direction * projectile_speed,

        bProvidesVision = false,
    }

    ProjectileManager:CreateLinearProjectile(info)

    if caster:HasModifier("modifier_item_aghanims_shard") then
        -- First
        local count = 3
        local fullAngle = 60
        local factor = fullAngle/(count-1)

        vDirection = RotatePosition(Vector(0,0,0), QAngle(0, 20, 0), projectile_direction)

        local shardDirection = vDirection
        shardDirection.z = 0
        shardDirection = shardDirection:Normalized()

        info.vVelocity = shardDirection * projectile_speed
        
        local projectile2 = ProjectileManager:CreateLinearProjectile(info)

        -- Second
        vDirection = RotatePosition(Vector(0,0,0), QAngle(0, -20, 0), projectile_direction)

        local shardDirection = vDirection
        shardDirection.z = 0
        shardDirection = shardDirection:Normalized()

        info.vVelocity = shardDirection * projectile_speed
        
        local projectile3 = ProjectileManager:CreateLinearProjectile(info)
    end

    -- Play effects
    local sound_cast = "Hero_Lina.DragonSlave.Cast"
    local sound_projectile = "Hero_Lina.DragonSlave"
    EmitSoundOn( sound_cast, self:GetCaster() )
    EmitSoundOn( sound_projectile, self:GetCaster() )
end

function lina_dragon_slave_custom:OnProjectileHitHandle( target, location, projectile )
    if not target then return end

    local caster = self:GetCaster()

    local debuff = target:FindModifierByName("modifier_lina_dragon_slave_custom_stack")

    local damage = self:GetSpecialValueFor("dragon_slave_damage") + (caster:GetBaseIntellect() * (self:GetSpecialValueFor("int_to_damage")/100))

    local fierySoul = caster:FindModifierByName("modifier_lina_fiery_soul_custom")
    if fierySoul then
        local fierySoul_Ability = fierySoul:GetAbility()

        damage = damage + (fierySoul_Ability:GetSpecialValueFor("fiery_soul_spell_damage") * fierySoul:GetStackCount())
    end

    -- apply damage
    local damageTable = {
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }
    ApplyDamage( damageTable )

    if not debuff then
        debuff = target:AddNewModifier(caster, self, "modifier_lina_dragon_slave_custom_stack", {
            duration = self:GetSpecialValueFor("debuff_duration")
        })
    end

    if debuff then
        if debuff:GetStackCount() < self:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end

    -- get direction
    local direction = ProjectileManager:GetLinearProjectileVelocity( projectile )
    direction.z = 0
    direction = direction:Normalized()

    -- play effects
    self:PlayEffects( target, direction )
end

function lina_dragon_slave_custom:PlayEffects( target, direction )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_lina/lina_spell_dragon_slave_impact.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlForward( effect_cast, 1, direction )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
----------
function modifier_lina_dragon_slave_custom_stack:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP 
    }
end

function modifier_lina_dragon_slave_custom_stack:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("dmg_increase_per_stack_pct") * self:GetStackCount()
end

function modifier_lina_dragon_slave_custom_stack:GetModifierIncomingDamage_Percentage(event)
    local caster = self:GetCaster()

    if event.attacker ~= caster then return end

    local parent = self:GetParent()

    if event.target ~= parent then return end
    if not event.inflictor then return end
    if event.inflictor:GetAbilityName() ~= "lina_dragon_slave_custom" then return end
    if self:GetStackCount() < 1 then return end

    return self:GetAbility():GetSpecialValueFor("dmg_increase_per_stack_pct") * self:GetStackCount()
end