LinkLuaModifier("modifier_octarines_blessing", "items/octarine/item_octarines_blessing", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_octarines_blessing = class(ItemBaseClass)
item_octarines_blessing_2 = item_octarines_blessing
item_octarines_blessing_3 = item_octarines_blessing
item_octarines_blessing_4 = item_octarines_blessing
item_octarines_blessing_5 = item_octarines_blessing
item_octarines_blessing_6 = item_octarines_blessing
item_octarine_core = item_octarines_blessing
modifier_octarines_blessing = class(ItemBaseClass)

BANNED_ABILITIES = {
    "tinker_rearm",
    "chicken_ability_4",
    "chicken_ability_6",
    "arc_warden_tempest_double_custom",
    "templar_assassin_psi_blades_custom"
}

EXEMPT_ITEMS = {
    ["item_octarines_blessing"] = true,
    ["item_octarines_blessing_2"] = true,
    ["item_octarines_blessing_3"] = true,
    ["item_octarines_blessing_4"] = true,
    ["item_octarines_blessing_5"] = true,
    ["item_octarines_blessing_6"] = true,
    ["item_ex_machina"] = true,
    ["item_refresher"] = true,
    ["item_book_of_lies"] = true
}
-------------
function item_octarines_blessing:GetIntrinsicModifierName()
    return "modifier_octarines_blessing"
end

function IsItemException(item)
    return EXEMPT_ITEMS[item:GetName()]
end

function item_octarines_blessing:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local particle = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "DOTA_Item.Refresher.Activate", caster)

    for i=0, caster:GetAbilityCount()-1 do
        local abil = caster:GetAbilityByIndex(i)
        if abil ~= nil then
            local pass = true
            for _,banned in ipairs(BANNED_ABILITIES) do
                if abil:GetAbilityName() == banned then pass = false end
            end

            if pass then
                abil:EndCooldown()
            end
        end
    end

    for i=0,17 do
        local item = caster:GetItemInSlot(i)
        if item ~= nil then
            local pass = false
            if item:GetPurchaser() == caster and not IsItemException(item) then
                pass = true
            end

            if pass then
                item:EndCooldown()
            end
        end
    end
end
------------

function modifier_octarines_blessing:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.spell_lifesteal_percent = ability:GetLevelSpecialValueFor("creep_lifesteal", (ability:GetLevel() - 1))
end

function modifier_octarines_blessing:OnTakeDamage(event)
    if not IsServer() then return end
    
    if event.attacker == self:GetParent() and not event.unit:IsBuilding() and not event.unit:IsOther() then
        if self:GetParent():FindAllModifiersByName(self:GetName())[1] == self and (event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL or event.damage_type == DAMAGE_TYPE_MAGICAL) and event.inflictor and bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL and event.damage_flags ~= 1280 then
            local particle = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.attacker)
            ParticleManager:ReleaseParticleIndex(particle)

            if not event.attacker:IsAlive() or event.attacker:GetHealth() < 1 then return end
            
            local lifestealCreep = self.spell_lifesteal_percent
            local healAmount = math.max(event.damage, 0) * lifestealCreep * 0.01
            if healAmount < 0 or healAmount > INT_MAX_LIMIT then
                healAmount = self:GetParent():GetMaxHealth()
            end
            event.attacker:Heal(healAmount, event.attacker)
        end
    end
end

function modifier_octarines_blessing:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
        MODIFIER_PROPERTY_CAST_RANGE_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_octarines_blessing:GetModifierPercentageCooldown()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_cooldown", (self:GetAbility():GetLevel() - 1))
end

function modifier_octarines_blessing:GetModifierCastRangeBonus()
    return self:GetAbility():GetLevelSpecialValueFor("cast_range_bonus", (self:GetAbility():GetLevel() - 1))
end

function modifier_octarines_blessing:GetModifierHealthBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_health", (self:GetAbility():GetLevel() - 1))
end

function modifier_octarines_blessing:GetModifierManaBonus()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana", (self:GetAbility():GetLevel() - 1))
end

function modifier_octarines_blessing:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_octarines_blessing:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1))
end

function modifier_octarines_blessing:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_all_stats", (self:GetAbility():GetLevel() - 1)) + self:GetAbility():GetLevelSpecialValueFor("bonus_intellect", (self:GetAbility():GetLevel() - 1))
end

function modifier_octarines_blessing:GetModifierConstantManaRegen()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_mana_regen", (self:GetAbility():GetLevel() - 1))
end