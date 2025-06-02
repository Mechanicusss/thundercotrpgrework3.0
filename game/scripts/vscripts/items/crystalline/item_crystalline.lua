LinkLuaModifier("modifier_item_crystalline", "items/crystalline/item_crystalline", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_crystalline_debuff", "items/crystalline/item_crystalline", LUA_MODIFIER_MOTION_NONE)

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

item_crystalline = class(ItemBaseClass)
item_crystalline_2 = item_crystalline
item_crystalline_3 = item_crystalline
item_crystalline_4 = item_crystalline
item_crystalline_5 = item_crystalline
modifier_item_crystalline = class(item_crystalline)
modifier_item_crystalline_debuff = class(ItemBaseClassDebuff)
-------------
function item_crystalline:GetIntrinsicModifierName()
    return "modifier_item_crystalline"
end

function modifier_item_crystalline:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_MANA_BONUS, --GetModifierManaBonus 
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_PROJECTILE_NAME 
    }
    return funcs
end

function modifier_item_crystalline:OnTakeDamage(event)
    local victim = event.unit
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if event.attacker ~= caster then return end
    if victim == caster then return end
    if ability == event.inflictor then return end
    if event.attacker:IsIllusion() or not event.attacker:IsRealHero() then return end
    
    local debuff = victim:FindModifierByNameAndCaster("modifier_item_crystalline_debuff", caster)
    if debuff == nil then
        debuff = victim:AddNewModifier(caster, ability, "modifier_item_crystalline_debuff", { duration = ability:GetSpecialValueFor("duration") })
    end

    if not debuff or debuff == nil then return end

    debuff:ForceRefresh()
end

function modifier_item_crystalline:GetModifierProjectileName()
    return "particles/items2_fx/skadi_projectile.vpcf"
end

function modifier_item_crystalline:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_crystalline:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_crystalline:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_crystalline:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_crystalline:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_crystalline:GetModifierManaBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end
----
function modifier_item_crystalline_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE, --GetModifierAttackSpeedPercentage
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }

    return funcs
end

function modifier_item_crystalline_debuff:OnTakeDamage(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetCaster() then return end
    if event.attacker:IsIllusion() or not event.attacker:IsRealHero() then return end

    local victim = event.unit
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if victim == caster then return end

    if ability == event.inflictor then return end

    ---- Shatter check -----
    if not ability:IsCooldownReady() then return end
    if victim:GetHealthPercent() > ability:GetSpecialValueFor("kill_hp_threshold") then return end

    local victimMaxHealth = victim:GetMaxHealth()

    if IsCreepTCOTRPG(victim) or IsBossTCOTRPG(victim) then
        --victim:Kill(ability, victim)
        ApplyDamage({
            victim = victim, 
            attacker = caster, 
            damage = victimMaxHealth, 
            damage_type = DAMAGE_TYPE_PURE,
            damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
        })
        return
    end

    local frostExplosionParticle = ParticleManager:CreateParticle("particles/econ/items/lich/frozen_chains_ti6/lich_frozenchains_frostnova.vpcf", PATTACH_CUSTOMORIGIN, victim)
    ParticleManager:SetParticleControlEnt(frostExplosionParticle, 0, victim, PATTACH_POINT_FOLLOW, "attach_hitloc", victim:GetOrigin(), true)
    ParticleManager:ReleaseParticleIndex(frostExplosionParticle)

    local particle = ParticleManager:CreateParticle("particles/econ/items/ancient_apparition/aa_blast_ti_5/ancient_apparition_ice_blast_explode_ti5.vpcf", PATTACH_CUSTOMORIGIN, victim)
    ParticleManager:SetParticleControlEnt(particle, 0, victim, PATTACH_POINT_FOLLOW, "attach_hitloc", victim:GetOrigin(), true)
    ParticleManager:SetParticleControl(particle, 1, Vector(ability:GetSpecialValueFor("radius"), ability:GetSpecialValueFor("radius"), ability:GetSpecialValueFor("radius")))
    ParticleManager:ReleaseParticleIndex(particle)

    local victims = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
        ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() or enemy == victim then break end

        ApplyDamage({
            victim = enemy, 
            attacker = caster, 
            damage = victimMaxHealth * (ability:GetSpecialValueFor("max_hp_damage")/100), 
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        })
    end

    EmitSoundOnLocationWithCaster(victim:GetOrigin(), "Ability.FrostNova", victim)
    ability:UseResources(false, false, false, true)
end

function modifier_item_crystalline_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("attack_slow_pct")
end

function modifier_item_crystalline_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("speed_slow_pct")
end

function modifier_item_crystalline_debuff:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("healing_degen")
end

function modifier_item_crystalline_debuff:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("healing_degen")
end

function modifier_item_crystalline_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("healing_degen")
end

function modifier_item_crystalline_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("healing_degen")
end

function modifier_item_crystalline_debuff:GetTexture()
    return "crystalline"
end

function modifier_item_crystalline_debuff:GetStatusEffectName()
     return "particles/status_fx/status_effect_frost.vpcf"
end