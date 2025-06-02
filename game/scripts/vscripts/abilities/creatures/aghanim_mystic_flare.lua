aghanim_mystic_flare = class({})

LinkLuaModifier( "modifier_aghanim_mystic_flare_thinker", "modifiers/creatures/modifier_aghanim_mystic_flare_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_aghanim_mystic_flare_dummy", "modifiers/creatures/modifier_aghanim_mystic_flare_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_aghanim_mystic_flare_dummy_aura", "modifiers/creatures/modifier_aghanim_mystic_flare_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_aghanim_mystic_flare_debuff", "modifiers/creatures/modifier_aghanim_mystic_flare_debuff", LUA_MODIFIER_MOTION_NONE )

----------------------------------------------------------------------------------------

function aghanim_mystic_flare:Precache( context )
    PrecacheResource( "particle", "particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare_ambient.vpcf", context )
    PrecacheResource( "particle", "particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare.vpcf", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_skywrath_mage.vsndevts", context ) 
end

--------------------------------------------------------------------------------

function aghanim_mystic_flare:OnSpellStart()
    if IsServer() then
       local caster = self:GetCaster()

       self.mod = CreateModifierThinker( caster, self, "modifier_aghanim_mystic_flare_thinker", { duration = self:GetChannelTime() }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false )
    end
end

--------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function aghanim_mystic_flare:OnChannelThink( flInterval )
    if IsServer() then
    end
end

-------------------------------------------------------------------------------

function aghanim_mystic_flare:OnChannelFinish( bInterrupted )
    if IsServer() then
        
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------