LinkLuaModifier("modifier_apocalypse_mana_void", "modifiers/apocalypse_modifiers/mana_void", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_mana_void = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_mana_void = class(ItemBaseClass)

function modifier_apocalypse_mana_void:GetIntrinsicModifierName()
    return "modifier_apocalypse_mana_void"
end

function modifier_apocalypse_mana_void:GetTexture() return "manavoid" end
-------------
function modifier_apocalypse_mana_void:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_DEATH,  
    }

    return funcs
end

function modifier_apocalypse_mana_void:OnDeath(event)
    if event.unit ~= self:GetParent() then return end

    local attacker = event.attacker
    local unit = event.unit

    local delay = 1.719524 -- Seconds before explosion occurs
    local radius = 300
    local damage = 0.40

    local ability = self:GetAbility()

    if not RollPercentage(40) then return end

    EmitSoundOn("Hero_Antimage.ManaVoidCast", unit)

    DrawWarningCircle(unit, unit:GetAbsOrigin(), radius, delay)
    AddFOWViewer(DOTA_TEAM_GOODGUYS, unit:GetAbsOrigin(), radius, delay*2, false)

    for i = 1, 2, 1 do
        Timers:CreateTimer(delay*i, function()
            Explode(unit:GetTeam(), unit:GetAbsOrigin(), unit:GetMaxMana())
        end)
    end

    function Explode(team, loc, mana)
        local effect_cast = ParticleManager:CreateParticle( "particles/econ/items/antimage/antimage_weapon_basher_ti5/antimage_manavoid_ti_5.vpcf", PATTACH_WORLDORIGIN, unit )
        ParticleManager:SetParticleControl( effect_cast, 0, unit:GetAbsOrigin() )
        ParticleManager:SetParticleControl( effect_cast, 1, Vector(radius, radius, radius) )
        ParticleManager:ReleaseParticleIndex( effect_cast )
        EmitSoundOn("Hero_Antimage.ManaVoid", unit)

        local victims = FindUnitsInRadius(team, loc, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,victim in ipairs(victims) do
            if 
                victim:IsAlive() and 
                not victim:IsMagicImmune()
            then
                local dmg = mana * damage

                ApplyDamage({
                    victim = victim,
                    attacker = unit,
                    damage = dmg,
                    damage_type = DAMAGE_TYPE_MAGICAL,
                    damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
                    ability = ability,
                })

                victim:SpendMana(dmg, ability)
                SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_LOSS, victim, dmg, nil)
            end
        end
    end
end