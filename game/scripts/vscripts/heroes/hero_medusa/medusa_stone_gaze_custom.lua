LinkLuaModifier("modifier_medusa_stone_gaze_custom", "heroes/hero_medusa/medusa_stone_gaze_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_stone_gaze_custom_slow", "heroes/hero_medusa/medusa_stone_gaze_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_medusa_stone_gaze_custom_stone", "heroes/hero_medusa/medusa_stone_gaze_custom", LUA_MODIFIER_MOTION_NONE)

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

medusa_stone_gaze_custom = class(ItemBaseClass)
modifier_medusa_stone_gaze_custom = class(medusa_stone_gaze_custom)
modifier_medusa_stone_gaze_custom_slow = class(ItemBaseClassDebuff)
modifier_medusa_stone_gaze_custom_stone = class(ItemBaseClassDebuff)
-------------
function medusa_stone_gaze_custom:GetIntrinsicModifierName()
    return "modifier_medusa_stone_gaze_custom"
end

function modifier_medusa_stone_gaze_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_medusa_stone_gaze_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_medusa_stone_gaze_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if not unit:IsRealHero() or unit:IsIllusion() or (not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim)) then return end

    local ability = self:GetAbility()
    local chance = ability:GetSpecialValueFor("chance")

    if not RollPseudoRandomPercentage(chance, 98, unit) then return end

    if not victim:HasModifier("modifier_medusa_stone_gaze_custom_slow") and not victim:HasModifier("modifier_medusa_stone_gaze_custom_stone") then
        local slow = victim:AddNewModifier(unit, ability, "modifier_medusa_stone_gaze_custom_slow", {
            duration = ability:GetSpecialValueFor("face_duration")
        })
        EmitSoundOn("Hero_Medusa.StoneGaze.Target", victim)
    end
end

function modifier_medusa_stone_gaze_custom_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }

    return funcs
end

function modifier_medusa_stone_gaze_custom_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_medusa_stone_gaze_custom_slow:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if not parent:HasModifier("modifier_medusa_stone_gaze_custom_stone") then
        local slow = parent:AddNewModifier(caster, ability, "modifier_medusa_stone_gaze_custom_stone", {
            duration = ability:GetSpecialValueFor("stone_duration")
        })
        EmitSoundOn("Hero_Medusa.StoneGaze.Stun", parent)
    end
end

function modifier_medusa_stone_gaze_custom_slow:GetStatusEffectName()
    return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end
--
function modifier_medusa_stone_gaze_custom_stone:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE   
    }

    return funcs
end

function modifier_medusa_stone_gaze_custom_stone:GetModifierIncomingPhysicalDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_physical_damage")
end

function modifier_medusa_stone_gaze_custom_stone:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
    }

    return state
end

function modifier_medusa_stone_gaze_custom_stone:OnCreated()
    if not IsServer() then return end

    self:PlayEffects()
end

function modifier_medusa_stone_gaze_custom_stone:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local victim = self:GetParent()
    local ability = self:GetAbility()

    if not caster:HasScepter() then return end

    local victims = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
            ability:GetSpecialValueFor("explosion_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        ApplyDamage({
            victim = victim, 
            attacker = caster, 
            damage = victim:GetMaxHealth() * (ability:GetSpecialValueFor("explosion_max_hp_damage")/100), 
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = ability
        })

        self:PlayEffects2(victim, ability:GetSpecialValueFor("explosion_radius"))
    end
end

function modifier_medusa_stone_gaze_custom_stone:GetStatusEffectName()
    return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end

function modifier_medusa_stone_gaze_custom_stone:StatusEffectPriority(  )
    return MODIFIER_PRIORITY_ULTRA
end

function modifier_medusa_stone_gaze_custom_stone:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetParent(),
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector( 0,0,0 ), -- unknown
        true -- unknown, true
    )

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )
end

function modifier_medusa_stone_gaze_custom_stone:PlayEffects2(target, radius)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_earth_spirit/espirit_stone_explosion.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( effect_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(effect_cast, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(effect_cast, 2, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(radius, radius, radius), true)

    -- buff particle
    self:AddParticle(
        effect_cast,
        false, -- bDestroyImmediately
        false, -- bStatusEffect
        -1, -- iPriority
        false, -- bHeroEffect
        false -- bOverheadEffect
    )
end