LinkLuaModifier("modifier_mage_masher", "items/item_mage_masher/item_mage_masher", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_mage_masher = class(ItemBaseClass)
item_mage_masher_2 = item_mage_masher
item_mage_masher_3 = item_mage_masher
item_mage_masher_4 = item_mage_masher
item_mage_masher_5 = item_mage_masher
item_mage_masher_6 = item_mage_masher
item_mage_masher_7 = item_mage_masher
modifier_mage_masher = class(item_mage_masher)
-------------
function item_mage_masher:GetIntrinsicModifierName()
    return "modifier_mage_masher"
end

function item_mage_masher:OnSpellStart()
    if not IsServer() then return end

    local ability = self
    local target = self:GetCursorTarget()
    local duration = 0.4

    if not ability or ability:IsNull() then return end

    if self:GetCaster():GetTeamNumber() == target:GetTeamNumber() then
        EmitSoundOn("DOTA_Item.ForceStaff.Activate", target)
        target:AddNewModifier(self:GetCaster(), ability, "modifier_mage_masher_force_ally", {duration = duration })
    else
        -- If the target possesses a ready Linken's Sphere, do nothing
        if target:TriggerSpellAbsorb(ability) then return end
    
        target:AddNewModifier(self:GetCaster(), ability, "modifier_mage_masher_force_enemy", {duration = duration})
        self:GetCaster():AddNewModifier(target, ability, "modifier_mage_masher_force_self", {duration = duration})
        local buff = self:GetCaster():AddNewModifier(self:GetCaster(), ability, "modifier_mage_masher_attack_speed", {duration = ability:GetSpecialValueFor("range_duration")})
        buff.target = target
        buff:SetStackCount(ability:GetSpecialValueFor("max_attacks"))
        EmitSoundOn("DOTA_Item.ForceStaff.Activate", target)
        EmitSoundOn("DOTA_Item.ForceStaff.Activate", self:GetCaster())
        
        if self:GetCaster():IsRangedAttacker() then
            local startAttack = {
                UnitIndex = self:GetCaster():entindex(),
                OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
                TargetIndex = target:entindex(),}
            ExecuteOrderFromTable(startAttack)
        end
    end
end

function modifier_mage_masher:OnCreated()
    if IsServer() then
        if not self:GetAbility() then self:Destroy() end
    end
end
------------
function modifier_mage_masher:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_BONUS, --GetModifierHealthBonus
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,--GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, --GetModifierAttackRangeBonus
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS, --GetModifierProjectileSpeedBonus
    }

    return funcs
end

function modifier_mage_masher:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    
    if ability and not ability:IsNull() then
        self.health = self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
        self.damage = self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
        self.agility = self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
        self.strength = self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
        self.intellect = self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
        self.magicArmor = self:GetAbility():GetLevelSpecialValueFor("bonus_magical_armor", (self:GetAbility():GetLevel() - 1))
        self.range = self:GetAbility():GetLevelSpecialValueFor("base_attack_range", (self:GetAbility():GetLevel() - 1))
    end
end

function modifier_mage_masher:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local ability = self:GetAbility()

    if self:GetCaster() ~= attacker or not UnitIsNotMonkeyClone(attacker) then return end
    if not IsBossTCOTRPG(victim) and not IsCreepTCOTRPG(victim) then return end

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end

    local distance = (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D()
    if distance < ability:GetSpecialValueFor("min_damage_range") then return end

    if distance > ability:GetSpecialValueFor("max_damage_range") then
        distance = ability:GetSpecialValueFor("max_damage_range")
    end

    local multiplier = (distance / ability:GetSpecialValueFor("range_falloff_multiplier"))

    return multiplier
end

function modifier_mage_masher:GetModifierProjectileSpeedBonus()
    return self:GetAbility():GetSpecialValueFor("proj_speed")
end

function modifier_mage_masher:GetModifierHealthBonus()
    return self.health or self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierPreAttack_BonusDamage()
    return self.damage or self:GetAbility():GetLevelSpecialValueFor("bonus_damage", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierBonusStats_Agility()
    return self.agility or self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierBonusStats_Strength()
    return self.strength or self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierBonusStats_Intellect()
    return self.intellect or self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierMagicalResistanceBonus()
    return self.magicArmor or self:GetAbility():GetLevelSpecialValueFor("bonus_magical_armor", (self:GetAbility():GetLevel() - 1))
end

function modifier_mage_masher:GetModifierAttackRangeBonus()
    if not self:GetCaster():IsRangedAttacker() then return end
    
    return self.range or self:GetAbility():GetLevelSpecialValueFor("base_attack_range", (self:GetAbility():GetLevel() - 1))
end