LinkLuaModifier("modifier_burning_blades", "items/burning_blades/item_burning_blades", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_burning_blades_aura_enemy", "items/burning_blades/item_burning_blades", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_burning_blades_explosion_debuff", "items/burning_blades/item_burning_blades", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_burning_blades_active", "items/burning_blades/item_burning_blades", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_burning_blades = class(ItemBaseClass)
modifier_burning_blades_active = class(ItemBaseClass)
item_burning_blades2 = item_burning_blades
item_burning_blades3 = item_burning_blades
item_burning_blades4 = item_burning_blades
item_burning_blades5 = item_burning_blades
item_burning_blades6 = item_burning_blades
modifier_burning_blades = class(item_burning_blades)
modifier_burning_blades_aura_enemy = class(ItemBaseClassAura)
modifier_burning_blades_explosion_debuff = class(ItemDebuff)
-------------
function item_burning_blades:GetIntrinsicModifierName()
    return "modifier_burning_blades"
end

function item_burning_blades:GetAbilityTextureName()
    if self:GetToggleState() then
        return "burning_blades_toggle"
    end

    if self:GetLevel() == 1 then
        return "burning_blades"
    elseif self:GetLevel() == 2 then
        return "burning_blades3"
    elseif self:GetLevel() == 3 then
        return "burning_blades2"
    elseif self:GetLevel() == 4 then
        return "burning_blades4"
    elseif self:GetLevel() == 5 then
        return "burning_blades5"
    elseif self:GetLevel() == 6 then
        return "burning_blades6"
    end
end

function item_burning_blades:OnToggle()
    local caster = self:GetCaster()

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_burning_blades_active", {})
    else
        caster:RemoveModifierByName("modifier_burning_blades_active")
    end
end

function item_burning_blades:GetAOERadius()
    return 700
end
------------
function modifier_burning_blades_explosion_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS , --GetModifierMagicalResistanceBonus
    }
    return funcs
end

function modifier_burning_blades_explosion_debuff:AddCustomTransmitterData()
    return
    {
        shred = self.fShred,
    }
end

function modifier_burning_blades_explosion_debuff:HandleCustomTransmitterData(data)
    if data.shred ~= nil then
        self.fShred = tonumber(data.shred)
    end
end

function modifier_burning_blades_explosion_debuff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    self.shred = params.shred

    self:InvokeBonusDamage()
end

function modifier_burning_blades_explosion_debuff:InvokeBonusDamage()
    if IsServer() == true then
        self.fShred = self.shred

        self:SendBuffRefreshToClients()
    end
end

function modifier_burning_blades_explosion_debuff:GetModifierMagicalResistanceBonus()
    return self.fShred
end
------------
function modifier_burning_blades:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_EVASION_CONSTANT, --GetModifierEvasion_Constant
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_burning_blades:OnRemoved()
    if not IsServer() then return end

    if self:GetAbility():GetToggleState() then
        self:GetAbility():ToggleAbility()
    end
end

function modifier_burning_blades:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end

    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local victim = event.target

    if not RollPercentage(ability:GetSpecialValueFor("explosion_chance")) or event.target:IsMagicImmune() then return end

    local victims = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
        ability:GetSpecialValueFor("explosion_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,zvictim in ipairs(victims) do
        if not zvictim:IsAlive() or zvictim:IsMagicImmune() then break end

        ApplyDamage({
            victim = event.target,
            attacker = self:GetCaster(),
            damage = self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster()) * (ability:GetSpecialValueFor("explosion_damage")/100),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability,
        })

        zvictim:AddNewModifier(caster, ability, "modifier_burning_blades_explosion_debuff", { 
            duration = ability:GetSpecialValueFor("explosion_debuff_duration"),
            shred = ability:GetSpecialValueFor("magic_reduce")
        })
    end

    self:PlayEffects(victim)
end

function modifier_burning_blades:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/arena/items_fx/vermillion_robe_explosion.vpcf"
    local sound_cast = "ParticleDriven.Rocket.Explode"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 1, target:GetOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

function modifier_burning_blades:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_burning_blades:GetModifierStatusResistance()
    return self:GetAbility():GetLevelSpecialValueFor("status_resistance", (self:GetAbility():GetLevel() - 1))
end

function modifier_burning_blades:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("hp_regen_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_burning_blades:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("hp_regen_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_burning_blades:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_burning_blades:GetModifierEvasion_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("evasion", (self:GetAbility():GetLevel() - 1))
end

function modifier_burning_blades:GetModifierSpellAmplify_Percentage()
    return self.fAmp
end

function modifier_burning_blades:OnCreated()
    self:SetHasCustomTransmitterData(true)

    local ability = self:GetAbility()

    self.caster = self:GetCaster()

    if IsServer() then
        self:StartIntervalThink(FrameTime())
    end
end

function modifier_burning_blades:AddCustomTransmitterData()
    return
    {
        amp = self.fAmp,
    }
end

function modifier_burning_blades:HandleCustomTransmitterData(data)
    if data.amp ~= nil then
        self.fAmp = tonumber(data.amp)
    end
end

function modifier_burning_blades:InvokeSpellAmp()
    if IsServer() == true then
        self.fAmp = self.amp

        self:SendBuffRefreshToClients()
    end
end

function modifier_burning_blades:OnIntervalThink()
    local caster = self:GetCaster()

    self.amp = self:GetAbility():GetSpecialValueFor("spell_amp")

    self:InvokeSpellAmp()
end
--
function modifier_burning_blades_active:GetEffectName()
    return "particles/econ/events/ti10/radiance_owner_ti10.vpcf"
end

function modifier_burning_blades_active:IsAura()
  return true
end

function modifier_burning_blades_active:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_burning_blades_active:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_burning_blades_active:GetAuraRadius()
  return 700
end

function modifier_burning_blades_active:GetModifierAura()
    return "modifier_burning_blades_aura_enemy"
end

function modifier_burning_blades_active:GetAuraEntityReject(target)
    return false
end
----------
function modifier_burning_blades_aura_enemy:OnCreated()
    local ability = self:GetAbility()

    if not IsServer() then return end

    self.damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability,
    }

    local interval = self:GetAbility():GetSpecialValueFor("burn_interval")

    self:StartIntervalThink(interval)
end

function modifier_burning_blades_aura_enemy:GetEffectName()
    return "particles/econ/events/ti10/radiance_ti10.vpcf"
end

function modifier_burning_blades_aura_enemy:OnIntervalThink()
    self.damageTable.damage = self:GetAbility():GetSpecialValueFor("flat_burn"),
    
    ApplyDamage(self.damageTable)
end

function modifier_burning_blades_aura_enemy:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MISS_PERCENTAGE, --GetModifierMiss_Percentage
    }

    return funcs
end

function modifier_burning_blades_aura_enemy:GetModifierMiss_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("burn_miss", (self:GetAbility():GetLevel() - 1))
end

function modifier_burning_blades_aura_enemy:IsDebuff()
    return true
end
----------
