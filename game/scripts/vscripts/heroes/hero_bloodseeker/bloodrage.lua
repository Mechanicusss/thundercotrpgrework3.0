LinkLuaModifier("modifier_bloodseeker_bloodrage_custom", "heroes/hero_bloodseeker/bloodrage", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_bloodseeker_bloodrage_custom_buff", "heroes/hero_bloodseeker/bloodrage", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_bloodseeker_bloodrage_custom_autocast", "heroes/hero_bloodseeker/bloodrage", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_bloodseeker_bloodrage_custom_enrage", "heroes/hero_bloodseeker/bloodrage", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT
LinkLuaModifier("modifier_bloodseeker_bloodrage_custom_enrage_cd", "heroes/hero_bloodseeker/bloodrage", LUA_MODIFIER_MOTION_NONE) --- PETH WEFY INPARFANT

local AbilityClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local AbilityClassBuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local AbilityClassDebuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
}

bloodseeker_bloodrage_custom = class(AbilityClass)
modifier_bloodseeker_bloodrage_custom = class(AbilityClass)
modifier_bloodseeker_bloodrage_custom_buff = class(AbilityClassBuff)
modifier_bloodseeker_bloodrage_custom_autocast = class(AbilityClass)
modifier_bloodseeker_bloodrage_custom_enrage = class(AbilityClassBuff)
modifier_bloodseeker_bloodrage_custom_enrage_cd = class(AbilityClassDebuff)

function bloodseeker_bloodrage_custom:GetIntrinsicModifierName()
  return "modifier_bloodseeker_bloodrage_custom"
end

function modifier_bloodseeker_bloodrage_custom:OnRemoved()
    if not IsServer() then return end

    local autocast = self:GetParent():FindModifierByName("modifier_bloodseeker_bloodrage_custom_autocast")
    if autocast ~= nil then
        self:GetParent():RemoveModifierByName("modifier_bloodseeker_bloodrage_custom_autocast")
    end

    local buff = self:GetParent():FindModifierByName("modifier_bloodseeker_bloodrage_custom_buff")
    if buff ~= nil then
        self:GetParent():RemoveModifierByName("modifier_bloodseeker_bloodrage_custom_buff")
    end
end

--
function modifier_bloodseeker_bloodrage_custom_autocast:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_bloodseeker_bloodrage_custom_autocast:OnRemoved()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()
    if not parent:IsAlive() and ability:GetAutoCastState() then
        ability:ToggleAutoCast()
    end

    self:StartIntervalThink(-1)
end

function modifier_bloodseeker_bloodrage_custom_autocast:IsHidden()
    return true
end

function modifier_bloodseeker_bloodrage_custom_autocast:RemoveOnDeath()
    return true
end

function modifier_bloodseeker_bloodrage_custom_autocast:OnIntervalThink()
    if self:GetParent():IsChanneling() then return end
    
    if self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() and self:GetAbility():IsCooldownReady() then
        self:GetAbility():CastAbility()
    end
end
--
function bloodseeker_bloodrage_custom:GetHealthCost()
    return self:GetCaster():GetMaxHealth() * (self:GetSpecialValueFor("damage_pct")/100)
end

function bloodseeker_bloodrage_custom:OnSpellStart()
    if not IsServer() then return end
--
    local target = self:GetCursorTarget()
    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

    if not target or target:IsNull() then
        target = self:GetCaster()
    end

    if not target:IsAlive() then return end 

    local damage = self:GetHealthCost(-1)

    local buff = target:FindModifierByName("modifier_bloodseeker_bloodrage_custom_buff")
    if buff then
        buff:RemoveModifierByName("modifier_bloodseeker_bloodrage_custom_buff")
    end
    
    target:AddNewModifier(caster, ability, "modifier_bloodseeker_bloodrage_custom_buff", { duration = duration, damage = damage })

    CreateParticleWithTargetAndDuration("particles/units/heroes/hero_bloodseeker/bloodseeker_bloodrage.vpcf", target, duration)
    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "hero_bloodseeker.bloodRage", caster)
end
---------------------
function modifier_bloodseeker_bloodrage_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_bloodseeker_bloodrage_custom_buff:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker ~= parent then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_item_aghanims_shard") then
        local shardDamage = caster:GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("attack_hp_damage_pct")/100)
        local damageTable = {
            attacker = parent,
            damage = shardDamage,
            damage_type = DAMAGE_TYPE_PURE,
            damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
        }

        local damageSelf = damageTable
        damageSelf.victim = parent

        -- Self Damage --
        ApplyDamage(damageSelf)

        local damageTarget = damageTable
        damageTarget.victim = target

        -- Victim Damage --
        ApplyDamage(damageTarget)
    end

    local talent = caster:FindAbilityByName("talent_bloodseeker_2")
    if not talent or (talent ~= nil and talent:GetLevel() < 1) then return end 

    local heal = talent:GetSpecialValueFor("heal")
    local healing = target:GetHealth() * (heal/100)

    parent:Heal(healing, self:GetAbility())

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, healing, nil)

    if talent:GetLevel() < 2 then return end 

    if target:GetHealthPercent() <= talent:GetSpecialValueFor("health_percent_trigger") and not parent:HasModifier("modifier_bloodseeker_bloodrage_custom_enrage") and not parent:HasModifier("modifier_bloodseeker_bloodrage_custom_enrage_cd") then
        parent:AddNewModifier(parent, talent, "modifier_bloodseeker_bloodrage_custom_enrage", {
            duration = talent:GetSpecialValueFor("rage_duration")
        })
    end
end

function modifier_bloodseeker_bloodrage_custom_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_bloodseeker_bloodrage_custom_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_bloodseeker_bloodrage_custom_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_bloodseeker_bloodrage_custom_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end 

    self.damage = params.damage

    self:InvokeBonusDamage()
end

function modifier_bloodseeker_bloodrage_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_bloodseeker_bloodrage_custom_buff:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("spell_amp")
end

function modifier_bloodseeker_bloodrage_custom_buff:GetModifierPreAttack_BonusDamage()
    return self.fDamage
end

function modifier_bloodseeker_bloodrage_custom_buff:GetTexture()
    return "bloodseeker_bloodrage"
end
-------------------
function modifier_bloodseeker_bloodrage_custom_enrage_cd:RemoveOnDeath() return false end
-------------------
function modifier_bloodseeker_bloodrage_custom_enrage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT_ADJUST 
    }
end

function modifier_bloodseeker_bloodrage_custom_enrage:GetModifierBaseAttackTimeConstant_Adjust()
    return self:GetAbility():GetSpecialValueFor("rage_bat")
end

function modifier_bloodseeker_bloodrage_custom_enrage:OnRemoved()
    if not IsServer() then return end 

    self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_bloodseeker_bloodrage_custom_enrage_cd", {
        duration = self:GetAbility():GetSpecialValueFor("rage_cooldown")
    })
end