LinkLuaModifier("modifier_tormentor_reflect_custom", "creeps/tormentor_reflect_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

tormentor_reflect_custom = class(ItemBaseClass)
modifier_tormentor_reflect_custom = class(tormentor_reflect_custom)
-------------
function tormentor_reflect_custom:GetIntrinsicModifierName()
    return "modifier_tormentor_reflect_custom"
end
------------
function modifier_tormentor_reflect_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE  
    }
end

function modifier_tormentor_reflect_custom:GetModifierIncomingDamage_Percentage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local reflectPct = ability:GetSpecialValueFor("passive_reflection_pct")

    local damage = event.original_damage * (reflectPct/100)

    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),    -- int, your team number
        parent:GetOrigin(),    -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        1200,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    if #enemies > 0 then
        damage = damage / #enemies
    end

    for _,enemy in ipairs(enemies) do
        ApplyDamage({
            attacker = parent,
            victim = enemy,
            damage = damage,
            damage_type = event.damage_type,
            damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL),
            ability = ability
        })

        EmitSoundOn("Miniboss.Tormenter.Reflect", enemy)

        local pfx = ParticleManager:CreateParticle("particles/neutral_fx/miniboss_damage_reflect.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(pfx, 0, parent:GetAbsOrigin())
        ParticleManager:SetParticleControlEnt(pfx, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(pfx)
    end

    local effect_cast = ParticleManager:CreateParticle( "particles/neutral_fx/miniboss_damage_reflect.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.attacker)
    ParticleManager:SetParticleControl(effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControlEnt(effect_cast, 1, event.attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", event.attacker:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(effect_cast)

    EmitSoundOn("Miniboss.Tormenter.Reflect", parent)
end