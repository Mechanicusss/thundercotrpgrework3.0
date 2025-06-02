LinkLuaModifier("modifier_item_armor_piercing_crossbow", "armor_piercing_crossbow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_armor_piercing_crossbow_debuff", "armor_piercing_crossbow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_armor_piercing_crossbow_active", "armor_piercing_crossbow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_armor_piercing_crossbow_dawn_debuff", "armor_piercing_crossbow", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_armor_piercing_crossbow = class(ItemBaseClass)
item_armor_piercing_crossbow_2 = item_armor_piercing_crossbow
item_armor_piercing_crossbow_3 = item_armor_piercing_crossbow
item_armor_piercing_crossbow_4 = item_armor_piercing_crossbow
item_armor_piercing_crossbow_5 = item_armor_piercing_crossbow
item_armor_piercing_crossbow_6 = item_armor_piercing_crossbow
item_armor_piercing_crossbow_7 = item_armor_piercing_crossbow
item_armor_piercing_crossbow_8 = item_armor_piercing_crossbow
modifier_item_armor_piercing_crossbow = class(ItemBaseClass)
modifier_item_armor_piercing_crossbow_debuff = class(ItemBaseClassDebuff)
modifier_item_armor_piercing_crossbow_active = class(ItemBaseClassBuff)
modifier_item_armor_piercing_crossbow_dawn_debuff = class(ItemBaseClassDebuff)
-------------
function item_armor_piercing_crossbow:GetIntrinsicModifierName()
    return "modifier_item_armor_piercing_crossbow"
end

function item_armor_piercing_crossbow:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function item_armor_piercing_crossbow:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_item_armor_piercing_crossbow_active", {
        duration = self:GetSpecialValueFor("active_duration")
    })

    EmitSoundOn("Item.Brooch.Cast", caster)
end

function modifier_item_armor_piercing_crossbow:GetEffectName() 
    if self:GetAbility():GetLevel() == 8 then
        return "particles/units/heroes/hero_clinkz/clinkz_burning_army_ambient_2.vpcf"
    end
end

function modifier_item_armor_piercing_crossbow:GetModifierProjectileName() 
    if self:GetAbility():GetLevel() == 8 and self:GetParent():IsRangedAttacker() then
        return "particles/econ/items/clinkz/clinkz_maraxiform/clinkz_ti9_summon_projectile_arrow.vpcf"
    end
end

function modifier_item_armor_piercing_crossbow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE_POST_CRIT,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK
    }
    return funcs
end

function modifier_item_armor_piercing_crossbow:OnAttackRecordDestroy(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end 

    local target = event.target

    target:RemoveModifierByName("modifier_item_armor_piercing_crossbow_debuff")
end

function modifier_item_armor_piercing_crossbow:OnAttackLanded(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if unit:IsIllusion() then return end

    if not caster:IsAlive() then
        return
    end

    if ability:GetLevel() ~= 8 then return end

    local debuff = victim:FindModifierByName("modifier_item_armor_piercing_crossbow_dawn_debuff")
    if debuff == nil then
        debuff = victim:AddNewModifier(unit, ability, "modifier_item_armor_piercing_crossbow_dawn_debuff", {
            duration = ability:GetSpecialValueFor("dawn_debuff_duration")
        })
    end

    if debuff ~= nil then
        debuff:ForceRefresh()
    end
end

function modifier_item_armor_piercing_crossbow:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_armor_piercing_crossbow:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_armor_piercing_crossbow:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_item_armor_piercing_crossbow:OnIntervalThink()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    if ability:GetLevel() == 8 then
        if parent:GetLevel() < MAX_LEVEL then
            DisplayError(parent:GetPlayerID(), "Requires Level " .. MAX_LEVEL)
            parent:DropItemAtPositionImmediate(ability, parent:GetAbsOrigin())
        end
    end
end

function modifier_item_armor_piercing_crossbow:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
            
            local ability = self:GetAbility()
            local victimArmor = params.target:GetPhysicalArmorValue(false)
            local reducedArmor = victimArmor * (ability:GetSpecialValueFor("ignore_armor_pct")/100)
            
            params.target:AddNewModifier(self:GetParent(), ability, "modifier_item_armor_piercing_crossbow_debuff", {
                armor = -reducedArmor
            })

            EmitSoundOn("DOTA_Item.Daedelus.Crit", params.target)
        end
    end
end

function modifier_item_armor_piercing_crossbow:GetModifierPreAttack_CriticalStrike(keys)
    local ability = self:GetAbility()
    local unit = self:GetParent()

    local crit = ability:GetSpecialValueFor("crit_chance")
    if unit:HasModifier("modifier_item_armor_piercing_crossbow_active") then
        crit = crit + ability:GetSpecialValueFor("active_chance")
    end

    if RollPercentage(crit) then
        self.record = keys.record

        return ability:GetSpecialValueFor("crit_multiplier")
    end
end
-----------
function modifier_item_armor_piercing_crossbow_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
    }
end


function modifier_item_armor_piercing_crossbow_debuff:OnCreated(props)
    self.armor = props.armor
end

function modifier_item_armor_piercing_crossbow_debuff:GetModifierPhysicalArmorBonus()
    if IsServer() then
        return self.armor
    end
end
----------
function modifier_item_armor_piercing_crossbow_dawn_debuff:IsHidden() return false end

function modifier_item_armor_piercing_crossbow_dawn_debuff:GetEffectName() return "particles/econ/items/huskar/huskar_2021_immortal/huskar_2021_immortal_burning_spear_debuff_gold.vpcf" end
function modifier_item_armor_piercing_crossbow_dawn_debuff:GetTexture() return "crossbow8" end

function modifier_item_armor_piercing_crossbow_dawn_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local attacker = self:GetCaster()
    local ability = self:GetAbility()

    self.damageTable = {
        attacker = attacker,
        victim = parent,
        ability = ability,
        damage_type = DAMAGE_TYPE_PHYSICAL,
    }

    self:StartIntervalThink(0.2)
end

function modifier_item_armor_piercing_crossbow_dawn_debuff:OnIntervalThink() 
    local attacker = self:GetCaster()
    local ability = self:GetAbility()

    self.damageTable.damage = attacker:GetAverageTrueAttackDamage(attacker) * (ability:GetSpecialValueFor("dawn_dps_from_atk")/100) * 0.2

    ApplyDamage(self.damageTable)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, self:GetParent(), self.damageTable.damage, nil)
end
