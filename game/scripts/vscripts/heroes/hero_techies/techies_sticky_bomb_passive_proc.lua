LinkLuaModifier("modifier_techies_sticky_bomb_passive_proc", "heroes/hero_techies/techies_sticky_bomb_passive_proc", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

techies_sticky_bomb_passive_proc = class(ItemBaseClass)
modifier_techies_sticky_bomb_passive_proc = class(techies_sticky_bomb_passive_proc)
-------------
function techies_sticky_bomb_passive_proc:GetIntrinsicModifierName()
    return "modifier_generic_orb_effect_lua"
end

function techies_sticky_bomb_passive_proc:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local stickyBomb = caster:FindAbilityByName("techies_sticky_bomb")
    if stickyBomb == nil then return end

    SpellCaster:Cast(stickyBomb, point, true)
end

function techies_sticky_bomb_passive_proc:GetCastRange()
    return self:GetCaster():Script_GetAttackRange()
end

function techies_sticky_bomb_passive_proc:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function techies_sticky_bomb_passive_proc:GetProjectileName()
    return "particles/units/heroes/hero_techies/techies_base_attack.vpcf"
end

function techies_sticky_bomb_passive_proc:OnOrbFire(params)
    local caster = self:GetCaster()
    local target = params.target
    local ability = self

    if caster:PassivesDisabled() then return end
    if caster:IsIllusion() then return end
    if not target:IsBaseNPC() then return end

    local stickyBombProc = caster:FindAbilityByName("techies_sticky_bomb_passive_proc")
    local stickyBomb = caster:FindAbilityByName("techies_sticky_bomb")

    if stickyBomb ~= nil and stickyBombProc ~= nil and stickyBomb:GetLevel() > 0 and stickyBombProc:GetLevel() > 0 then
        if self.attackTimer ~= nil then
            Timers:RemoveTimer(self.attackTimer)
            self.attackTimer = nil
        end

        self.attackTimer = Timers:CreateTimer(0.1, function()
            if target == nil or not target:IsAlive() then return end
            
            SpellCaster:Cast(stickyBomb, target, true)
            stickyBombProc:UseResources(false, false, false, true)
        end)
    end
end

function techies_sticky_bomb_passive_proc:OnOrbImpact(params)
    if not IsServer() then return end

    --[[ApplyDamage({
        victim = params.target,
        attacker = params.attacker,
        damage = params.attacker:GetAverageTrueAttackDamage(params.attacker),
        damage_type = DAMAGE_TYPE_PHYSICAL
    })--]]
end