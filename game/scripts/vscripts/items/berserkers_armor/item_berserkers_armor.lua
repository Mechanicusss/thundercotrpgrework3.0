LinkLuaModifier("modifier_berserkers_armor", "items/berserkers_armor/item_berserkers_armor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_berserkers_armor_toggle", "items/berserkers_armor/item_berserkers_armor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_berserkers_armor_enrage", "items/berserkers_armor/item_berserkers_armor", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseToggleClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

local ItemBaseEnrageClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

item_berserkers_armor = class(ItemBaseClass)
item_berserkers_armor_2 = item_berserkers_armor
item_berserkers_armor_3 = item_berserkers_armor
item_berserkers_armor_4 = item_berserkers_armor
item_berserkers_armor_5 = item_berserkers_armor
item_berserkers_armor_6 = item_berserkers_armor
modifier_berserkers_armor_toggle = class(ItemBaseToggleClass)
modifier_berserkers_armor_enrage = class(ItemBaseEnrageClass)
modifier_berserkers_armor = class(item_berserkers_armor)
function modifier_berserkers_armor_enrage:GetTexture() return "berserkersarmor" end
function modifier_berserkers_armor_toggle:GetTexture() return "berserkersarmor" end
-------------
function item_berserkers_armor:GetIntrinsicModifierName()
    return "modifier_berserkers_armor"
end

function item_berserkers_armor:GetAbilityTextureName()
    if self:GetToggleState() then
        return "berserkersarmor_toggle"
    end

    if self:GetLevel() == 1 then
        return "berserkersarmor"
    elseif self:GetLevel() == 2 then
        return "berserkersarmor2"
    elseif self:GetLevel() == 3 then
        return "berserkersarmor3"
    elseif self:GetLevel() == 4 then
        return "berserkersarmor4"
    elseif self:GetLevel() == 5 then
        return "berserkersarmor5"
    elseif self:GetLevel() == 6 then
        return "berserkersarmor6"
    end
end

function item_berserkers_armor:ResetToggleOnRespawn()
    return true
end

function item_berserkers_armor:OnToggle()
    local caster = self:GetCaster()

    if self:GetToggleState() then
        EmitSoundOnLocationForPlayer("DOTA_Item.Armlet.Activate", caster:GetOrigin(), caster:GetPlayerID())
        caster:AddNewModifier(caster, self, "modifier_berserkers_armor_toggle", {})
        caster:AddNewModifier(caster, self, "modifier_berserkers_armor_enrage", {})
    else
        EmitSoundOnLocationForPlayer("DOTA_Item.Armlet.DeActivate", caster:GetOrigin(), caster:GetPlayerID())
        caster:RemoveModifierByName("modifier_berserkers_armor_toggle")
        caster:RemoveModifierByName("modifier_berserkers_armor_enrage")
    end
end
------------
function modifier_berserkers_armor_enrage:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
    }

    return funcs
end

function modifier_berserkers_armor_enrage:GetModifierPreAttack_BonusDamage()
    local stacks = self:GetParent():GetModifierStackCount("modifier_berserkers_armor_enrage", self:GetParent())
    local damage = self:GetParent():GetStrength() * (self:GetAbility():GetLevelSpecialValueFor("enrage_damage_from_str_pct", (self:GetAbility():GetLevel() - 1))/100)
    return stacks * damage
end

function modifier_berserkers_armor_enrage:GetModifierAttackSpeedBonus_Constant()
    local stacks = self:GetParent():GetModifierStackCount("modifier_berserkers_armor_enrage", self:GetParent())
    return stacks * self:GetAbility():GetLevelSpecialValueFor("enrage_attack_speed_gain", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor_enrage:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster:IsIllusion() then
        local owner = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID())

        if owner:HasModifier("modifier_berserkers_armor_enrage") then
            caster:SetModifierStackCount("modifier_berserkers_armor_enrage", caster, owner:GetModifierStackCount("modifier_berserkers_armor_enrage", owner))
        end
    end

    self:StartIntervalThink(1.0)
end

