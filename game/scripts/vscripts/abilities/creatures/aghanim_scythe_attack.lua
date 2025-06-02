aghanim_scythe_attack = class({})

LinkLuaModifier( "modifier_aghanim_scythe_attack_thinker", "modifiers/creatures/modifier_aghanim_scythe_attack_thinker", LUA_MODIFIER_MOTION_NONE )

----------------------------------------------------------------------------------------

function aghanim_scythe_attack:Precache( context )
    PrecacheResource( "particle", "particles/econ/items/necrolyte/necro_sullen_harvest/necro_ti7_immortal_scythe_start.vpcf", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_necrolyte.vsndevts", context ) 
end

--------------------------------------------------------------------------------

function aghanim_scythe_attack:OnSpellStart()
    if IsServer() then
       local caster = self:GetCaster()

       self.mod = CreateModifierThinker( caster, self, "modifier_aghanim_scythe_attack_thinker", { duration = self:GetChannelTime() }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false )
    end
end

--------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function aghanim_scythe_attack:OnChannelThink( flInterval )
    if IsServer() then
    end
end

-------------------------------------------------------------------------------

function aghanim_scythe_attack:OnChannelFinish( bInterrupted )
    if IsServer() then
        
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------