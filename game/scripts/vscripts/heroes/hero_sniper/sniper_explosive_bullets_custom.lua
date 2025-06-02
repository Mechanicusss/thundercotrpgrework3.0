LinkLuaModifier("modifier_sniper_explosive_bullets_custom", "heroes/hero_sniper/sniper_explosive_bullets_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_explosive_bullets_custom_scepter_buff", "heroes/hero_sniper/sniper_explosive_bullets_custom", LUA_MODIFIER_MOTION_NONE)

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

sniper_explosive_bullets_custom = class(ItemBaseClass)
modifier_sniper_explosive_bullets_custom = class(sniper_explosive_bullets_custom)
modifier_sniper_explosive_bullets_custom_scepter_buff = class(ItemBaseClassBuff)
-------------
function sniper_explosive_bullets_custom:GetIntrinsicModifierName()
    return "modifier_sniper_explosive_bullets_custom"
end

function sniper_explosive_bullets_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_sniper_explosive_bullets_custom_scepter_buff", {
        duration = self:GetSpecialValueFor("scepter_duration")
    })
end

function sniper_explosive_bullets_custom:GetBehavior()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
    else
        return DOTA_ABILITY_BEHAVIOR_PASSIVE 
    end
end

function sniper_explosive_bullets_custom:GetManaCost()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return self:GetSpecialValueFor("scepter_mana_cost")
    end

    return 0
end

function sniper_explosive_bullets_custom:GetCooldown()
    local caster = self:GetCaster()

    if caster:HasScepter() then
        return self:GetSpecialValueFor("scepter_cooldown")
    end

    return 0
end
------------
function modifier_sniper_explosive_bullets_custom:OnCreated()
    if IsServer() then
        self:StartIntervalThink(0.1)
    end
end

function modifier_sniper_explosive_bullets_custom:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if not caster:HasModifier("modifier_gun_joe_machine_gun") and ability:IsActivated() then
        ability:SetActivated(false)
    elseif caster:HasModifier("modifier_gun_joe_machine_gun") and not ability:IsActivated() then
        ability:SetActivated(true)
    end
end

function modifier_sniper_explosive_bullets_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_sniper_explosive_bullets_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end
    if parent:PassivesDisabled() then return end
    if parent:IsIllusion() then return end

    local target = event.target
    local ability = self:GetAbility()

    if not ability:IsActivated() then return end

    local chance = ability:GetSpecialValueFor("chance")
    local radius = ability:GetSpecialValueFor("radius")
    local damage = ability:GetSpecialValueFor("bonus_damage")
    local damageFromAttack = ability:GetSpecialValueFor("damage_from_attack")

    if parent:HasModifier("modifier_sniper_explosive_bullets_custom_scepter_buff") then
        chance = 100
    end
    
    if not RollPercentage(chance) then return end

    local nFXIndex = ParticleManager:CreateParticle( "particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_guided_missile_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)

    ParticleManager:SetParticleControlEnt( nFXIndex, 2, target, PATTACH_POINT_FOLLOW, "attach_head", target:GetOrigin(), true )
    ParticleManager:ReleaseParticleIndex( nFXIndex )

    target:EmitSound( "Hero_Techies.Pick")

    local enemies = FindUnitsInRadius( parent:GetTeamNumber(), target:GetOrigin(), target, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )

    for _,enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) and ( not enemy:IsMagicImmune() ) and ( not enemy:IsInvulnerable() ) then

            local tbl = {
                victim      = enemy,
                attacker    = parent,
                damage      = damage + (event.damage * (damageFromAttack / 100)),
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability     = ability,
            }

            ApplyDamage( tbl )
        end
    end
end