LinkLuaModifier("modifier_item_shamans_sword", "items/item_shamans_sword/item_shamans_sword", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shamans_sword_stacks", "items/item_shamans_sword/item_shamans_sword", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_shamans_sword_vulnerable", "items/item_shamans_sword/item_shamans_sword", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_shamans_sword = class(ItemBaseClass)
modifier_item_shamans_sword = class(item_shamans_sword)
modifier_item_shamans_sword_stacks = class(ItemBaseClassDebuff)
modifier_item_shamans_sword_vulnerable = class(ItemBaseClassDebuff)
-------------
function item_shamans_sword:GetIntrinsicModifierName()
    return "modifier_item_shamans_sword"
end
-------------
function modifier_item_shamans_sword:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_item_shamans_sword:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local ability = self:GetAbility()

    if ability == event.inflictor then return end

    if event.inflictor ~= nil then
        if string.match(event.inflictor:GetAbilityName(), "item_") then return end
    end

    local target = event.unit 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end

    local stacks = target:FindModifierByName("modifier_item_shamans_sword_stacks")
    if not stacks and not target:HasModifier("modifier_item_shamans_sword_vulnerable") then
        stacks = target:AddNewModifier(parent, ability, "modifier_item_shamans_sword_stacks", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if stacks then
        if stacks:GetStackCount() < ability:GetSpecialValueFor("max_stacks") and not target:HasModifier("modifier_item_shamans_sword_vulnerable") then
            stacks:IncrementStackCount()
        end

        if stacks:GetStackCount() >= ability:GetSpecialValueFor("max_stacks") then
            stacks:Destroy()
            target:AddNewModifier(parent, ability, "modifier_item_shamans_sword_vulnerable", {
                duration = ability:GetSpecialValueFor("magic_vulnerable_duration")
            })
        end

        stacks:ForceRefresh()
    end
end
-------------
function modifier_item_shamans_sword_stacks:GetEffectName()
    return "particles/neutral_fx/gnoll_poison_debuff.vpcf"
end

function modifier_item_shamans_sword_stacks:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_item_shamans_sword_stacks:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_item_shamans_sword_stacks:OnCreated()
    if not IsServer() then return end 

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    self:StartIntervalThink(interval)
end

function modifier_item_shamans_sword_stacks:OnIntervalThink()
    local parent = self:GetParent()

    local caster = self:GetCaster()

    local ability = self:GetAbility()

    local damage = caster:GetPrimaryStatValue() * (ability:GetSpecialValueFor("primary_attribute_damage_multiplier"))  * self:GetStackCount()

    ApplyDamage({
        attacker = caster,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, parent, damage, nil)
end
-------
function modifier_item_shamans_sword_vulnerable:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
    }
end

function modifier_item_shamans_sword_vulnerable:GetModifierMagicalResistanceDecrepifyUnique( params )
    return self:GetAbility():GetSpecialValueFor("magic_vulnerable") * (-1)
end