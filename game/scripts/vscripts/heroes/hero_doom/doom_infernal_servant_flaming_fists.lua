LinkLuaModifier("modifier_doom_infernal_servant_flaming_fists", "heroes/hero_doom/doom_infernal_servant_flaming_fists", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

doom_infernal_servant_flaming_fists = class(ItemBaseClass)
modifier_doom_infernal_servant_flaming_fists = class(doom_infernal_servant_flaming_fists)
-------------
function doom_infernal_servant_flaming_fists:GetIntrinsicModifierName()
    return "modifier_doom_infernal_servant_flaming_fists"
end

function modifier_doom_infernal_servant_flaming_fists:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_doom_infernal_servant_flaming_fists:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = parent:GetOwner()
    local ability = self:GetAbility()

    if parent ~= event.attacker then return end

    local radius = ability:GetSpecialValueFor("radius")
    local strength = ability:GetSpecialValueFor("strength_to_damage")

    local units = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,unit in ipairs(units) do
        if not unit:IsMagicImmune() and not unit:IsInvulnerable() then
            local damage = (caster:GetStrength() * (strength/100))
            local attackToPure = parent:GetAverageTrueAttackDamage(parent) * (ability:GetSpecialValueFor("attack_to_pure")/100)

            ApplyDamage({
                victim = unit,
                attacker = caster,
                damage = damage + attackToPure,
                damage_type = DAMAGE_TYPE_PURE,
                ability = ability
            })
        end
    end

    EmitSoundOn("Hero_WarlockGolem.Attack", parent)
end