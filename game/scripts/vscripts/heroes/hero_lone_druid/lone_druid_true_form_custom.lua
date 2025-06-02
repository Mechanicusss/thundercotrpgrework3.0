LinkLuaModifier("modifier_lone_druid_true_form_custom", "heroes/hero_lone_druid/lone_druid_true_form_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lone_druid_true_form_custom_transforming", "heroes/hero_lone_druid/lone_druid_true_form_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lone_druid_true_form_custom_talent_thinker", "heroes/hero_lone_druid/lone_druid_true_form_custom", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

lone_druid_true_form_custom = class(ItemBaseClass)
modifier_lone_druid_true_form_custom = class(ItemBaseClassBuff)
modifier_lone_druid_true_form_custom_transforming = class(ItemBaseClassBuff)
modifier_lone_druid_true_form_custom_talent_thinker = class(ItemBaseClass)
-------------
function modifier_lone_druid_true_form_custom_talent_thinker:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(FrameTime())
end

function modifier_lone_druid_true_form_custom_talent_thinker:OnIntervalThink()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_lone_druid_1")

    local bearForm = caster:FindModifierByName("modifier_lone_druid_true_form_custom")
    
    if talent ~= nil and talent:GetLevel() > 2 then
        if bearForm ~= nil and bearForm:GetRemainingTime() > 0 then
            -- Remove it first in case they have the regular ult active with a duration
            caster:RemoveModifierByName("modifier_lone_druid_true_form_custom")
        end

        if not bearForm then
            caster:AddNewModifier(caster, self:GetAbility(), "modifier_lone_druid_true_form_custom", {})
        end
    else
        if bearForm ~= nil and bearForm:GetRemainingTime() <= 0 then
            caster:RemoveModifierByName("modifier_lone_druid_true_form_custom")
        end
    end
end
-------------
function lone_druid_true_form_custom:GetIntrinsicModifierName()
    return "modifier_lone_druid_true_form_custom_talent_thinker"
end

function lone_druid_true_form_custom:GetBehavior()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_lone_druid_1")
    
    if talent ~= nil and talent:GetLevel() > 2 then
        return DOTA_ABILITY_BEHAVIOR_PASSIVE 
    end

    return self.BaseClass.GetBehavior(self) or 0
end

function lone_druid_true_form_custom:GetManaCost(level)
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_lone_druid_1")
    
    if talent ~= nil and talent:GetLevel() > 2 then
        return 0 
    end

    return self.BaseClass.GetManaCost(self, level) or 0
end

function lone_druid_true_form_custom:GetCooldown(level)
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_lone_druid_1")
    
    if talent ~= nil and talent:GetLevel() > 2 then
        return 0 
    end

    return self.BaseClass.GetCooldown(self, level) or 0
end

function lone_druid_true_form_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_lone_druid_true_form_custom_transforming", {
        duration = self:GetSpecialValueFor("transformation_time")
    })

    EmitSoundOn("Hero_LoneDruid.TrueForm.Cast", caster)
end
-------------
function modifier_lone_druid_true_form_custom_transforming:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    local particle = "particles/units/heroes/hero_lone_druid/lone_druid_true_form.vpcf"

    local effect_cast = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 3, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(effect_cast)
end

function modifier_lone_druid_true_form_custom_transforming:OnRemoved()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:AddNewModifier(parent, self:GetAbility(), "modifier_lone_druid_true_form_custom", {
        duration = self:GetAbility():GetSpecialValueFor("duration")
    })
end

function modifier_lone_druid_true_form_custom_transforming:CheckState()
    return {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true
    }
end

function modifier_lone_druid_true_form_custom_transforming:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE
    }
end

function modifier_lone_druid_true_form_custom_transforming:GetModifierModelChange()
    return "models/development/invisiblebox.vmdl"
end
----------------
function modifier_lone_druid_true_form_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_ATTACK_RANGE_BASE_OVERRIDE,
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_lone_druid_true_form_custom:OnAttackStart(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    EmitSoundOn("Hero_LoneDruid.TrueForm.PreAttack", event.target)
end

function modifier_lone_druid_true_form_custom:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    EmitSoundOn("Hero_LoneDruid.TrueForm.Attack", event.target)
end

function modifier_lone_druid_true_form_custom:GetModifierExtraHealthPercentage()
    return self:GetAbility():GetSpecialValueFor("bonus_hp_pct")
end

function modifier_lone_druid_true_form_custom:GetModifierPhysicalArmorBonus()
    if self.lock then return 0 end

    self.lock = true

    local armor = self:GetParent():GetPhysicalArmorValue(false)

    self.lock = false

    local bonus = armor * (self:GetAbility():GetSpecialValueFor("bonus_armor_pct")/100)
    
    return bonus
end

function modifier_lone_druid_true_form_custom:GetModifierSpellAmplify_Percentage()
    if not self:GetParent():HasScepter() then return 0 end
    if self.fDamage == nil then return 0 end
    if self.lockSpellAmp then return 0 end

    self.lockSpellAmp = true

    local spellDamage = self.fDamage

    self.lockSpellAmp = false

    local bonus = spellDamage * (self:GetAbility():GetSpecialValueFor("bonus_spell_damage_pct")/100)
    
    return bonus
end

function modifier_lone_druid_true_form_custom:GetModifierBonusStats_Intellect()
    if not self:GetParent():HasScepter() then return 0 end
    if self.lockIntellect then return 0 end

    self.lockIntellect = true

    local intellect = self:GetParent():GetBaseIntellect()

    self.lockIntellect = false

    local bonus = intellect * (self:GetAbility():GetSpecialValueFor("bonus_intellect_pct")/100)
    
    return bonus
end

function modifier_lone_druid_true_form_custom:GetModifierAttackRangeOverride()
    return 225
end

function modifier_lone_druid_true_form_custom:GetModifierModelChange()
    return "models/heroes/lone_druid/true_form.vmdl"
end

function modifier_lone_druid_true_form_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    local parent = self:GetParent()

    if not IsServer() then return end 

    parent:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)

    self:StartIntervalThink(0.1)
end

function modifier_lone_druid_true_form_custom:OnIntervalThink()
    self.damage = self:GetParent():GetSpellAmplification(false) * 100
    self:InvokeBonusDamage()
end

function modifier_lone_druid_true_form_custom:OnRemoved()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
end

function modifier_lone_druid_true_form_custom:RemoveOnDeath()
    return false
end

function modifier_lone_druid_true_form_custom:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_lone_druid_true_form_custom:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_lone_druid_true_form_custom:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end