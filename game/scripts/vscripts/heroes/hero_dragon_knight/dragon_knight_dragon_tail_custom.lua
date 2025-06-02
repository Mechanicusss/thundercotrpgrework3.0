LinkLuaModifier("modifier_dragon_knight_dragon_tail_custom", "heroes/hero_dragon_knight/dragon_knight_dragon_tail_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

dragon_knight_dragon_tail_custom = class(ItemBaseClass)
modifier_dragon_knight_dragon_tail_custom = class(dragon_knight_dragon_tail_custom)
-------------
function dragon_knight_dragon_tail_custom:GetIntrinsicModifierName()
    return "modifier_dragon_knight_dragon_tail_custom"
end

function dragon_knight_dragon_tail_custom:GetCooldown(level)
    local ab = self:GetCaster():FindAbilityByName("special_bonus_unique_dragon_knight_3_custom")
    if ab ~= nil and ab:GetLevel() > 0 then
        return self.BaseClass.GetCooldown(self, level) - ab:GetSpecialValueFor("value")
    end

    return self.BaseClass.GetCooldown(self, level) or 0
end

function modifier_dragon_knight_dragon_tail_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_dragon_knight_dragon_tail_custom:OnCreated()
end

function modifier_dragon_knight_dragon_tail_custom:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if victim ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()
    
    if not RollPercentage(ability:GetSpecialValueFor("chance")) or not ability:IsCooldownReady() then return end

    local projectile_name = "particles/units/heroes/hero_dragon_knight/dragon_knight_dragon_tail_dragonform_proj.vpcf"
    local projectile_speed = 1600

    -- create projectile
    local info = {
        Target = unit,
        Source = victim,
        Ability = ability,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
        EffectName = projectile_name,
        iMoveSpeed = projectile_speed,
        bDodgeable = true,                           -- Optional
    }

    ProjectileManager:CreateTrackingProjectile(info)

    ability:UseResources(false, false, false, true)
end

function dragon_knight_dragon_tail_custom:OnProjectileHit(target, location)
    if not target then return end

    local caster = self:GetCaster()

    -- cancel if linken
    if target:TriggerSpellAbsorb(self) then return end

    -- load data
    local damage = self:GetSpecialValueFor("damage") + (caster:GetStrength()*(self:GetSpecialValueFor("str_to_damage")/100))
    local duration = self:GetSpecialValueFor("stun_duration")

    -- damage
    local damageTable = {
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }

    ApplyDamage(damageTable)

    -- stun
    target:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_generic_stunned_lua", -- modifier name
        { duration = duration } -- kv
    )

    -- Play effects
    self:PlayEffects( target, caster:HasModifier("modifier_dragon_knight_dragon_form_custom") )
    local sound_cast = "Hero_DragonKnight.DragonTail.Target"
    EmitSoundOn( sound_cast, target )
end

function dragon_knight_dragon_tail_custom:PlayEffects( target, dragonform )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_dragon_knight/dragon_knight_dragon_tail.vpcf"

    -- Get Data
    local vec = target:GetOrigin()-self:GetCaster():GetOrigin()
    local attach = "attach_attack1"
    if dragonform then
        attach = "attach_attack2"
    end

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 3, vec )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        2,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        attach,
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        4,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end