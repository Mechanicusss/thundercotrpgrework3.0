LinkLuaModifier("modifier_battlemage_arsenal", "items/battlemage_arsenal/item_battlemage_arsenal", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_battlemage_arsenal_attack_buff", "items/battlemage_arsenal/item_battlemage_arsenal", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemDebuffBaseClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsPurgeException = function(self) return false end,
}

local ItemBuffBaseClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsPurgeException = function(self) return false end,
}

item_battlemage_arsenal = class(ItemBaseClass)
item_battlemage_arsenal_2 = item_battlemage_arsenal
item_battlemage_arsenal_3 = item_battlemage_arsenal
item_battlemage_arsenal_4 = item_battlemage_arsenal
item_battlemage_arsenal_5 = item_battlemage_arsenal
item_battlemage_arsenal_6 = item_battlemage_arsenal
item_battlemage_arsenal_7 = item_battlemage_arsenal
item_battlemage_arsenal_8 = item_battlemage_arsenal
modifier_battlemage_arsenal = class(item_battlemage_arsenal)
modifier_battlemage_arsenal_attack_buff = class(ItemBuffBaseClass)

function modifier_battlemage_arsenal_attack_buff:GetTexture() return "Battlemages_Arsenal" end
-------------
function item_battlemage_arsenal:GetIntrinsicModifierName()
    return "modifier_battlemage_arsenal"
end

function item_battlemage_arsenal:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local mod = caster:FindModifierByNameAndCaster("modifier_battlemage_arsenal_attack_buff", caster)
    if mod == nil then
        mod = caster:AddNewModifier(caster, self, "modifier_battlemage_arsenal_attack_buff", {
            duration = self:GetSpecialValueFor("duration")
        })
    end

    mod:ForceRefresh()

    EmitSoundOn("Item.Brooch.Cast", caster)
end
------------
function modifier_battlemage_arsenal_attack_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        MODIFIER_PROPERTY_ALWAYS_ETHEREAL_ATTACK,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_OVERRIDE_ATTACK_MAGICAL,
        MODIFIER_PROPERTY_OVERRIDE_ATTACK_DAMAGE,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
    }
    return funcs
end

function modifier_battlemage_arsenal_attack_buff:GetModifierOverrideAttackDamage() return 0 end

function modifier_battlemage_arsenal_attack_buff:GetModifierProcAttack_BonusDamage_Magical(keys)
    EmitSoundOn("Item.Brooch.Target.Ranged", keys.target)

    ApplyDamage({
        attacker = self:GetCaster(),
        victim = keys.target,
        damage = keys.original_damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })
    return 0
end

function modifier_battlemage_arsenal_attack_buff:GetOverrideAttackMagical()
    return 1
end

function modifier_battlemage_arsenal_attack_buff:GetAllowEtherealAttack()
    return 1
end

function modifier_battlemage_arsenal_attack_buff:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_battlemage_arsenal_attack_buff:GetModifierProjectileName()
    return "particles/arena/items_fx/desolator6_projectile.vpcf"
end

function modifier_battlemage_arsenal_attack_buff:GetEffectName()
    return "particles/items5_fx/revenant_brooch.vpcf"
end
------------

function modifier_battlemage_arsenal:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, -- GetModifierMoveSpeedBonus_Constant
        --MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierMPRegenAmplify_Percentage
        --MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, -- GetModifierSpellLifestealRegenAmplify_Percentage
        MODIFIER_EVENT_ON_ATTACK_LANDED, --OnAttackLanded
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_battlemage_arsenal:OnCreated()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    
    self.slow_duration = self:GetAbility():GetLevelSpecialValueFor("slow_duration", (self:GetAbility():GetLevel() - 1))
    self.slow_amount = self:GetAbility():GetLevelSpecialValueFor("slow", (self:GetAbility():GetLevel() - 1))
    self.int_multiplier = self:GetAbility():GetLevelSpecialValueFor("int_damage_multiplier", (self:GetAbility():GetLevel() - 1))
    self.delay = self:GetAbility():GetLevelSpecialValueFor("delay", (self:GetAbility():GetLevel() - 1))

    self.ready = true

    self.bonusAttackCooldown = false
    --self:StartIntervalThink(0.1)
end

function modifier_battlemage_arsenal:OnIntervalThink()
    local caster = self:GetCaster()

    if caster:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_INTELLECT then
        caster:DropItemAtPositionImmediate(self:GetAbility(), caster:GetAbsOrigin())
        DisplayError(caster:GetPlayerID(), "#primary_intellect_item")
    end

    self:StartIntervalThink(-1)
end

function modifier_battlemage_arsenal:OnRemoved()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if caster:HasModifier("modifier_battlemage_arsenal_attack_buff") then
        caster:RemoveModifierByName("modifier_battlemage_arsenal_attack_buff")
    end
end

function modifier_battlemage_arsenal:OnAttack(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local ability = self:GetAbility()

    if not ability or ability == nil then return end

    if self:GetCaster() ~= attacker then
        return
    end

    if not attacker:IsRangedAttacker() or not attacker:IsRealHero() then return end
    if self.bonusAttackCooldown then return end

    if attacker:HasModifier("modifier_nyx_assassin_vendetta") then
        attacker:RemoveModifierByName("modifier_nyx_assassin_vendetta")
    end

    Timers:CreateTimer(self.delay, function()
        if self.bonusAttackCooldown then return end

        attacker:PerformAttack(victim, true, true, true, false, true, false, true)
        
        self.bonusAttackCooldown = true
        local cd = ability:GetSpecialValueFor("double_attack_cd") * (1-(ability:GetEffectiveCooldown(ability:GetLevel())/100))

        Timers:CreateTimer(cd, function()
            self.bonusAttackCooldown = false
            self.ready = true
        end)
    end)
end

function modifier_battlemage_arsenal:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local ability = self:GetAbility()

    if not ability or ability == nil then return end

    if self:GetCaster() ~= attacker then
        return
    end

    if victim:IsMagicImmune() or not attacker:IsRealHero() then return end
    --if not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim) then return end
    --if not self.ready then return end

    --self.ready = false
end

function modifier_battlemage_arsenal:GetModifierHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierPreAttack_BonusDamage()
    local damageFromMana = self:GetParent():GetMaxMana() * (self:GetAbility():GetSpecialValueFor("damage_from_max_mana")/100)
    return self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1)) + damageFromMana
end

function modifier_battlemage_arsenal:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_movement_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_spell_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierMPRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("mana_regen_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_battlemage_arsenal:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("spell_lifesteal_amp", (self:GetAbility():GetLevel() - 1))
end