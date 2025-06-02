LinkLuaModifier("modifier_item_spire_of_aggron", "items/item_spire_of_aggron/item_spire_of_aggron", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_spire_of_aggron_buff", "items/item_spire_of_aggron/item_spire_of_aggron", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
}

item_spire_of_aggron = class(ItemBaseClass)
item_spire_of_aggron_2 = item_spire_of_aggron
item_spire_of_aggron_3 = item_spire_of_aggron
item_spire_of_aggron_4 = item_spire_of_aggron
item_spire_of_aggron_5 = item_spire_of_aggron
item_spire_of_aggron_6 = item_spire_of_aggron
item_spire_of_aggron_7 = item_spire_of_aggron
item_spire_of_aggron_8 = item_spire_of_aggron
modifier_item_spire_of_aggron = class(item_spire_of_aggron)
modifier_item_spire_of_aggron_buff = class(ItemBaseClassBuff)
-------------
function item_spire_of_aggron:GetIntrinsicModifierName()
    return "modifier_item_spire_of_aggron"
end

function modifier_item_spire_of_aggron:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, --GetModifierBonusStats_Intellect
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, -- GetModifierMoveSpeedBonus_Constant
        MODIFIER_PROPERTY_MANA_BONUS, --GetModifierManaBonus
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, --GetModifierConstantManaRegen
    }
    return funcs
end


function modifier_item_spire_of_aggron:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.count = 0
end

function modifier_item_spire_of_aggron:OnAbilityFullyCast(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then return end

    local noTarget = false

    if event.target == nil then noTarget = true end

    local parent = self:GetParent()
    local inflictor = event.ability
    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    if inflictor:IsItem() then return end
    if inflictor:GetAbilityName() == "void_spirit_aether_remnant_custom" or inflictor:GetAbilityName() == "timbersaw_chakram_custom" or inflictor:GetAbilityName() == "timbersaw_chakram_2_custom" or inflictor:GetAbilityName() == "hoodwink_sharpshooter_custom" or inflictor:GetAbilityName() == "hoodwink_sharpshooter_cancel_custom" or inflictor:GetAbilityName() == "zuus_transcendence_custom" or inflictor:GetAbilityName() == "zuus_transcendence_custom_descend" or inflictor:GetAbilityName() == "necrolyte_reaper_form" or inflictor:GetAbilityName() == "necrolyte_reaper_form_exit" or inflictor:GetAbilityName() == "lich_ice_spire_custom" then return end
    if bit.band(inflictor:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_CHANNELLED) ~= 0 then return end
    
    if not RollPercentage(ability:GetSpecialValueFor("chance")) then
        parent:RemoveModifierByName("modifier_item_spire_of_aggron_buff")
        self.count = 0
        return
    end

    self.count = self.count + 1

    --(self.count % 2) == 0
    if self.count > 0 then
        local buff = parent:FindModifierByName("modifier_item_spire_of_aggron_buff")
        if buff == nil then
            buff = parent:AddNewModifier(parent, ability, "modifier_item_spire_of_aggron_buff", {
                duration = ability:GetSpecialValueFor("consec_spell_amp_duration")
            })

            buff:SetStackCount(1)
        else
            buff:SetStackCount(self.count)
        end
    end

    local castPos = parent:GetCursorPosition()

    if not noTarget then
        Timers:CreateTimer(0.2, function()
            SpellCaster:Cast(inflictor, event.target, false)
        end)
    else
        Timers:CreateTimer(0.2, function()
            SpellCaster:Cast(inflictor, castPos, false)
        end)
    end

    ability:UseResources(false, false, false, true)
end

function modifier_item_spire_of_aggron:GetModifierBonusStats_Intellect()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_spire_of_aggron:GetModifierBonusStats_Strength()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_spire_of_aggron:GetModifierSpellAmplify_Percentage()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

function modifier_item_spire_of_aggron:GetModifierPhysicalArmorBonus()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_spire_of_aggron:GetModifierMoveSpeedBonus_Constant()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end

function modifier_item_spire_of_aggron:GetModifierManaBonus()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_spire_of_aggron:GetModifierConstantManaRegen()
    if not self then return end
    if not self:GetAbility() or self:GetAbility():IsNull() then return end
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

---
function modifier_item_spire_of_aggron_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.amp = ability:GetSpecialValueFor("consec_spell_amp") * self:GetStackCount()

    self:InvokeBonusAmp()
end

function modifier_item_spire_of_aggron_buff:OnStackCountChanged()
    if not IsServer() then return end

    local ability = self:GetAbility()

    self.amp = ability:GetSpecialValueFor("consec_spell_amp") * self:GetStackCount()

    self:InvokeBonusAmp()
end

function modifier_item_spire_of_aggron_buff:AddCustomTransmitterData()
    return
    {
        amp = self.fAmp
    }
end

function modifier_item_spire_of_aggron_buff:HandleCustomTransmitterData(data)
    if data.amp ~= nil then
        self.fAmp = tonumber(data.amp)
    end
end

function modifier_item_spire_of_aggron_buff:InvokeBonusAmp()
    if IsServer() == true then
        self.fAmp = self.amp

        self:SendBuffRefreshToClients()
    end
end

function modifier_item_spire_of_aggron_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_spire_of_aggron_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, --GetModifierSpellAmplify_Percentage
    }
    return funcs
end

function modifier_item_spire_of_aggron_buff:GetModifierSpellAmplify_Percentage()
    return self.fAmp
end

function modifier_item_spire_of_aggron_buff:GetTexture()
    return "item_spire_of_aggron"
end