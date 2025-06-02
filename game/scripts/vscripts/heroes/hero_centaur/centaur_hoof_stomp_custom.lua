LinkLuaModifier("modifier_centaur_hoof_stomp_custom", "heroes/hero_centaur/centaur_hoof_stomp_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_centaur_hoof_stomp_custom_debuff", "heroes/hero_centaur/centaur_hoof_stomp_custom", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

centaur_hoof_stomp_custom = class(ItemBaseClass)
modifier_centaur_hoof_stomp_custom = class(centaur_hoof_stomp_custom)
modifier_centaur_hoof_stomp_custom_debuff = class(ItemBaseClassDebuff)
-------------
function centaur_hoof_stomp_custom:GetIntrinsicModifierName()
    return "modifier_centaur_hoof_stomp_custom"
end

function modifier_centaur_hoof_stomp_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK 
    }
    return funcs
end

function modifier_centaur_hoof_stomp_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_centaur_hoof_stomp_custom:OnAttack(event)
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

    caster:FadeGesture(ACT_DOTA_CAST_ABILITY_1)

    local ability = self:GetAbility()
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
    local damage = ability:GetLevelSpecialValueFor("damage", (ability:GetLevel() - 1))
    local strengthMulti = ability:GetLevelSpecialValueFor("strength_damage", (ability:GetLevel() - 1))
    local chance = ability:GetLevelSpecialValueFor("chance", (ability:GetLevel() - 1))

    if not RollPercentage(chance) then return end

    self:PlayEffects(caster, radius)

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        ApplyDamage({
            victim = victim, 
            ability = ability,
            attacker = caster, 
            damage = damage + (caster:GetStrength() * (strengthMulti / 100)), 
            damage_type = DAMAGE_TYPE_MAGICAL
        })

        local debuff = victim:FindModifierByName("modifier_centaur_hoof_stomp_custom_debuff")
        if debuff == nil then
            debuff = victim:AddNewModifier(caster, ability, "modifier_centaur_hoof_stomp_custom_debuff", {
                duration = ability:GetSpecialValueFor("stack_duration")
            })
        end

        if debuff ~= nil then
            if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
                debuff:IncrementStackCount()
            end

            debuff:ForceRefresh()
        end
    end

    --EmitSoundOnLocationWithCaster( caster:GetOrigin(), "Hero_Centaur.HoofStomp", caster )
end

--------------------------------------------------------------------------------
function modifier_centaur_hoof_stomp_custom:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/econ/items/centaur/centaur_ti6/centaur_ti6_warstomp.vpcf"
    local sound_cast = "Hero_Centaur.HoofStomp"
    

    -- Get Data
    local offset = 100
    local caster = self:GetCaster()
    local origin = caster:GetOrigin()
    local direction_normalized = (target:GetOrigin() - origin):Normalized()
    local final_position = origin + Vector(direction_normalized.x * offset, direction_normalized.y * offset, 0)

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(effect_cast, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)

    EmitSoundOn(sound_cast, caster)
end
----------
function modifier_centaur_hoof_stomp_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE, --GetModifierAttackSpeedPercentage
    }
end

function modifier_centaur_hoof_stomp_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow_per_stack") * self:GetStackCount()
end

function modifier_centaur_hoof_stomp_custom_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("slow_per_stack") * self:GetStackCount()
end

function modifier_centaur_hoof_stomp_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res_per_stack") * self:GetStackCount()
end

function modifier_centaur_hoof_stomp_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end