LinkLuaModifier("modifier_apocalypse_corpse_explosion", "modifiers/apocalypse_modifiers/corpse_explosion", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_corpse_explosion = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_corpse_explosion = class(ItemBaseClass)

function modifier_apocalypse_corpse_explosion:GetIntrinsicModifierName()
    return "modifier_apocalypse_corpse_explosion"
end

function modifier_apocalypse_corpse_explosion:GetTexture() return "skull" end
-------------
function modifier_apocalypse_corpse_explosion:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,  
    }

    return funcs
end

function modifier_apocalypse_corpse_explosion:OnDeath(event)
    if event.unit ~= self:GetParent() then return end

    local attacker = event.attacker
    local unit = event.unit

    local delay = 2 -- Seconds before explosion occurs
    local radius = 300
    local damage = 0.30

    local ability = self:GetAbility()

    AddFOWViewer(DOTA_TEAM_GOODGUYS, unit:GetAbsOrigin(), radius, delay, false)
    DrawWarningCircle(unit, unit:GetAbsOrigin(), radius, delay)

    Timers:CreateTimer(2, function()
        Explode(unit:GetTeam(), unit:GetAbsOrigin(), unit:GetMaxHealth())
    end)

    function Explode(team, loc, hp)
        local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_WORLDORIGIN, unit )
        ParticleManager:SetParticleControl( effect_cast, 0, unit:GetAbsOrigin() )
        ParticleManager:ReleaseParticleIndex( effect_cast )
        EmitSoundOn("Hero_Techies.StickyBomb.Detonate", unit)

        local victims = FindUnitsInRadius(team, loc, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            if 
                victim:IsAlive() and 
                not victim:IsMagicImmune()
            then
                local dmg = hp * damage

                ApplyDamage({
                    victim = victim,
                    attacker = unit,
                    damage = dmg,
                    damage_type = DAMAGE_TYPE_MAGICAL,
                    damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
                    ability = ability,
                })
            end
        end
    end
end