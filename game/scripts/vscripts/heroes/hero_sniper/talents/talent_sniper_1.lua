LinkLuaModifier("modifier_talent_sniper_1", "heroes/hero_sniper/talents/talent_sniper_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_sniper_1_overheat", "heroes/hero_sniper/talents/talent_sniper_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_sniper_1_superheat", "heroes/hero_sniper/talents/talent_sniper_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_sniper_1_ignite", "heroes/hero_sniper/talents/talent_sniper_1", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_sniper_1_activated", "heroes/hero_sniper/talents/talent_sniper_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

talent_sniper_1 = class(ItemBaseClass)
talent_sniper_1_sub = class(ItemBaseClass)
modifier_talent_sniper_1 = class(talent_sniper_1)
modifier_talent_sniper_1_overheat = class(ItemBaseDebuff)
modifier_talent_sniper_1_superheat = class(ItemBaseBuff)
modifier_talent_sniper_1_ignite = class(ItemBaseDebuff)
modifier_talent_sniper_1_activated = class(ItemBaseBuff)
-------------
function talent_sniper_1:GetIntrinsicModifierName()
    return "modifier_talent_sniper_1"
end
-------------
function talent_sniper_1_sub:OnSpellStart()
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_talent_sniper_1_activated", {
        duration = self:GetDuration()
    })
end
-------------
function modifier_talent_sniper_1:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local rifle = parent:FindAbilityByName("gun_joe_rifle")

    if not rifle then return end

    if rifle:GetToggleState() then
        rifle:ToggleAbility()
    end

    rifle:SetActivated(false)

    local activator = parent:FindAbilityByName("talent_sniper_1_sub")
    if not activator then
        activator = parent:AddAbility("talent_sniper_1_sub")
    end

    parent:SwapAbilities(
        "gun_joe_rifle",
        "talent_sniper_1_sub",
        false,
        true
    )

    if activator then
        activator:SetLevel(1)
        activator:SetActivated(true)
        activator:SetHidden(false)
    end
end

function modifier_talent_sniper_1:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_talent_sniper_1_overheat")
    parent:RemoveModifierByName("modifier_talent_sniper_1_superheat")

    local rifle = parent:FindAbilityByName("gun_joe_rifle")

    if not rifle then return end

    if rifle:GetToggleState() then
        rifle:ToggleAbility()
    end

    rifle:SetActivated(true)

    local activator = parent:FindAbilityByName("talent_sniper_1_sub")
    if activator then
        activator:SetActivated(false)
        activator:SetHidden(true)
        parent:RemoveModifierByName("modifier_talent_sniper_1_activated") 
    end

    parent:SwapAbilities(
        "gun_joe_rifle",
        "talent_sniper_1_sub",
        true,
        false
    )
end

function modifier_talent_sniper_1:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_talent_sniper_1:OnAttack(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end
    if not parent:HasModifier("modifier_gun_joe_machine_gun") then return end
    if parent:HasModifier("modifier_talent_sniper_1_superheat") then return end
    if not parent:HasModifier("modifier_talent_sniper_1_activated") then return end

    local ability = self:GetAbility()

    local mod = parent:FindModifierByName("modifier_talent_sniper_1_overheat")
    if not mod then
        mod = parent:AddNewModifier(parent, ability, "modifier_talent_sniper_1_overheat", {
            duration = ability:GetSpecialValueFor("overheat_duration")
        })
    end

    if mod then
        if mod:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            mod:IncrementStackCount()
            mod:ForceRefresh()
        elseif mod:GetStackCount() == ability:GetSpecialValueFor("max_stacks") then
            parent:AddNewModifier(parent, ability, "modifier_talent_sniper_1_superheat", {
                duration = ability:GetSpecialValueFor("superheat_duration")
            })
            mod:Destroy()
            return
        end
    end
end
-------------------
function modifier_talent_sniper_1_superheat:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ALWAYS_ETHEREAL_ATTACK,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_OVERRIDE_ATTACK_MAGICAL,
        MODIFIER_PROPERTY_OVERRIDE_ATTACK_DAMAGE,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_talent_sniper_1_superheat:GetModifierOverrideAttackDamage() return 0 end

function modifier_talent_sniper_1_superheat:GetModifierProcAttack_BonusDamage_Magical(keys)
    ApplyDamage({
        attacker = self:GetCaster(),
        victim = keys.target,
        damage = keys.original_damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    })
    return 0
end

function modifier_talent_sniper_1_superheat:GetOverrideAttackMagical()
    return 1
end

function modifier_talent_sniper_1_superheat:GetAllowEtherealAttack()
    return 1
end

function modifier_talent_sniper_1_superheat:GetAbsoluteNoDamagePhysical()
    return 1
end

function modifier_talent_sniper_1_superheat:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.target then return end
    if not parent:HasModifier("modifier_gun_joe_machine_gun") then return end

    local ability = self:GetAbility()
    local victim = event.target

    local mod = victim:FindModifierByName("modifier_talent_sniper_1_ignite")
    if not mod then
        mod = victim:AddNewModifier(parent, ability, "modifier_talent_sniper_1_ignite", {
            duration = ability:GetSpecialValueFor("ignite_duration"),
            damage = event.damage
        })
    end

    if mod then
        mod:ForceRefresh()
    end
end

function modifier_talent_sniper_1_superheat:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()
    local machineGun = parent:FindAbilityByName("gun_joe_machine_gun")

    if not machineGun then return end

    if machineGun:GetToggleState() then
        machineGun:ToggleAbility()
    end

    machineGun:StartCooldown(self:GetAbility():GetSpecialValueFor("cooldown"))
end

function modifier_talent_sniper_1_superheat:GetPriority()
    return 1001
end
------------
function modifier_talent_sniper_1_ignite:OnCreated(params)
    if not IsServer() then return end

    self.damage = params.damage

    self.damageTable = {
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    }

    local interval = self:GetCaster():GetSecondsPerAttack()
    if interval < 0.1 then
        interval = 0.1
    end

    self:StartIntervalThink(interval)
end

function modifier_talent_sniper_1_ignite:OnIntervalThink()
    if not self:GetCaster():HasModifier("modifier_talent_sniper_1") then self:Destroy() return end
    
    ApplyDamage(self.damageTable)
end

function modifier_talent_sniper_1_ignite:GetEffectName()
    return "particles/units/heroes/hero_phoenix/phoenix_icarus_dive_burn_debuff.vpcf"
end
--------
function modifier_talent_sniper_1_overheat:GetPriority()
    return 1001
end