function modifier_berserkers_armor_enrage:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if caster:IsIllusion() or not caster:IsHero() then
        return
    end

    local drain = ability:GetLevelSpecialValueFor("enrage_drain_per_second", (ability:GetLevel() - 1)) 
    local drainPct = ability:GetLevelSpecialValueFor("enrage_drain_per_second_pct", (ability:GetLevel() - 1)) 
    local totalDrain = drain + (caster:GetMaxHealth() * (drainPct/100)) * caster:GetModifierStackCount("modifier_berserkers_armor_enrage", caster)

    --local currentHealth = caster:GetHealth()
    --local updatedHealth = currentHealth - totalDrain

    --if updatedHealth < 1 or currentHealth < 1 then -- Should maybe fix berserker making you stuck at 0 hp if you kill yourself with it?
        --caster:ForceKill(false)
    --end

    ApplyDamage({
        victim = caster,
        attacker = caster,
        damage = totalDrain,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
    })

    --caster:SetHealth(updatedHealth) -- Because the interval ticks every 0.5s we only drain half
end
------------
function modifier_berserkers_armor_toggle:OnCreated()
    if not IsServer() then return end

    self.particleCaster = self:GetCaster()
    self.particleCaster.particle = ParticleManager:CreateParticle("particles/items_fx/armlet.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.particleCaster)
    
    ParticleManager:SetParticleControlEnt(self.particleCaster.particle, 0, self.particleCaster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self.particleCaster:GetAbsOrigin(), true)

    self:StartIntervalThink(1.0)
end

function modifier_berserkers_armor_toggle:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if caster:IsIllusion() or not caster:IsHero() then
        return
    end

    local maxStacks = ability:GetLevelSpecialValueFor("enrage_max_stacks", (ability:GetLevel() - 1))
    local stacks = caster:GetModifierStackCount("modifier_berserkers_armor_enrage", caster)

    if stacks < maxStacks then
        caster:SetModifierStackCount("modifier_berserkers_armor_enrage", caster, (stacks + 1))
    end
end

function modifier_berserkers_armor_toggle:OnRemoved()
    if not IsServer() then return end
    ParticleManager:DestroyParticle(self.particleCaster.particle, true)
end

function modifier_berserkers_armor_toggle:OnRespawn()
    if not IsServer() then return end
    ParticleManager:DestroyParticle(self.particleCaster.particle, true)
end

function modifier_berserkers_armor_toggle:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE, --GetModifierExtraHealthPercentage
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS, --GetModifierExtraHealthBonus
    }

    return funcs
end

function modifier_berserkers_armor_toggle:GetModifierExtraHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("toggle_max_health_increase_flat", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor_toggle:GetModifierExtraHealthPercentage()
    return self:GetAbility():GetLevelSpecialValueFor("toggle_max_health_increase_pct", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor_toggle:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("toggle_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor_toggle:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("toggle_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor_toggle:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("toggle_bonus_armor", (self:GetAbility():GetLevel() - 1))
end
------------

function modifier_berserkers_armor:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,--GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, --GetModifierConstantHealthRegen
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }

    return funcs
end

function modifier_berserkers_armor:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker

    if self:GetParent() ~= attacker then
        return
    end

    if event.target:GetUnitName() == "npc_tcot_tormentor" then return end

    local lifestealAmount = self:GetAbility():GetSpecialValueFor("lifesteal")

    if lifestealAmount < 1 or not attacker:IsAlive() or attacker:GetHealth() < 1 or event.target:IsOther() or event.target:IsBuilding() then
        return
    end

    local heal = event.damage * (lifestealAmount/100)

    --local heal = attacker:GetLevel() + self.lifestealAmount

    if attacker:IsIllusion() then -- Illusions only heal for 10% of the value
        heal = heal * 0.1
    end
    
    --attacker:SetHealth(attacker:GetHealth() + heal) DO NOT USE! Ignores regen reduction
    if heal < 0 or heal > INT_MAX_LIMIT then
        heal = self:GetParent():GetMaxHealth()
    end
    attacker:Heal(heal, nil)

    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_berserkers_armor:OnRemoved()
    if not IsServer() then return end

    if self:GetAbility():GetToggleState() then
        self:GetAbility():ToggleAbility()
    end
end

function modifier_berserkers_armor:OnCreated()
    if not IsServer() then return end

    --self:StartIntervalThink(0.1)
end

function modifier_berserkers_armor:OnIntervalThink()
    local caster = self:GetCaster()

    if caster:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_STRENGTH then
        caster:DropItemAtPositionImmediate(self:GetAbility(), caster:GetAbsOrigin())
        DisplayError(caster:GetPlayerID(), "#primary_strength_item")
    end

    self:StartIntervalThink(-1)
end

function modifier_berserkers_armor:OnRespawn()
    if not IsServer() then return end

    if self:GetAbility():GetToggleState() then
        self:GetAbility():ToggleAbility()
    end
end

function modifier_berserkers_armor:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor:GetModifierConstantHealthRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_berserkers_armor:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end