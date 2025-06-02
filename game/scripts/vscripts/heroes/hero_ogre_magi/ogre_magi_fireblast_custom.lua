ogre_magi_fireblast_custom = class({})
LinkLuaModifier( "modifier_generic_stunned_lua", "modifiers/modifier_generic_stunned_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ogre_magi_fireblast_custom", "heroes/hero_ogre_magi/ogre_magi_fireblast_custom", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

ogre_magi_fireblast_custom = class(ItemBaseClass)
modifier_ogre_magi_fireblast_custom = class(ogre_magi_fireblast_custom)

function ogre_magi_fireblast_custom:GetIntrinsicModifierName()
    return "modifier_ogre_magi_fireblast_custom"
end

function modifier_ogre_magi_fireblast_custom:DeclareFunctions()
    return {
        --MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_ogre_magi_fireblast_custom:OnAttack(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:IsSilenced() or caster:IsIllusion() then
        return
    end

    local ability = self:GetAbility()
    if not ability:GetAutoCastState() or not ability:IsCooldownReady() then return end

    unit:CastAbilityOnTarget(victim, ability, -1)
end
--------------------------------------------------------------------------------
-- Ability Start
function ogre_magi_fireblast_custom:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    -- cancel if linken
    if target:TriggerSpellAbsorb( self ) then
        return
    end

    -- load data
    local duration = self:GetSpecialValueFor( "stun_duration" )
    local damage = self:GetSpecialValueFor( "fireblast_damage" ) + (self:GetCaster():GetBaseIntellect()*(self:GetSpecialValueFor("int_to_damage")/100))

    -- Apply damage
    local damageTable = {
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }
    ApplyDamage( damageTable )

    -- stun
    target:AddNewModifier(
        self:GetCaster(),
        self, 
        "modifier_generic_stunned_lua", 
        {duration = duration}
    )

    -- play effects
    self:PlayEffects( target )

end

--------------------------------------------------------------------------------
function ogre_magi_fireblast_custom:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast.vpcf"
    local sound_cast = "Hero_OgreMagi.Fireblast.Cast"
    local sound_target = "Hero_OgreMagi.Fireblast.Target"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 1, target:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetCaster() )
    EmitSoundOn( sound_target, target )
end