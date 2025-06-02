LinkLuaModifier("modifier_item_leveller", "items/item_leveller/item_leveller", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_leveller = class(ItemBaseClass)
modifier_item_leveller = class(item_leveller)
-------------
function item_leveller:GetIntrinsicModifierName()
    return "modifier_item_leveller"
end
-------------
function modifier_item_leveller:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_leveller:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_leveller:GetModifierTotalDamageOutgoing_Percentage(event)
    if event.damage_type == DAMAGE_TYPE_PHYSICAL and IsBossTCOTRPG(event.target) then
        return self:GetAbility():GetSpecialValueFor("bonus_boss_damage_pct")
    end
end

function modifier_item_leveller:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker

    if self:GetCaster() ~= attacker then
        return
    end

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