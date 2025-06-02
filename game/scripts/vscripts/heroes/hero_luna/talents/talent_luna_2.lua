LinkLuaModifier("modifier_talent_luna_2", "heroes/hero_luna/talents/talent_luna_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_luna_2_debuff", "heroes/hero_luna/talents/talent_luna_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

talent_luna_2 = class(ItemBaseClass)
modifier_talent_luna_2 = class(talent_luna_2)
modifier_talent_luna_2_debuff = class(ItemBaseClassDebuff)
-------------
function talent_luna_2:GetIntrinsicModifierName()
    return "modifier_talent_luna_2"
end
------------
function modifier_talent_luna_2:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }
end

function modifier_talent_luna_2:OnTakeDamage(event)
    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    if event.inflictor then return end
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end

    local target = event.unit

    local glaives = parent:FindAbilityByName("luna_starglaives_custom")
    if not glaives then return end
    if glaives:GetLevel() < 1 then return end
    if not glaives:GetToggleState() then return end

    target:AddNewModifier(parent, self:GetAbility(), "modifier_talent_luna_2_debuff", {
        duration = self:GetAbility():GetSpecialValueFor("duration")
    })
end

function modifier_talent_luna_2:GetModifierTotalDamageOutgoing_Percentage(event)
    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    if not event.inflictor then return end
    if event.inflictor:GetAbilityName() ~= "luna_might_of_the_moon_custom" then return end

    return self:GetAbility():GetSpecialValueFor("motm_damage_increase")
end
------------
function modifier_talent_luna_2_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

function modifier_talent_luna_2:GetModifierIncomingDamage_Percentage(event)
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if event.target ~= parent then return end
    if event.damage_type ~= DAMAGE_TYPE_PURE then return end

    return self:GetAbility():GetSpecialValueFor("pure_damage_increase")
end

function modifier_talent_luna_2_debuff:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_talent_luna_2_debuff:OnIntervalThink()
    if not self:GetCaster():HasModifier("modifier_talent_luna_2") then self:Destroy() return end

    ApplyDamage({
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage = self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster()) * (self:GetAbility():GetSpecialValueFor("scorch_attack_pct")/100),
        ability = self:GetAbility(),
        damage_type = DAMAGE_TYPE_PURE
    })
end

function modifier_talent_luna_2_debuff:GetEffectName()
    return "particles/econ/items/phoenix/phoenix_ti10_immortal/phoenix_ti10_fire_spirit_burn.vpcf"
end