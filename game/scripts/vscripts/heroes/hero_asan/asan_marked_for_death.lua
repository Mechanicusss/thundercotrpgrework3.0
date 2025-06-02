LinkLuaModifier("modifier_asan_marked_for_death", "heroes/hero_asan/asan_marked_for_death", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_asan_marked_for_death_debuff", "heroes/hero_asan/asan_marked_for_death", LUA_MODIFIER_MOTION_NONE)

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

asan_marked_for_death = class(ItemBaseClass)
modifier_asan_marked_for_death = class(asan_marked_for_death)
modifier_asan_marked_for_death_debuff = class(ItemBaseClassDebuff)
-------------
function asan_marked_for_death:GetIntrinsicModifierName()
    return "modifier_asan_marked_for_death"
end
----------------
function modifier_asan_marked_for_death:OnCreated()
    if not IsServer() then return end

    self.crit_bonus = self:GetAbility():GetSpecialValueFor("crit_damage")
end

function modifier_asan_marked_for_death:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_asan_marked_for_death:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    if target:HasModifier("modifier_asan_marked_for_death_debuff") then return end 

    local ability = self:GetAbility()

    local chance = ability:GetSpecialValueFor("chance")

    if not RollPercentage(chance) then return end

    local duration = ability:GetSpecialValueFor("duration")

    target:AddNewModifier(parent, ability, "modifier_asan_marked_for_death_debuff", {
        duration = duration
    })

    EmitSoundOn("Hero_Terrorblade.Sunder.Target", target)
end

function modifier_asan_marked_for_death:GetModifierPreAttack_CriticalStrike( params )
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        if params.target:HasModifier("modifier_asan_marked_for_death_debuff") then
            self.record = params.record

            return self.crit_bonus
        end
    end
end

function modifier_asan_marked_for_death:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
            self:PlayEffects( params.target )
        end
    end
end

function modifier_asan_marked_for_death:PlayEffects( target )
    -- Load effects
    local particle_cast = "particles/units/heroes/hero_phantom_assassin_persona/pa_persona_attack_blur_crit.vpcf"
    local sound_cast = "Hero_PhantomAssassin.CoupDeGrace.Arcana"

    -- if target:IsMechanical() then
    --  particle_cast = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact_mechanical.vpcf"
    --  sound_cast = "Hero_PhantomAssassin.CoupDeGrace.Mech"
    -- end

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlForward( effect_cast, 1, (self:GetParent():GetOrigin()-target:GetOrigin()):Normalized() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn( sound_cast, target )

    self:PlayEffects2(target)
end

function modifier_asan_marked_for_death:PlayEffects2( target )
    -- Load effects
    local particle_cast = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact_dagger.vpcf"
    local sound_cast = "Hero_PhantomAssassin.CoupDeGrace"

    -- if target:IsMechanical() then
    --  particle_cast = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact_mechanical.vpcf"
    --  sound_cast = "Hero_PhantomAssassin.CoupDeGrace.Mech"
    -- end

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlForward( effect_cast, 1, (self:GetParent():GetOrigin()-target:GetOrigin()):Normalized() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn( sound_cast, target )
end
----------------
function modifier_asan_marked_for_death_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.burstEffect = ParticleManager:CreateParticle( "particles/econ/items/phantom_assassin/pa_crimson_witness_2021/pa_crimson_witness_blur_ambient.vpcf", PATTACH_POINT_FOLLOW, parent )
    
    ParticleManager:SetParticleControlEnt(
        self.burstEffect,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    ParticleManager:SetParticleControlEnt(
        self.burstEffect,
        1,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    ParticleManager:SetParticleControlEnt(
        self.burstEffect,
        3,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    self.damage = 0
end

function modifier_asan_marked_for_death_debuff:OnDestroy()
    if not IsServer() then return end

    if self.burstEffect ~= nil then
        ParticleManager:DestroyParticle(self.burstEffect, false)
        ParticleManager:ReleaseParticleIndex(self.burstEffect)
    end

    if not self:GetCaster():HasModifier("modifier_item_aghanims_shard") then return end

    local damage = self.damage * (self:GetAbility():GetSpecialValueFor("end_damage_pct")/100)

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        ability = self:GetAbility(),
        damage_type = DAMAGE_TYPE_PHYSICAL,
        damage = damage
    })
end

function modifier_asan_marked_for_death_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_asan_marked_for_death_debuff:GetModifierIncomingDamage_Percentage(event)
   if event.attacker == self:GetCaster() then
    self.damage = self.damage + event.damage
   end 
end