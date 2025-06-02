LinkLuaModifier("modifier_item_mom_custom", "items/item_mom_custom/item_mom_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_mom_custom_toggle", "items/item_mom_custom/item_mom_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_mom_custom_debuff", "items/item_mom_custom/item_mom_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassToggle = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

item_mom_custom = class(ItemBaseClass)
item_mom_custom2 = item_mom_custom
item_mom_custom3 = item_mom_custom
item_mom_custom4 = item_mom_custom
item_mom_custom5 = item_mom_custom
item_mom_custom6 = item_mom_custom
modifier_item_mom_custom = class(item_mom_custom)
modifier_item_mom_custom_toggle = class(ItemBaseClassToggle)
modifier_item_mom_custom_debuff = class(ItemBaseClassDebuff)

function modifier_item_mom_custom_toggle:GetTexture() return "mom_custom_toggle" end
-------------
function item_mom_custom:GetIntrinsicModifierName()
    return "modifier_item_mom_custom"
end

function item_mom_custom:GetAbilityTextureName()
    if self:GetToggleState() then
        return "mom_custom_toggle"
    end

    if self:GetLevel() == 1 then
        return "mom_custom"
    elseif self:GetLevel() == 2 then
        return "mom_custom2"
    elseif self:GetLevel() == 3 then
        return "mom_custom3"
    elseif self:GetLevel() == 4 then
        return "mom_custom4"
    elseif self:GetLevel() == 5 then
        return "mom_custom5"
    elseif self:GetLevel() == 6 then
        return "mom_custom6"
    end
end

function item_mom_custom:OnToggle()
    local caster = self:GetCaster()

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_item_mom_custom_toggle", {})
        EmitSoundOn("DOTA_Item.MaskOfMadness.Activate", caster)
    else
        caster:RemoveModifierByName("modifier_item_mom_custom_toggle")
    end
end
--------------
function modifier_item_mom_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_item_mom_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_mom_custom:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_mom_custom:OnCreated()
    if not IsServer() then return end
end

function modifier_item_mom_custom:OnRemoved()
    if not IsServer() then return end

    if self:GetAbility():GetToggleState() then
        self:GetAbility():ToggleAbility()
    end
end

function modifier_item_mom_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local victim = event.target
    local attack_damage = event.damage
    local ability = self:GetAbility()

    if self:GetCaster() ~= attacker then
        return
    end

    if not UnitIsNotMonkeyClone(attacker) or not attacker:IsRealHero() or attacker:IsIllusion() then return end
    if event.inflictor ~= nil then return end -- Should block abilities from proccing it? 

    local disarmor = victim:FindModifierByName("modifier_item_mom_custom_debuff")
    if disarmor == nil then
        disarmor = victim:AddNewModifier(attacker, ability, "modifier_item_mom_custom_debuff", {
            duration = ability:GetSpecialValueFor("corruption_duration")
        })
    end

    if disarmor ~= nil then
        disarmor:ForceRefresh()
    end
    ----------------------------
    if event.target:GetUnitName() == "npc_tcot_tormentor" then return end
    
    local lifestealAmount = self:GetAbility():GetSpecialValueFor("lifesteal")

    if attacker:HasModifier("modifier_item_mom_custom_toggle") then
        lifestealAmount = self:GetAbility():GetSpecialValueFor("bonus_lifesteal_burst")
    end

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
----------
function modifier_item_mom_custom_toggle:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
    }
end

function modifier_item_mom_custom_toggle:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true
    }
end

function modifier_item_mom_custom_toggle:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed_burst")
end

function modifier_item_mom_custom_toggle:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_atk_pct_burst")
end

function modifier_item_mom_custom_toggle:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("incoming_damage_increase")
end

function modifier_item_mom_custom_toggle:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    self.interval = ability:GetSpecialValueFor("interval")
    self.bonusDamageBurst = ability:GetSpecialValueFor("bonus_atk_pct_burst")
    self.baseDamage = parent:GetAverageTrueAttackDamage(parent)
    self.increment = ability:GetSpecialValueFor("increase_pct")
end

function modifier_item_mom_custom_toggle:GetEffectName()
    return "particles/econ/items/drow/drow_head_mania/mask_of_madness_active_mania.vpcf"
end

function modifier_item_mom_custom_toggle:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
----------
function modifier_item_mom_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus
    }
end

function modifier_item_mom_custom_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("corruption")
end