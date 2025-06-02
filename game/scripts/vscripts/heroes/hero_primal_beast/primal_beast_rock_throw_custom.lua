LinkLuaModifier("modifier_primal_beast_rock_throw_custom", "heroes/hero_primal_beast/primal_beast_rock_throw_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_primal_beast_rock_throw_custom_debuff", "heroes/hero_primal_beast/primal_beast_rock_throw_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_primal_beast_rock_throw_custom_buff", "heroes/hero_primal_beast/primal_beast_rock_throw_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

primal_beast_rock_throw_custom = class(ItemBaseClass)
modifier_primal_beast_rock_throw_custom = class(primal_beast_rock_throw_custom)
modifier_primal_beast_rock_throw_custom_debuff = class(ItemBaseClassDebuff)
modifier_primal_beast_rock_throw_custom_buff = class(ItemBaseClassBuff)
-------------
function primal_beast_rock_throw_custom:GetIntrinsicModifierName()
    return "modifier_primal_beast_rock_throw_custom"
end

function primal_beast_rock_throw_custom:OnProjectileHit_ExtraData(hTarget, hLoc, extraData)
    if not hTarget then return end

    local caster = self:GetCaster()

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_primal_beast/primal_beast_rock_throw_impact.vpcf", PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, hTarget:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 3, hTarget:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_PrimalBeast.RockThrow.Impact", hTarget)

    local damage = caster:GetStrength() * (self:GetSpecialValueFor("strength_multiplier")/100)
    if extraData.split == 1 then
        damage = damage * (self:GetSpecialValueFor("split_damage_pct")/100)
    end

    ApplyDamage({
        attacker = caster,
        victim = hTarget,
        damage = damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = self
    })

    hTarget:AddNewModifier(caster, self, "modifier_primal_beast_rock_throw_custom_debuff", {
        duration = self:GetSpecialValueFor("debuff_duration")
    })

    if extraData.split == 1 then return end

    local maxTargets = self:GetSpecialValueFor("max_split_targets")
    local i = 0

    local victims = FindUnitsInRadius(caster:GetTeam(), hTarget:GetAbsOrigin(), nil,
            self:GetSpecialValueFor("split_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if enemy:IsAlive() and not enemy:IsAttackImmune() and not enemy:IsInvulnerable() and enemy ~= hTarget then
            if i < maxTargets then
                local spawnOrigin = hTarget:GetAbsOrigin()
                local point = enemy:GetAbsOrigin()
                local collision_radius = 225
                local vision_distance = 300
                local travel_speed = 1058
                local distance = (point - spawnOrigin):Length2D()
                local direction = (point - spawnOrigin):Normalized()
                local velocity = direction * travel_speed

                local projectile =  {
                    EffectName          = "particles/units/heroes/hero_primal_beast/primal_beast_rock_throw_arc.vpcf",
                    Ability             = self,
                    vSpawnOrigin        = spawnOrigin,
                    fDistance           = distance,
                    fStartRadius        = collision_radius,
                    fEndRadius          = collision_radius,
                    Source              = hTarget,
                    bProvidesVision     = true,
                    iVisionTeamNumber   = caster:GetTeam(),
                    iVisionRadius       = vision_distance,
                    bDrawsOnMinimap     = false,
                    bVisibleToEnemies   = true, 
                    iUnitTargetTeam     = DOTA_UNIT_TARGET_TEAM_ENEMY,
                    iUnitTargetFlags    = DOTA_UNIT_TARGET_FLAG_NONE,
                    iUnitTargetType     = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                    vVelocity           = velocity,
                    iMoveSpeed = travel_speed,
                    Target = enemy,
                    ExtraData = {
                        split = 1
                    }
                }               

                ProjectileManager:CreateTrackingProjectile(projectile)

                EmitSoundOn("Hero_PrimalBeast.RockThrow.Projectile", hTarget)
            else
                return
            end

            i = i + 1
        end
    end
end
----------------
function modifier_primal_beast_rock_throw_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_EVENT_ON_ATTACK,
        --MODIFIER_PROPERTY_FIXED_ATTACK_RATE 
    }
end

function modifier_primal_beast_rock_throw_custom:GetModifierFixedAttackRate()
    return self:GetAbility():GetSpecialValueFor("fixed_attack_rate")
end

function modifier_primal_beast_rock_throw_custom:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("attack_range_bonus")
end

function modifier_primal_beast_rock_throw_custom:GetPriority()
    return 99999
end

function modifier_primal_beast_rock_throw_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    local point = target:GetAbsOrigin()
    local spawnOrigin = parent:GetAbsOrigin()

    local collision_radius = 225
    local vision_distance = 300
    local travel_speed = 1222
    local distance = (point - spawnOrigin):Length2D()
    local direction = (point - spawnOrigin):Normalized()
    local velocity = direction * travel_speed

    local projectile =  {
        EffectName          = "particles/units/heroes/hero_primal_beast/primal_beast_rock_throw.vpcf",
        Ability             = ability,
        vSpawnOrigin        = spawnOrigin,
        fDistance           = distance,
        fStartRadius        = collision_radius,
        fEndRadius          = collision_radius,
        Source              = parent,
        bProvidesVision     = true,
        iVisionTeamNumber   = parent:GetTeam(),
        iVisionRadius       = vision_distance,
        bDrawsOnMinimap     = false,
        bVisibleToEnemies   = true, 
        iUnitTargetTeam     = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags    = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType     = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        vVelocity           = velocity,
        iMoveSpeed = 1222,
        Target = target,
        ExtraData = {
            split = 0
        }
    }  
    
    EmitSoundOn("Hero_PrimalBeast.RockThrow.Cast", caster)
    EmitSoundOn("Hero_PrimalBeast.RockThrow.Projectile", caster)

    ProjectileManager:CreateTrackingProjectile(projectile)

    local buff = parent:FindModifierByName("modifier_primal_beast_rock_throw_custom_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_primal_beast_rock_throw_custom_buff", {
            duration = ability:GetSpecialValueFor("strength_duration")
        })
    end

    if buff then
        if buff:GetStackCount() < ability:GetSpecialValueFor("strength_max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end

    ability:UseResources(false, false, false, true)
end
--------------
function modifier_primal_beast_rock_throw_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_primal_beast_rock_throw_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("debuff_increased_slow")
end

function modifier_primal_beast_rock_throw_custom_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("debuff_increased_damage")
end
------------------
function modifier_primal_beast_rock_throw_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    }
end

function modifier_primal_beast_rock_throw_custom_buff:OnCreated()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.strength = parent:GetStrength() * (ability:GetSpecialValueFor("strength_bonus_per_primary_rock")/100) 
end

function modifier_primal_beast_rock_throw_custom_buff:GetModifierBonusStats_Strength()
    return self.strength * self:GetStackCount()
end