aghanim_life_drain = class({})

LinkLuaModifier( "modifier_aghanim_life_drain_thinker", "modifiers/creatures/modifier_aghanim_life_drain_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_aghanim_life_drain_debuff_thinker", "modifiers/creatures/modifier_aghanim_life_drain_debuff_thinker", LUA_MODIFIER_MOTION_NONE )

----------------------------------------------------------------------------------------

function aghanim_life_drain:Precache( context )
    PrecacheResource( "particle", "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", context )
    PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_pugna.vsndevts", context ) 
end
--------------------------------------------------------------------------------

function aghanim_life_drain:OnAbilityPhaseStart()
    if IsServer() then
        self:GetCaster():AddNewModifier(
            self:GetCaster(),
            self,
            "modifier_black_king_bar_immune",
            {duration = self:GetChannelTime() + 1.25}
        )
    end
    return true
end
--------------------------------------------------------------------------------

function aghanim_life_drain:OnSpellStart()
    if IsServer() then
       local caster = self:GetCaster()

       self.mod = CreateModifierThinker( caster, self, "modifier_aghanim_life_drain_thinker", { duration = self:GetChannelTime() }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false )
    end
end

--------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function aghanim_life_drain:OnChannelThink( flInterval )
    if IsServer() then
    end
end

-------------------------------------------------------------------------------

function aghanim_life_drain:OnChannelFinish( bInterrupted )
    if IsServer() then
        
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------