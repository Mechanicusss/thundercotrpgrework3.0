LinkLuaModifier("modifier_faceless_void_time_dilation_custom", "heroes/hero_faceless_void/faceless_void_time_dilation_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_faceless_void_time_dilation_custom_debuff", "heroes/hero_faceless_void/faceless_void_time_dilation_custom", LUA_MODIFIER_MOTION_NONE)

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

faceless_void_time_dilation_custom = class(ItemBaseClass)
modifier_faceless_void_time_dilation_custom = class(faceless_void_time_dilation_custom)
modifier_faceless_void_time_dilation_custom_debuff = class(ItemBaseClassDebuff)
-------------
function faceless_void_time_dilation_custom:GetIntrinsicModifierName()
    return "modifier_faceless_void_time_dilation_custom"
end

function modifier_faceless_void_time_dilation_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE
    }
    return funcs
end

function modifier_faceless_void_time_dilation_custom:GetModifierProcAttack_BonusDamage_Pure(params)
    if IsServer() then
        if not self:GetParent():HasModifier("modifier_item_aghanims_shard") then return 0 end
        -- get target
        local target = params.target if target==nil then target = params.unit end
        if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
            return 0
        end

        if not target:HasModifier("modifier_faceless_void_time_dilation_custom_debuff") then return 0 end

        -- return damage bonus
        local total = params.damage * (self:GetAbility():GetSpecialValueFor("shard_damage_bonus_pure")/100)
        
        return total
    end
end

function modifier_faceless_void_time_dilation_custom:OnAttack(event)
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
    local radius = ability:GetSpecialValueFor("radius")

    if not ability:IsCooldownReady() then return end

    local victims = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        victim:AddNewModifier(parent, ability, "modifier_faceless_void_time_dilation_custom_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })

        EmitSoundOn("Hero_FacelessVoid.TimeDilation.Target", victim)
        self:PlayEffects2(victim)
    end

    self:PlayEffects(victim, radius)

    ability:UseResources(false, false, false, true)
end

function modifier_faceless_void_time_dilation_custom:PlayEffects(target, radius)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_faceless_void/faceless_void_timedialate.vpcf"
    local sound_cast = "Hero_FacelessVoid.TimeDilation.Cast"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_POINT_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl(effect_cast, 1, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(effect_cast)

    -- Create Sound
    EmitSoundOn(sound_cast, target)
end

function modifier_faceless_void_time_dilation_custom:PlayEffects2(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_faceless_void/faceless_void_time_lock_bash.vpcf"
    local sound_cast = "Hero_FacelessVoid.TimeLockImpact"

    -- Get Data
    local forward = (target:GetOrigin()-self:GetCaster():GetOrigin()):Normalized()

    -- Create Particle
    local particle = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, target )
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin() )
    ParticleManager:SetParticleControlEnt(particle, 2, self.parent, PATTACH_CUSTOMORIGIN, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
-----------
function modifier_faceless_void_time_dilation_custom_debuff:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true,
    }
end

function modifier_faceless_void_time_dilation_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_faceless_void_time_dilation_custom_debuff:GetModifierIncomingDamage_Percentage(event)
    if event.attacker ~= self:GetCaster() then return end

    return self:GetAbility():GetSpecialValueFor("shard_damage_bonus_pct")
end

function modifier_faceless_void_time_dilation_custom_debuff:GetStatusEffectName()
    return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_faceless_void_time_dilation_custom_debuff:GetEffectName()
    return "particles/status_fx/status_effect_faceless_chronosphere.vpcf"
end