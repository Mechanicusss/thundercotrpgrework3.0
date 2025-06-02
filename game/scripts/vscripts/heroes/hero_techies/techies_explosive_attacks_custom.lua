LinkLuaModifier("modifier_techies_explosive_attacks_custom", "heroes/hero_techies/techies_explosive_attacks_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

techies_explosive_attacks_custom = class(ItemBaseClass)
modifier_techies_explosive_attacks_custom = class(techies_explosive_attacks_custom)
-------------
function techies_explosive_attacks_custom:GetIntrinsicModifierName()
    return "modifier_techies_explosive_attacks_custom"
end
---------------------
function modifier_techies_explosive_attacks_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_techies_explosive_attacks_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
end

function modifier_techies_explosive_attacks_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if ability:GetLevel() < 1  then return end

    if parent ~= event.attacker then return end

    local target = event.target

    if target ~= event.target then return end
    if target:IsMagicImmune() then return end
    if not ability:IsCooldownReady() then return end

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_techies/techies_remote_mines_detonate.vpcf", PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_Techies.RemoteMine.Detonate", target)

    local radius = ability:GetSpecialValueFor("radius")

    local victims = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim:IsMagicImmune() then break end

        local damage = (parent:GetAverageTrueAttackDamage(parent) * (ability:GetSpecialValueFor("attack_to_damage")/100))

        ApplyDamage({
            attacker = parent,
            victim = victim,
            damage = damage,
            ability = ability,
            damage_type = DAMAGE_TYPE_MAGICAL,
        })
    end
    
    if not parent:HasModifier("modifier_techies_go_nuclear_buff") then
        ability:UseResources(false, false, false, true)
    end
end