LinkLuaModifier("modifier_scorching_malevolence", "scorching_malevolence", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scorching_malevolence_burning", "scorching_malevolence", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scorching_malevolence_debuff_crit", "scorching_malevolence", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scorching_malevolence_debuff", "scorching_malevolence", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

local ItemBaseDebuffClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    GetEffectAttachType = function() return PATTACH_OVERHEAD_FOLLOW end,
    GetEffectName =       function() return "particles/items2_fx/orchid.vpcf" end,
}

item_scorching_malevolence = class(ItemBaseClass)
item_scorching_malevolence2 = item_scorching_malevolence
item_scorching_malevolence3 = item_scorching_malevolence
item_scorching_malevolence4 = item_scorching_malevolence
modifier_scorching_malevolence = class(item_scorching_malevolence)
modifier_scorching_malevolence_debuff = class(ItemBaseDebuffClass)
modifier_scorching_malevolence_debuff_crit = class(ItemBaseClass)
modifier_scorching_malevolence_burning = class(ItemBaseClassAura)
-------------
function item_scorching_malevolence:GetIntrinsicModifierName()
    return "modifier_scorching_malevolence"
end

function item_scorching_malevolence:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    local target = self:GetCursorTarget()
    local duration = self:GetLevelSpecialValueFor("silence_duration", (self:GetLevel() - 1)) 

    target:AddNewModifier(caster, ability, "modifier_scorching_malevolence_debuff", { duration = duration })

    EmitSoundOnLocationWithCaster(target:GetOrigin(), "DOTA_Item.Bloodthorn.Activate", target)
end
------------
function modifier_scorching_malevolence_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_NEGATIVE_EVASION_CONSTANT, --GetModifierNegativeEvasion_Constant   
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_ATTACK_START, 
    }
    return funcs
end

function modifier_scorching_malevolence_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_PASSIVES_DISABLED] = true
    }
    return state
end

function modifier_scorching_malevolence_debuff:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("target_crit_multiplier")
end

function modifier_scorching_malevolence_debuff:OnTakeDamage(keys)
    if not IsServer() then return end
    local parent = self:GetParent()
    if parent == keys.unit then
        ParticleManager:SetParticleControl(ParticleManager:CreateParticle("particles/items2_fx/orchid_pop.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.unit), 1, Vector(keys.damage))
        self.damage = (self.damage or 0) + keys.damage
    end
end

function modifier_scorching_malevolence_debuff:OnAttackStart(keys)
    if not IsServer() then return end
    local parent = self:GetParent()
    if parent == keys.target then
        local ability = self:GetAbility()
        keys.attacker:AddNewModifier(parent, self:GetAbility(), "modifier_scorching_malevolence_debuff_crit", {duration = 1.5})
    end
end

function modifier_scorching_malevolence_debuff:OnDestroy()
    if not IsServer() then return end
    local ability = self:GetAbility()
    local parent = self:GetParent()
    local damage = (self.damage or 0) * ability:GetSpecialValueFor("silence_damage_percent") * 0.01
    ParticleManager:SetParticleControl(ParticleManager:CreateParticle("particles/items2_fx/orchid_pop.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent), 1, Vector(damage))
    if damage > 0 then
        ApplyDamage({
            attacker = self:GetCaster(),
            victim = parent,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
            ability = ability
        })
    end
end

function modifier_scorching_malevolence_debuff_crit:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_scorching_malevolence_debuff_crit:GetModifierPreAttack_CriticalStrike(keys)
    if not IsServer() then return end
    if keys.target == self:GetCaster() and keys.target:HasModifier("modifier_scorching_malevolence_debuff") then
        return self:GetAbility():GetSpecialValueFor("target_crit_multiplier")
    else
        self:Destroy()
    end
end

function modifier_scorching_malevolence_debuff_crit:OnAttackLanded(keys)
    if not IsServer() then return end
    if self:GetParent() == keys.attacker then
        keys.attacker:RemoveModifierByName("modifier_scorching_malevolence_debuff_crit")
    end
end

function modifier_scorching_malevolence_debuff:OnCreated(params)
    if not IsServer() then return end
    self.damage = 0
end

function modifier_scorching_malevolence_debuff:GetModifierNegativeEvasion_Constant()
    return 9999
end
------------
function modifier_scorching_malevolence:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_BONUS_DAY_VISION, --GetBonusDayVision
        MODIFIER_PROPERTY_EVASION_CONSTANT, --GetModifierEvasion_Constant
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_scorching_malevolence:GetModifierPreAttack_CriticalStrike(k)
    if not IsServer() then return end

    local ability = self:GetAbility()
    if RollPercentage(ability:GetSpecialValueFor("tooltip_crit_chance")) then
        return ability:GetSpecialValueFor("tooltip_crit_chance")
    end
end

function modifier_scorching_malevolence:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_scorching_malevolence:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_scorching_malevolence:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_scorching_malevolence:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_scorching_malevolence:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_magic_resist", (self:GetAbility():GetLevel() - 1))
end

function modifier_scorching_malevolence:GetBonusDayVision()
    return self:GetAbility():GetLevelSpecialValueFor("upgrade_day_vision", (self:GetAbility():GetLevel() - 1))
end

function modifier_scorching_malevolence:GetModifierEvasion_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("evasion", (self:GetAbility():GetLevel() - 1))
end

function modifier_scorching_malevolence:OnCreated()
    if not IsServer() then return end
end

function modifier_scorching_malevolence:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end
    if parent:IsMuted() then return end

    local victim = event.target
    if victim:IsMagicImmune() or victim:IsInvulnerable() then return end

    local ability = self:GetAbility()
    local duration = ability:GetSpecialValueFor("burn_duration")

    local debuff = victim:FindModifierByName("modifier_scorching_malevolence_burning")
    if debuff == nil then
        debuff = victim:AddNewModifier(parent, ability, "modifier_scorching_malevolence_burning", {
            duration = duration
        })
    end

    if debuff ~= nil then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("burn_max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end
end
-----------------
function modifier_scorching_malevolence_burning:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_scorching_malevolence_burning:DeclareFunctions()
    local funcs = { 
        MODIFIER_PROPERTY_MISS_PERCENTAGE, --GetModifierMiss_Percentage
    }
    return funcs
end

function modifier_scorching_malevolence_burning:GetModifierMiss_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("blind_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_scorching_malevolence_burning:OnCreated()
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.interval = self.ability:GetSpecialValueFor("burn_interval")

    local burnIntToDamage = self.ability:GetSpecialValueFor("burn_int_to_damage")
    local damage = self.ability:GetSpecialValueFor("burn_damage")

    self.damageTable = {
        victim = self.parent, 
        attacker = self.caster, 
        damage = (damage + (self.caster:GetBaseIntellect() * (burnIntToDamage / 100))) * self:GetStackCount(), 
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability
    }

    self:StartIntervalThink(self.interval)
end

function modifier_scorching_malevolence_burning:OnStackCountChanged()
    if not IsServer() then return end

    local burnIntToDamage = self.ability:GetSpecialValueFor("burn_int_to_damage")
    local damage = self.ability:GetSpecialValueFor("burn_damage")

    self.damageTable.damage = (damage + (self.caster:GetBaseIntellect() * (burnIntToDamage / 100))) * self:GetStackCount()
end

function modifier_scorching_malevolence_burning:OnIntervalThink()
    ApplyDamage(self.damageTable)
end

function modifier_scorching_malevolence_burning:GetEffectName()
    return "particles/econ/events/ti6/radiance_ti6.vpcf"
end

function modifier_scorching_malevolence_burning:GetTexture()
    return "item_scorching_malevolence"
end