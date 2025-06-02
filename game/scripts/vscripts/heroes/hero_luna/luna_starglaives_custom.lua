LinkLuaModifier("modifier_luna_starglaives_custom", "heroes/hero_luna/luna_starglaives_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

luna_starglaives_custom = class(ItemBaseClass)
modifier_luna_starglaives_custom = class(luna_starglaives_custom)
----------------------
function luna_starglaives_custom:GetAbilityTextureName()
    local talent = self:GetCaster():FindAbilityByName("talent_luna_2")
    if talent ~= nil and talent:GetLevel() > 0 then
        return "glaive_gold"
    else
        return "luna_glaive_default"
    end
end

function luna_starglaives_custom:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self

    if self:GetToggleState() then
        caster:AddNewModifier(caster, ability, "modifier_luna_starglaives_custom", {})
    else
        caster:RemoveModifierByNameAndCaster("modifier_luna_starglaives_custom", caster)
    end
end
---------------------
function modifier_luna_starglaives_custom:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self:OnRefresh()

    self:StartIntervalThink(0.1)
end

function modifier_luna_starglaives_custom:OnIntervalThink()
    self:OnRefresh()
end

function modifier_luna_starglaives_custom:OnRefresh()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local cost = ability:GetSpecialValueFor("max_mana_cost_pct")
    local mana = parent:GetMaxMana() * (cost/100)

    if mana > parent:GetMana() then
        if ability:GetToggleState() then
            ability:ToggleAbility()
            return
        end
    end

    self.damage = (self:GetParent():GetSpellAmplification(false)*100) * (self:GetAbility():GetSpecialValueFor("spell_damage_conversion")/100)

    self:InvokeBonusDamage()
end

function modifier_luna_starglaives_custom:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_luna_starglaives_custom:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_luna_starglaives_custom:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end

function modifier_luna_starglaives_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_PROJECTILE_NAME 

    }
end

function modifier_luna_starglaives_custom:GetModifierBaseDamageOutgoing_Percentage()
    return self.fDamage
end

function modifier_luna_starglaives_custom:GetModifierProjectileName()
    local talent = self:GetCaster():FindAbilityByName("talent_luna_2")
    if talent ~= nil and talent:GetLevel() > 0 then
        return "particles/econ/items/luna/luna_ti9_weapon_gold/luna_ti9_gold_base_attack.vpcf"
    else
        return "particles/econ/items/luna/luna_ti9_weapon/luna_ti9_base_attack.vpcf"
    end
end

function modifier_luna_starglaives_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    EmitSoundOn("Hero_Luna.MoonGlaive.Impact", event.target)

    if not parent:HasModifier("modifier_item_aghanims_shard") then return end

    local ability = self:GetAbility()
    
    local cost = ability:GetSpecialValueFor("max_mana_cost_pct")
    local mana = parent:GetMaxMana() * (cost/100)

    ApplyDamage({
        attacker = parent,
        victim = event.target,
        damage = mana,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })
end

function modifier_luna_starglaives_custom:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local victim = event.target

    local ability = self:GetAbility()

    local cost = ability:GetSpecialValueFor("max_mana_cost_pct")
    local mana = parent:GetMaxMana() * (cost/100)

    if mana > parent:GetMana() then return end
    if parent:PassivesDisabled() then return end
    if parent:IsIllusion() then return end

    parent:SpendMana(mana, ability)

    local talent = parent:FindAbilityByName("talent_luna_1")
    if talent ~= nil then return end

    local chance = ability:GetSpecialValueFor("chance_moon_beam_reset_cd")
    if not RollPercentage(chance) then return end

    local moonBeam = parent:FindAbilityByName("luna_moon_beam_custom")
    if moonBeam ~= nil then
        local cd = moonBeam:GetCooldownTimeRemaining()

        moonBeam:EndCooldown()

        local newCd = cd-1
        if newCd < 0 then
            newCd = 0
        end

        moonBeam:StartCooldown(newCd)
    end
end