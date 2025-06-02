LinkLuaModifier("modifier_templar_assassin_psionic_explosion_custom", "heroes/hero_templar_assassin/templar_assassin_psionic_explosion_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_assassin_psionic_explosion_custom_debuff", "heroes/hero_templar_assassin/templar_assassin_psionic_explosion_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

templar_assassin_psionic_explosion_custom = class(ItemBaseClass)
modifier_templar_assassin_psionic_explosion_custom = class(templar_assassin_psionic_explosion_custom)
modifier_templar_assassin_psionic_explosion_custom_debuff = class(ItemBaseClassDebuff)
-------------
function templar_assassin_psionic_explosion_custom:GetIntrinsicModifierName()
    return "modifier_templar_assassin_psionic_explosion_custom"
end

function modifier_templar_assassin_psionic_explosion_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_templar_assassin_psionic_explosion_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local victim = event.target
    local ability = self:GetAbility()

    if victim:GetClassname() ~= "npc_dota_creature" then return end
    if not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim) then return end
    if not RollPercentage(ability:GetSpecialValueFor("chance")) then return end

    local projSpeed = parent:GetProjectileSpeed()
    if parent:HasScepter() then
        projSpeed = projSpeed + 1200
    end

    local projTable = {
        EffectName = "particles/units/heroes/hero_templar_assassin/templar_assassin_meld_attack.vpcf",
        vSourceLoc = parent:GetAbsOrigin(),
        Target = victim,
        iMoveSpeed = projSpeed,
        bDodgeable = false,
        bVisibleToEnemies = true,
        Ability = ability,
        Source = parent,
        bProvidesVision = true,
        iVisionRadius = 300,
        iVisionTeamNumber = parent:GetTeamNumber(),
        ExtraData = {
            startLocX = parent:GetAbsOrigin().x,
            startLocY = parent:GetAbsOrigin().y,
            startLocZ = parent:GetAbsOrigin().z
        }
    }

    ProjectileManager:CreateTrackingProjectile(projTable)

    --[[
    if parent:HasScepter() then
        local extraEnemies = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil,
            parent:Script_GetAttackRange()+50, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        local count = 0

        for _,extraEnemy in ipairs(extraEnemies) do
            if extraEnemy:IsAlive() and extraEnemy ~= victim and count < 2 then
                projTable.Target = extraEnemy
                ProjectileManager:CreateTrackingProjectile(projTable)

                count = count + 1
            end
        end
    end

    ability:UseResources(false, false, true)
    --]]
end

function templar_assassin_psionic_explosion_custom:OnProjectileHit_ExtraData(hTarget, hLoc, extraData)
    if not IsServer() then return end

    local caster = self:GetCaster()

    local damage = self:GetSpecialValueFor("damage") + (self:GetCaster():GetAgility() * (self:GetSpecialValueFor("agi_to_damage")/100))
    local distanceMultiplier = ((Vector(extraData["startLocX"], extraData["startLocY"], extraData["startLocZ"]) - hTarget:GetAbsOrigin()):Length2D() / (self:GetSpecialValueFor("distance_multiplier"))) * 0.1

    if distanceMultiplier < 1 then
        distanceMultiplier = 1
    end

    local totalDamage = damage * distanceMultiplier

    ApplyDamage({
        victim = hTarget, 
        attacker = caster, 
        damage = totalDamage, 
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = self
    })

    self:PlayEffects(hTarget)

    local victims = FindUnitsInRadius(caster:GetTeam(), hTarget:GetAbsOrigin(), nil,
        self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() or victim == hTarget then break end

        ApplyDamage({
            victim = victim, 
            attacker = caster, 
            damage = totalDamage, 
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = self
        })
    end

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_DAMAGE,
        hTarget,
        totalDamage,
        nil
    )
end

function templar_assassin_psionic_explosion_custom:PlayEffects(target)
    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    -- Get Resources
    local particle_cast = "particles/econ/items/lanaya/lanaya_epit_trap/templar_assassin_epit_trap_explode.vpcf"
    local sound_cast = "Hero_TemplarAssassin.Trap.Explode"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex(self.effect_cast)

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end