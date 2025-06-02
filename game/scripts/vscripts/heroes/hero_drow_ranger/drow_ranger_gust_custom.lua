drow_ranger_gust_custom = class({})
LinkLuaModifier("modifier_drow_ranger_gust_custom", "heroes/hero_drow_ranger/drow_ranger_gust_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_frost_arrows_custom_debuff", "heroes/hero_drow_ranger/drow_ranger_frost_arrows_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drow_ranger_frost_arrows_custom_hypothermia_debuff", "heroes/hero_drow_ranger/drow_ranger_frost_arrows_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

modifier_drow_ranger_gust_custom = class(ItemBaseClass)

function drow_ranger_gust_custom:GetIntrinsicModifierName()
    return "modifier_drow_ranger_gust_custom"
end
--------------------------
function modifier_drow_ranger_gust_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_drow_ranger_gust_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end

    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")

    if not RollPercentage(chance) then return end

    local caster = self:GetCaster()
    local point = event.target:GetAbsOrigin()

    -- load data
    local speed = ability:GetSpecialValueFor( "wave_speed" )
    local width = ability:GetSpecialValueFor( "wave_width" )
    local distance = ability:GetSpecialValueFor( "distance" )

    -- create projectile
    local projectile_name = "particles/econ/items/drow/drow_ti6/drow_ti6_silence_wave.vpcf"
    local projectile_distance = distance
    local projectile_direction = point-caster:GetOrigin()
    projectile_direction.z = 0
    projectile_direction = projectile_direction:Normalized()

    local info = {
        Source = caster,
        Ability = ability,
        vSpawnOrigin = event.target:GetAbsOrigin() + 300 * event.target:GetForwardVector(),
        
        bDeleteOnHit = false,
        
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        
        EffectName = projectile_name,
        fDistance = projectile_distance,
        fStartRadius = width,
        fEndRadius = width,
        vVelocity = projectile_direction * speed,
        
        ExtraData = {
            x = caster:GetOrigin().x,
            y = caster:GetOrigin().y,
            damage = event.damage
        }
    }
    ProjectileManager:CreateLinearProjectile(info)

    -- play effects
    local sound_cast = "Hero_DrowRanger.Silence"
    EmitSoundOn( sound_cast, caster )
end
--------------------------------------------------------------------------------
-- Projectile
function drow_ranger_gust_custom:OnProjectileHit_ExtraData( target, location, data )
    if not target then return end

    local caster = self:GetCaster()

    local damage = caster:GetAverageTrueAttackDamage(caster) * (self:GetSpecialValueFor("attack_to_damage")/100)

    local frostArrows = caster:FindAbilityByName("drow_ranger_frost_arrows_custom")
    if frostArrows ~= nil and frostArrows:GetLevel() > 0 then
        local maxStacks = frostArrows:GetSpecialValueFor("max_stacks")

        local debuff = target:FindModifierByName("modifier_drow_ranger_frost_arrows_custom_debuff")
        if debuff == nil then
            debuff = target:AddNewModifier(caster, frostArrows, "modifier_drow_ranger_frost_arrows_custom_debuff", { duration = frostArrows:GetSpecialValueFor("stack_duration") })
        end

        if debuff ~= nil then
            debuff:SetStackCount(maxStacks)
            debuff:ForceRefresh()
        end
    end

    ApplyDamage({
        attacker = caster,
        victim = target,
        damage = damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = self
    })
end