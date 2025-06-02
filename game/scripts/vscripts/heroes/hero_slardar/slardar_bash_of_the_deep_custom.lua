LinkLuaModifier("modifier_slardar_bash_of_the_deep_custom", "heroes/hero_slardar/slardar_bash_of_the_deep_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slardar_bash_of_the_deep_custom_debuff", "heroes/hero_slardar/slardar_bash_of_the_deep_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slardar_bash_of_the_deep_custom_stacks", "heroes/hero_slardar/slardar_bash_of_the_deep_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slardar_bash_of_the_deep_custom_buff", "heroes/hero_slardar/slardar_bash_of_the_deep_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

slardar_bash_of_the_deep_custom = class(ItemBaseClass)
modifier_slardar_bash_of_the_deep_custom = class(slardar_bash_of_the_deep_custom)
modifier_slardar_bash_of_the_deep_custom_debuff = class(ItemBaseClassDebuff)
modifier_slardar_bash_of_the_deep_custom_stacks = class(ItemBaseClassBuff)
modifier_slardar_bash_of_the_deep_custom_buff = class(ItemBaseClassBuff)
-------------
function slardar_bash_of_the_deep_custom:GetIntrinsicModifierName()
    return "modifier_slardar_bash_of_the_deep_custom"
end
------------
function modifier_slardar_bash_of_the_deep_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_slardar_bash_of_the_deep_custom:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent:HasModifier("modifier_slardar_bash_of_the_deep_custom_buff") then
        parent:RemoveModifierByName("modifier_slardar_bash_of_the_deep_custom_buff")
    end

    if parent:HasModifier("modifier_slardar_bash_of_the_deep_custom_stacks") then
        parent:RemoveModifierByName("modifier_slardar_bash_of_the_deep_custom_stacks")
    end
end

function modifier_slardar_bash_of_the_deep_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() or caster:IsIllusion() or caster:HasModifier("modifier_slardar_bash_of_the_deep_custom_buff") then
        return
    end

    local ability = self:GetAbility()
    if not ability:IsCooldownReady() then return end
    
    local debuff = caster:FindModifierByName("modifier_slardar_bash_of_the_deep_custom_stacks")
    if not debuff then
        debuff = caster:AddNewModifier(caster, ability, "modifier_slardar_bash_of_the_deep_custom_stacks", {})
    end

    if debuff then
        local attacks = ability:GetSpecialValueFor("attacks")

        if debuff:GetStackCount() < attacks then
            debuff:IncrementStackCount()
        end

        if debuff:GetStackCount() == attacks then
            caster:AddNewModifier(caster, ability, "modifier_slardar_bash_of_the_deep_custom_buff", {})
            caster:RemoveModifierByName("modifier_slardar_bash_of_the_deep_custom_stacks")
            return
        end
    end
end
--------------
function modifier_slardar_bash_of_the_deep_custom_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
------------
function modifier_slardar_bash_of_the_deep_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_slardar_bash_of_the_deep_custom_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_amp")
end

function modifier_slardar_bash_of_the_deep_custom_debuff:GetEffectName()
    return "particles/status_fx/status_effect_slardar_amp_damage.vpcf"
end
-------------
function modifier_slardar_bash_of_the_deep_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE  
    }

    return funcs
end

function modifier_slardar_bash_of_the_deep_custom_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_from_attack")
end

function modifier_slardar_bash_of_the_deep_custom_buff:OnAttackLanded(event)
    if not IsServer() then return end

    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() or caster:IsIllusion() then
        return
    end

    local ability = self:GetAbility()

    victim:AddNewModifier(caster, ability, "modifier_slardar_bash_of_the_deep_custom_debuff", {
        duration = ability:GetSpecialValueFor("duration")
    })

    EmitSoundOn("Hero_Slardar.Bash", victim)

    self:Destroy()
end