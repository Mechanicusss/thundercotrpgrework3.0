aghanim_illusory_orb = class({})

LinkLuaModifier( "modifier_aghanim_illusory_orb_thinker", "modifiers/creatures/modifier_aghanim_illusory_orb_thinker", LUA_MODIFIER_MOTION_NONE )

aghanim_illusory_orb.projectiles = {}
----------------------------------------------------------------------------------------

function aghanim_illusory_orb:Precache( context )
    PrecacheResource( "particle", "particles/units/heroes/hero_puck/puck_illusory_orb.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_puck/puck_orb_damage.vpcf", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_puck.vsndevts", context ) 
end

--------------------------------------------------------------------------------

function aghanim_illusory_orb:OnSpellStart()
    if IsServer() then
       local caster = self:GetCaster()

       self.mod = CreateModifierThinker( caster, self, "modifier_aghanim_illusory_orb_thinker", { duration = self:GetChannelTime() }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false )
    end
end

--------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function aghanim_illusory_orb:OnChannelThink( flInterval )
    if IsServer() then
    end
end

-------------------------------------------------------------------------------

function aghanim_illusory_orb:OnChannelFinish( bInterrupted )
    if IsServer() then
        
    end
end

--------------------------------------------------------------------------------
function aghanim_illusory_orb:OnProjectileThinkHandle( proj )
    -- update location
    local location = ProjectileManager:GetLinearProjectileLocation( proj )
    self.projectiles[proj].location = location
end
--------------------------------------------------------------------------------

function aghanim_illusory_orb:OnProjectileHitHandle( target, location, proj )
    if not target then 
        -- destroy reference
        self.projectiles[proj] = nil
        return true
    end

    -- damage
    local damageTable = {
        victim = target,
        attacker = self:GetCaster(),
        damage = self.projectiles[proj].damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self, --Optional.
    }
    ApplyDamage(damageTable)

    -- effects
    self:PlayEffects( target )
    return false
end
--------------------------------------------------------------------------------
function aghanim_illusory_orb:PlayEffects( target )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_puck/puck_orb_damage.vpcf"
    local sound_cast = "Hero_Puck.IIllusory_Orb_Damage"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end