aghanim_dispersion = class({})

LinkLuaModifier( "modifier_aghanim_dispersion", "modifiers/creatures/modifier_aghanim_dispersion", LUA_MODIFIER_MOTION_NONE )

function aghanim_dispersion:GetIntrinsicModifierName()
    return "modifier_aghanim_dispersion"
end

function aghanim_dispersion:Precache( context )
    PrecacheResource( "particle", "particles/econ/items/spectre/spectre_arcana/spectre_arcana_dispersion.vpcf", context )
end

----------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------