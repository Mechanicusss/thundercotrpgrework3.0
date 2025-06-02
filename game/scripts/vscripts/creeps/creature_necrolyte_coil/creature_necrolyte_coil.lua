LinkLuaModifier("modifier_creature_necrolyte_coil", "creeps/creature_necrolyte_coil/creature_necrolyte_coil", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

creature_necrolyte_coil = class(ItemBaseClass)
modifier_creature_necrolyte_coil = class(creature_necrolyte_coil)
-------------
function creature_necrolyte_coil:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function creature_necrolyte_coil:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    self.mod = caster:AddNewModifier(caster, self, "modifier_creature_necrolyte_coil", {
        duration = self:GetChannelTime()
    })
end

function creature_necrolyte_coil:OnChannelThink( flInterval )
    if IsServer() then
    end
end

-------------------------------------------------------------------------------

function creature_necrolyte_coil:OnChannelFinish( bInterrupted )
    if IsServer() then
        if self.mod ~= nil then
            self.mod:Destroy()
        end
    end
end

function creature_necrolyte_coil:OnProjectileHit_ExtraData(target, location, extraData)
    local ability = self
    local caster = self:GetCaster()

    if extraData.enemy == 1 then
        ApplyDamage({
            victim = target,
            attacker = caster,
            damage = ability:GetSpecialValueFor("damage"),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        })
    else
        local heal = target:GetMaxHealth() * (ability:GetSpecialValueFor("max_hp_heal_pct")/100)
        target:Heal(heal, ability)
        SendOverheadEventMessage(
            nil,
            OVERHEAD_ALERT_HEAL,
            target,
            heal,
            nil
        )
    end
end

function modifier_creature_necrolyte_coil:CreateCoil()
    local caster = self:GetCaster()

    caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)

    local ability = self:GetAbility()

    local radius = ability:GetSpecialValueFor("radius")

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and not victim:IsMagicImmune() and not victim:IsInvulnerable() then
            -- Don't target allies with the heal, other than necrolyte himself
            if victim:GetTeam() ~= caster:GetTeam() or victim == caster then
                local effectName = "particles/econ/items/necrolyte/necrophos_sullen/necro_sullen_pulse_enemy.vpcf"

                if victim:GetTeamNumber() == caster:GetTeamNumber() then
                    effectName = "particles/units/heroes/hero_necrolyte/necrolyte_pulse_friend.vpcf"
                end

                local projectile = {
                    iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
                    Target = victim,
                    EffectName = effectName,
                    iMoveSpeed = 400,
                    bDodgeable = false,
                    bIgnoreObstructions = true,
                    Ability = ability,
                    Source = caster,
                    ExtraData = {
                        enemy = victim:GetTeamNumber() ~= caster:GetTeamNumber()
                    }
                }

                ProjectileManager:CreateTrackingProjectile(projectile)
            end
        end
    end

    EmitSoundOn("Hero_Necrolyte.DeathPulse", caster)
end

function modifier_creature_necrolyte_coil:OnCreated()
    if not IsServer() then return end
    
    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("interval"))
end

function modifier_creature_necrolyte_coil:OnIntervalThink()
    self:CreateCoil()
end