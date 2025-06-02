invoker_chaos_meteor_lua = class({})
LinkLuaModifier( "modifier_invoker_chaos_meteor_lua_thinker", "items/item_meteorite_sword/item_meteorite_sword_chaos_meteor_modifier_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_invoker_chaos_meteor_lua_burn", "items/item_meteorite_sword/item_meteorite_sword_chaos_meteor_modifier_burn", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function invoker_chaos_meteor_lua:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- create thinker
    CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_invoker_chaos_meteor_lua_thinker", -- modifier name
        {}, -- kv
        Vector(point.x, point.y-200, point.z),
        self:GetCaster():GetTeamNumber(),
        false
    )

    CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_invoker_chaos_meteor_lua_thinker", -- modifier name
        {}, -- kv
        point,
        self:GetCaster():GetTeamNumber(),
        false
    )

    CreateModifierThinker(
        caster, -- player source
        self, -- ability source
        "modifier_invoker_chaos_meteor_lua_thinker", -- modifier name
        {}, -- kv
        Vector(point.x, point.y+200, point.z),
        self:GetCaster():GetTeamNumber(),
        false
    )
end
--------------------------------------------------------------------------------
-- Projectile
function invoker_chaos_meteor_lua:OnStolen( hAbility )
    self.orbs = hAbility.orbs
end

function invoker_chaos_meteor_lua:GetOrbSpecialValueFor( key_name, orb_name )
    if not IsServer() then return 0 end
    if not self.orbs[orb_name] then return 0 end
    return self:GetLevelSpecialValueFor( key_name, self.orbs[orb_name] )
    --return self:GetSpecialValueFor(key_name)
end