LinkLuaModifier("modifier_slardar_amplify_damage_custom", "heroes/hero_slardar/slardar_amplify_damage_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slardar_amplify_damage_custom_debuff", "heroes/hero_slardar/slardar_amplify_damage_custom", LUA_MODIFIER_MOTION_NONE)

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

slardar_amplify_damage_custom = class(ItemBaseClass)
modifier_slardar_amplify_damage_custom = class(slardar_amplify_damage_custom)
modifier_slardar_amplify_damage_custom_debuff = class(ItemBaseClassDebuff)
-------------
function slardar_amplify_damage_custom:GetIntrinsicModifierName()
    return "modifier_slardar_amplify_damage_custom"
end
------------
function modifier_slardar_amplify_damage_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }

    return funcs
end

function modifier_slardar_amplify_damage_custom:OnAttack(event)
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
    if not ability:IsCooldownReady() then return end
    
    local debuff = victim:FindModifierByName("modifier_slardar_amplify_damage_custom_debuff")
    if not debuff then
        debuff = victim:AddNewModifier(caster, ability, "modifier_slardar_amplify_damage_custom_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if debuff then
        debuff:ForceRefresh()
    end

    ability:UseResources(false, false, false, true)
end
------------
function modifier_slardar_amplify_damage_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_slardar_amplify_damage_custom_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_slardar_amplify_damage_custom_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_amp")
end

function modifier_slardar_amplify_damage_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_slardar/slardar_amp_damage.vpcf"
end

function modifier_slardar_amplify_damage_custom_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW 
end

function modifier_slardar_amplify_damage_custom_debuff:OnCreated()
    if not IsServer() then return end

    EmitSoundOn("Hero_Slardar.Amplify_Damage", self:GetParent())
end