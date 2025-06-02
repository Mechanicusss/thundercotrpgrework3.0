LinkLuaModifier("modifier_necrolyte_death_coil_reaper", "heroes/hero_necrolyte/necrolyte_death_coil_reaper", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

necrolyte_death_coil_reaper = class(ItemBaseClass)
modifier_necrolyte_death_coil_reaper = class(necrolyte_death_coil_reaper)
-------------
function necrolyte_death_coil_reaper:GetIntrinsicModifierName()
    return "modifier_necrolyte_death_coil_reaper"
end

function necrolyte_death_coil_reaper:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function necrolyte_death_coil_reaper:GetBehavior()
    local caster = self:GetCaster()

    if caster:HasModifier("modifier_item_aghanims_shard") then
        return DOTA_ABILITY_BEHAVIOR_AUTOCAST + DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE 
    end

    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE 
end

function necrolyte_death_coil_reaper:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")

    --[[
    local cost = self:GetSpecialValueFor("required_charges")
    local charges = caster:FindModifierByNameAndCaster("modifier_necrolyte_corpse_charges_buff_permanent", caster)
    if charges == nil or charges:GetStackCount() < cost then
        if self:GetAutoCastState() then
            self:ToggleAutoCast()
        end

        DisplayError(caster:GetPlayerID(), "#necrolyte_not_enough_corpse_charges")
        self:EndCooldown()
        return
    end
    

    if charges:GetStackCount() >= cost then
        charges:SetStackCount(charges:GetStackCount()-cost)
    end
    --]]

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsAlive() and not victim:IsMagicImmune() and not victim:IsInvulnerable() then
            local effectName = "particles/econ/items/necrolyte/necrophos_sullen/necro_sullen_pulse_enemy.vpcf"

            if victim:GetTeamNumber() == caster:GetTeamNumber() then
                effectName = "particles/units/heroes/hero_necrolyte/necrolyte_pulse_friend.vpcf"
            end

            local projectile = {
                Target = victim,
                EffectName = effectName,
                iMoveSpeed = 400,
                bDodgeable = false,
                bIgnoreObstructions = true,
                Ability = self,
                Source = caster,
                ExtraData = {
                    enemy = victim:GetTeamNumber() ~= caster:GetTeamNumber(),
                    spread = 1
                }
            }

            ProjectileManager:CreateTrackingProjectile(projectile)
        end
    end

    EmitSoundOn("Hero_Necrolyte.DeathPulse", caster)
end

function necrolyte_death_coil_reaper:OnProjectileHit_ExtraData(target, location, extraData)
    local ability = self
    local caster = self:GetCaster()

    if extraData.enemy == 1 then
        ApplyDamage({
            victim = target,
            attacker = caster,
            damage = ability:GetSpecialValueFor("damage") + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100)),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        })

        if extraData.spread == 1 then
            local radius = ability:GetSpecialValueFor("spread_radius")
            local victims = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil,
                radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_CLOSEST, false)

            for _,victim in ipairs(victims) do
                if victim:IsAlive() and not victim:IsMagicImmune() and not victim:IsInvulnerable() and victim ~= target then
                    local projectile = {
                        Target = victim,
                        EffectName = "particles/econ/items/necrolyte/necrophos_sullen/necro_sullen_pulse_enemy.vpcf",
                        iMoveSpeed = 400,
                        bDodgeable = false,
                        bIgnoreObstructions = true,
                        Ability = self,
                        Source = target,
                        ExtraData = {
                            enemy = 1,
                            spread = 0
                        }
                    }

                    ProjectileManager:CreateTrackingProjectile(projectile)
                    EmitSoundOn("Hero_Necrolyte.DeathPulse", target)
                end
            end
        end
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

function modifier_necrolyte_death_coil_reaper:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_necrolyte_death_coil_reaper:OnIntervalThink()
    local caster = self:GetParent()
    local ability = self:GetAbility()

    if caster:GetMana() < ability:GetManaCost(-1) or caster:IsSilenced() or not ability:GetAutoCastState() or not ability:IsCooldownReady() then return end
    
    --[[
    local cost = ability:GetSpecialValueFor("required_charges")
    local charges = caster:FindModifierByNameAndCaster("modifier_necrolyte_corpse_charges_buff_permanent", caster)
    if charges == nil or charges:GetStackCount() < cost then
        if ability:GetAutoCastState() then
            ability:ToggleAutoCast()
        end
    end
    --]]

    SpellCaster:Cast(ability, nil, true)
end