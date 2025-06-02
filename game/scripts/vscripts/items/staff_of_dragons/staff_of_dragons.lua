LinkLuaModifier("modifier_item_staff_of_dragons", "items/staff_of_dragons/staff_of_dragons", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_staff_of_dragons_debuff", "items/staff_of_dragons/staff_of_dragons", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_staff_of_dragons_debuff_burning", "items/staff_of_dragons/staff_of_dragons", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_staff_of_dragons = class(ItemBaseClass)
item_staff_of_dragons_2 = item_staff_of_dragons
item_staff_of_dragons_3 = item_staff_of_dragons
item_staff_of_dragons_4 = item_staff_of_dragons
item_staff_of_dragons_5 = item_staff_of_dragons
item_staff_of_dragons_6 = item_staff_of_dragons
item_staff_of_dragons_7 = item_staff_of_dragons
item_staff_of_dragons_8 = item_staff_of_dragons
modifier_item_staff_of_dragons = class(ItemBaseClass)
modifier_item_staff_of_dragons_debuff = class(ItemDebuff)
modifier_item_staff_of_dragons_debuff_burning = class(ItemDebuff)
function modifier_item_staff_of_dragons_debuff:GetTexture() return "staffofdragons" end
-------------
function item_staff_of_dragons:GetIntrinsicModifierName()
    return "modifier_item_staff_of_dragons"
end
---
function modifier_item_staff_of_dragons_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS , --GetModifierMagicalResistanceBonus
    }
    return funcs
end

function modifier_item_staff_of_dragons_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_shred")
end
---

function modifier_item_staff_of_dragons:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, -- GetModifierMoveSpeedBonus_Constant
        MODIFIER_EVENT_ON_TAKEDAMAGE, --OnTakeDamage
    }

    return funcs
end

function modifier_item_staff_of_dragons:OnTakeDamage(event)
    if not IsServer() then return end
    
    local damageType = event.damage_type

    --[[if event.attacker ~= self:GetParent() then 
        if event.attacker:GetOwner() ~= nil then
            if not event.attacker:GetOwner():IsPlayerController() then
                if event.attacker:GetOwner():GetUnitName() == "npc_dota_hero_shadow_shaman" then
                    event.attacker = event.attacker:GetOwner()
                    damageType = DAMAGE_TYPE_MAGICAL
                else
                    return 
                end
            else 
                return
            end
        else
            return 
        end
    end--]]

    if event.attacker ~= self:GetParent() or event.attacker == event.unit then return end
    if damageType ~= DAMAGE_TYPE_MAGICAL then return end
    if event.inflictor ~= nil then
        if event.inflictor == self:GetAbility() or string.find(event.inflictor:GetAbilityName(), "diabolic_edict") then return end
    end

    local victim = event.unit

    victim:AddNewModifier(event.attacker, self:GetAbility(), "modifier_item_staff_of_dragons_debuff", {
        duration = self:GetAbility():GetSpecialValueFor("duration")
    })

    ---
    local debuff = victim:FindModifierByName("modifier_item_staff_of_dragons_debuff_burning")
    if debuff == nil then
        debuff = victim:AddNewModifier(event.attacker, self:GetAbility(), "modifier_item_staff_of_dragons_debuff_burning", {
            duration = self:GetAbility():GetSpecialValueFor("duration")
        })
    end

    if debuff ~= nil then
        if debuff:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end
        debuff:ForceRefresh()
    end
end

function modifier_item_staff_of_dragons:GetModifierBonusStats_Intellect()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_staff_of_dragons:GetModifierBonusStats_Agility()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_staff_of_dragons:GetModifierSpellAmplify_Percentage()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

function modifier_item_staff_of_dragons:GetModifierBonusStats_Strength()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_staff_of_dragons:GetModifierPhysicalArmorBonus()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_staff_of_dragons:GetModifierMoveSpeedBonus_Constant()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end
--

function modifier_item_staff_of_dragons:OnCreated()
    if not IsServer() then return end
end
--------
function modifier_item_staff_of_dragons_debuff_burning:IsStackable()
    return true
end

function modifier_item_staff_of_dragons_debuff_burning:OnCreated()
    if not IsServer() then return end

    self.damage = self:GetAbility():GetSpecialValueFor("damage")

    self.damageTable = {
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    }

    self:OnIntervalThink()
    self:StartIntervalThink(1)
end

function modifier_item_staff_of_dragons_debuff_burning:OnIntervalThink()
    self.damageTable.damage = self.damage * self:GetStackCount()
    ApplyDamage(self.damageTable)
end

function modifier_item_staff_of_dragons_debuff_burning:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
