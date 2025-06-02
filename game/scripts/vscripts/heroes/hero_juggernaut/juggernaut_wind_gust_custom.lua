LinkLuaModifier("modifier_juggernaut_wind_gust_custom", "heroes/hero_juggernaut/juggernaut_wind_gust_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_juggernaut_wind_gust_custom_debuff", "heroes/hero_juggernaut/juggernaut_wind_gust_custom", LUA_MODIFIER_MOTION_NONE)

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

juggernaut_wind_gust_custom = class(ItemBaseClass)
modifier_juggernaut_wind_gust_custom = class(juggernaut_wind_gust_custom)
modifier_juggernaut_wind_gust_custom_debuff = class(ItemBaseClassDebuff)
-------------
function juggernaut_wind_gust_custom:GetIntrinsicModifierName()
    return "modifier_juggernaut_wind_gust_custom"
end

function modifier_juggernaut_wind_gust_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }
    return funcs
end

function modifier_juggernaut_wind_gust_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_juggernaut_wind_gust_custom:OnAttack(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()
    if not ability:IsCooldownReady() then return end

    self:CastDeafeningBlast(caster, ability, victim:GetAbsOrigin())

    ability:UseResources(false, false, false, true)
end

function modifier_juggernaut_wind_gust_custom:CastDeafeningBlast(caster, ability, target_point)
    if IsServer() then
        EmitSoundOn("Hero_Invoker.Tornado.Cast", caster)

        local caster_location   = caster:GetAbsOrigin()

        local baseDamage = ability:GetSpecialValueFor("damage")

        if caster:HasTalent("special_bonus_unique_juggernaut_7_custom") then
            baseDamage = baseDamage + caster:FindAbilityByName("special_bonus_unique_juggernaut_7_custom"):GetSpecialValueFor("value")
        end

        -- Get skill stats
        local deafening_blast_damage                = baseDamage + (caster:GetAgility() * (ability:GetSpecialValueFor("agi_to_damage")/100))
        local deafening_blast_travel_distance       = ability:GetSpecialValueFor("distance")
        local deafening_blast_travel_speed          = ability:GetSpecialValueFor("speed")
        local deafening_blast_radius_start          = ability:GetSpecialValueFor("radius_start")
        local deafening_blast_radius_end            = ability:GetSpecialValueFor("radius_end")

        if caster:HasTalent("special_bonus_unique_juggernaut_5_custom") then
            local attackDamage = caster:GetAverageTrueAttackDamage(caster) * (caster:FindAbilityByName("special_bonus_unique_juggernaut_5_custom"):GetSpecialValueFor("value")/100)
            deafening_blast_damage = deafening_blast_damage + attackDamage
        end

        local direction = (target_point - caster_location):Normalized()
        direction.z     = 0

        -- Create projectile
        local deafening_blast_projectile_table = 
        {
            EffectName          = "particles/units/heroes/hero_invoker/invoker_tornado_2.vpcf",
            Ability             = ability,
            vSpawnOrigin        = caster:GetAbsOrigin(),
            vVelocity           = direction * deafening_blast_travel_speed,
            fDistance           = deafening_blast_travel_distance,
            fStartRadius        = deafening_blast_radius_start,
            fEndRadius          = deafening_blast_radius_end,
            Source              = caster,
            bHasFrontalCone     = true,
            bReplaceExisting    = false,
            iUnitTargetTeam     = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags    = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType     = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            ExtraData = {
                deafening_blast_damage              = deafening_blast_damage, 
            }
        }

        ProjectileManager:CreateLinearProjectile(deafening_blast_projectile_table)
    end
end

function juggernaut_wind_gust_custom:OnProjectileHit_ExtraData(target, location, ExtraData)
    if IsServer() then
        if target then
            if target:IsMagicImmune() then return end
            local caster = self:GetCaster()
            local target_entity_index = target:GetEntityIndex()
            -- Apply deafening blast damage
            ApplyDamage({
                attacker = caster,
                victim = target,
                ability = self,
                damage_type = self:GetAbilityDamageType(),
                damage = ExtraData.deafening_blast_damage
            })

            EmitSoundOn("Hero_Invoker.Tornado.Target", target)

            local debuff = target:FindModifierByName("modifier_juggernaut_wind_gust_custom_debuff")
            if not debuff then
                debuff = target:AddNewModifier(caster, self, "modifier_juggernaut_wind_gust_custom_debuff", {
                    duration = self:GetSpecialValueFor("debuff_duration")
                })
            end

            if debuff then
                debuff:ForceRefresh()
            end
        end
    end 
end
---------------------------
function modifier_juggernaut_wind_gust_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_MISS_PERCENTAGE 
    }
end

function modifier_juggernaut_wind_gust_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_juggernaut_wind_gust_custom_debuff:GetModifierMiss_Percentage()
    return self:GetAbility():GetSpecialValueFor("miss")
end