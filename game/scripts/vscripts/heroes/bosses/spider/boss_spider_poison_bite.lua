LinkLuaModifier("modifier_boss_spider_poison_bite", "heroes/bosses/spider/boss_spider_poison_bite", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spider_poison_bite_debuff", "heroes/bosses/spider/boss_spider_poison_bite", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

boss_spider_poison_bite = class(ItemBaseClass)
modifier_boss_spider_poison_bite = class(boss_spider_poison_bite)
modifier_boss_spider_poison_bite_debuff = class(ItemBaseClassDebuff)
-------------
function boss_spider_poison_bite:GetIntrinsicModifierName()
    return "modifier_boss_spider_poison_bite"
end
-------------
function modifier_boss_spider_poison_bite:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_boss_spider_poison_bite:OnAttackLanded(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()
    
    local debuff = victim:FindModifierByName("modifier_boss_spider_poison_bite_debuff")
    if not debuff then
        debuff = victim:AddNewModifier(caster, ability, "modifier_boss_spider_poison_bite_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if debuff then
        debuff:IncrementStackCount()
        debuff:ForceRefresh()
    end
end
-------------
function modifier_boss_spider_poison_bite_debuff:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.25)
end

function modifier_boss_spider_poison_bite_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local damage = ability:GetSpecialValueFor("damage") * self:GetStackCount()

    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = damage,
        ability = ability,
        damage_type = ability:GetAbilityDamageType()
    })

    SendOverheadEventMessage(
        nil,
        OVERHEAD_ALERT_BONUS_POISON_DAMAGE,
        parent,
        damage,
        nil
    )
end

function modifier_boss_spider_poison_bite_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MISS_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }
    return funcs
end

function modifier_boss_spider_poison_bite_debuff:GetModifierMiss_Percentage()
    return self:GetAbility():GetSpecialValueFor("miss_chance")
end

function modifier_boss_spider_poison_bite_debuff:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("degen") * self:GetStackCount()
end

function modifier_boss_spider_poison_bite_debuff:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen") * self:GetStackCount()
end

function modifier_boss_spider_poison_bite_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen") * self:GetStackCount()
end

function modifier_boss_spider_poison_bite_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen") * self:GetStackCount()
end

function modifier_boss_spider_poison_bite_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_boss_spider_poison_bite_debuff:GetEffectName()
    return "particles/units/heroes/hero_broodmother/broodmother_incapacitatingbite_debuff.vpcf"
end