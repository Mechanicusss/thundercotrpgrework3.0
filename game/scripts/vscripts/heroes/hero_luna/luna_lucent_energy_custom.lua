LinkLuaModifier("modifier_luna_lucent_energy_custom", "heroes/hero_luna/luna_lucent_energy_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_luna_lucent_energy_custom_debuff", "heroes/hero_luna/luna_lucent_energy_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_luna_lucent_energy_custom_autocast", "heroes/hero_luna/luna_lucent_energy_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

luna_lucent_energy_custom = class(ItemBaseClass)
modifier_luna_lucent_energy_custom_autocast = class(ItemBaseClass)
modifier_luna_lucent_energy_custom = class(luna_lucent_energy_custom)
modifier_luna_lucent_energy_custom_debuff = class(ItemBaseClass)
----------------------
function luna_lucent_energy_custom:GetIntrinsicModifierName()
    return "modifier_luna_lucent_energy_custom_autocast"
end

function luna_lucent_energy_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster:HasModifier("modifier_luna_lucent_energy_custom") then
        caster:RemoveModifierByName("modifier_luna_lucent_energy_custom")
    end

    caster:AddNewModifier(caster, self, "modifier_luna_lucent_energy_custom", {})
end
---------------------
function modifier_luna_lucent_energy_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }
end

function modifier_luna_lucent_energy_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local charges = ability:GetSpecialValueFor("number_of_casts")

    self:SetStackCount(charges)
end

function modifier_luna_lucent_energy_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if parent ~= event.attacker then return end
    if not event.inflictor then return end
    if event.inflictor:GetAbilityName() ~= "luna_moon_beam_custom" then return end
    if not parent:HasModifier("modifier_talent_luna_1") then return end

    local target = event.unit 

    local debuff = target:FindModifierByName("modifier_luna_lucent_energy_custom_debuff")

    if not debuff then
        debuff = target:AddNewModifier(parent, ability, "modifier_luna_lucent_energy_custom_debuff", {
            duration = ability:GetSpecialValueFor("debuff_duration")
        })
    end

    if debuff then
        debuff:IncrementStackCount()
        debuff:ForceRefresh()
    end

    self:DecrementStackCount()
    if self:GetStackCount() <= 0 then
        self:Destroy()
        return
    end
end

function modifier_luna_lucent_energy_custom:OnAbilityExecuted(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    if parent ~= event.unit then return end
    if event.ability == ability then return end

    local target = event.target

    if not target then return end

    local mana = target:GetMana() * (ability:GetSpecialValueFor("mana_steal_pct")/100)

    target:SetMana(target:GetMana() - mana)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_LOSS, target, mana, nil)

    parent:GiveMana(mana)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, parent, mana, nil)

    if event.ability:GetAbilityName() == "luna_moon_beam_custom" then
        local debuff = target:FindModifierByName("modifier_luna_lucent_energy_custom_debuff")

        if not debuff then
            debuff = target:AddNewModifier(parent, ability, "modifier_luna_lucent_energy_custom_debuff", {
                duration = ability:GetSpecialValueFor("debuff_duration")
            })
        end

        if debuff then
            debuff:IncrementStackCount()
            debuff:ForceRefresh()
        end
    end

    -- Stacks --
    local motm = parent:FindAbilityByName("luna_might_of_the_moon_custom")
    if motm ~= nil then
        local buff = parent:FindModifierByName("modifier_luna_might_of_the_moon_custom_stacks")
        
        if not buff then
            buff = parent:AddNewModifier(parent, motm, "modifier_luna_might_of_the_moon_custom_stacks", {})
        end

        if buff then
            if buff:GetStackCount() < motm:GetSpecialValueFor("max_stacks") then
                buff:IncrementStackCount()
            end

            buff:ForceRefresh()
        end
    end

    self:DecrementStackCount()
    if self:GetStackCount() <= 0 then
        self:Destroy()
        return
    end
end
---------------
function modifier_luna_lucent_energy_custom_debuff:IsDebuff() return true end

function modifier_luna_lucent_energy_custom_debuff:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_luna_lucent_energy_custom_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local damage = ability:GetSpecialValueFor("debuff_damage") + (caster:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    ApplyDamage({
        victim = parent,
        attacker = caster,
        ability = ability,
        damage = damage * self:GetStackCount(),
        damage_type = DAMAGE_TYPE_MAGICAL
    })
end
----------
function modifier_luna_lucent_energy_custom_autocast:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_luna_lucent_energy_custom_autocast:OnIntervalThink()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    if ability:IsCooldownReady() and ability:GetAutoCastState() and not parent:IsSilenced() and not parent:IsHexed() and ability:GetManaCost(-1) <= parent:GetMana() then
        SpellCaster:Cast(ability, parent, true)
    end
end

function modifier_luna_lucent_energy_custom_autocast:IsHidden() return true end